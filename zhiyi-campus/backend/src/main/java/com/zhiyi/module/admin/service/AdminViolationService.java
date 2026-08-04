package com.zhiyi.module.admin.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.zhiyi.common.BusinessException;
import com.zhiyi.common.ResultCode;
import com.zhiyi.module.admin.dto.ConfirmViolationDTO;
import com.zhiyi.module.admin.entity.ViolationLog;
import com.zhiyi.module.admin.entity.ViolationReport;
import com.zhiyi.module.admin.mapper.ViolationLogMapper;
import com.zhiyi.module.admin.mapper.ViolationReportMapper;
import com.zhiyi.module.admin.vo.PenaltyStatsVO;
import com.zhiyi.module.admin.vo.ViolationVO;
import com.zhiyi.module.item.entity.Item;
import com.zhiyi.module.item.mapper.ItemMapper;
import com.zhiyi.module.trade.entity.TradeOrder;
import com.zhiyi.module.trade.entity.TradeReview;
import com.zhiyi.module.trade.mapper.TradeOrderMapper;
import com.zhiyi.module.trade.mapper.TradeReviewMapper;
import com.zhiyi.module.user.dto.BanUserDTO;
import com.zhiyi.module.user.entity.SysUser;
import com.zhiyi.module.user.mapper.SysUserMapper;
import com.zhiyi.module.user.service.BanService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 超管违规审核服务 —— 4.5 人工审核与风控工作台
 *
 * 确认违规 → 处罚用户（调 A 模块 BanService）
 * 误判放行 → 撤销违规记录
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AdminViolationService {

    private final ViolationReportMapper violationReportMapper;
    private final SysUserMapper sysUserMapper;
    private final ItemMapper itemMapper;
    private final BanService banService;
    private final ViolationLogMapper violationLogMapper;
    private final TradeOrderMapper tradeOrderMapper;
    private final TradeReviewMapper tradeReviewMapper;

    /**
     * 分页查询违规记录列表
     */
    public IPage<ViolationVO> getViolations(int page, int size, String status) {
        LambdaQueryWrapper<ViolationReport> q = new LambdaQueryWrapper<ViolationReport>()
                .eq(status != null && !status.isEmpty(), ViolationReport::getStatus, status)
                .orderByDesc(ViolationReport::getCreatedAt);

        Page<ViolationReport> p = new Page<>(page, size);
        IPage<ViolationReport> result = violationReportMapper.selectPage(p, q);

        List<ViolationReport> records = result.getRecords();
        if (records.isEmpty()) {
            return result.convert(r -> toVO(r, Map.of(), Map.of(), Map.of()));
        }

        // 批量预加载：收集所有 userId、handlerId、itemId
        List<Long> userIds = records.stream().map(ViolationReport::getUserId)
                .distinct().collect(Collectors.toList());
        List<Long> handlerIds = records.stream().map(ViolationReport::getHandlerId)
                .filter(id -> id != null).distinct().collect(Collectors.toList());
        List<Long> itemIds = records.stream().map(ViolationReport::getItemId)
                .filter(id -> id != null).distinct().collect(Collectors.toList());

        Map<Long, SysUser> userMap = userIds.isEmpty() ? Map.of()
                : sysUserMapper.selectBatchIds(userIds).stream()
                        .collect(Collectors.toMap(SysUser::getId, u -> u));
        Map<Long, SysUser> handlerMap = handlerIds.isEmpty() ? Map.of()
                : sysUserMapper.selectBatchIds(handlerIds).stream()
                        .collect(Collectors.toMap(SysUser::getId, u -> u));
        Map<Long, Item> itemMap = itemIds.isEmpty() ? Map.of()
                : itemMapper.selectBatchIds(itemIds).stream()
                        .collect(Collectors.toMap(Item::getId, i -> i));

        // 合并 handler 到 userMap（避免 key 冲突，用不同的 map 更安全）
        final Map<Long, SysUser> finalUserMap = userMap;
        final Map<Long, SysUser> finalHandlerMap = handlerMap;
        final Map<Long, Item> finalItemMap = itemMap;

        return result.convert(r -> toVO(r, finalUserMap, finalHandlerMap, finalItemMap));
    }

    /**
     * 确认违规 + 处罚用户
     */
    @Transactional(rollbackFor = Exception.class)
    public void confirmViolation(Long reportId, ConfirmViolationDTO dto, Long adminId) {
        ViolationReport report = violationReportMapper.selectById(reportId);
        if (report == null) {
            throw new BusinessException(ResultCode.NOT_FOUND, "违规记录不存在");
        }
        if (!"PENDING".equals(report.getStatus())) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "该违规记录已处理，不能重复操作");
        }

        // 1. 更新违规记录
        report.setStatus("CONFIRMED");
        report.setHandlerId(adminId);
        report.setHandleNote(dto.getHandleNote());
        report.setHandledAt(LocalDateTime.now());
        violationReportMapper.updateById(report);

        // 2. 调用 A 模块封禁服务
        BanUserDTO banDTO = new BanUserDTO();
        banDTO.setUserId(report.getUserId());
        banDTO.setType(dto.getType());
        banDTO.setReason(dto.getReason());
        banDTO.setBanDays(dto.getBanDays());
        banService.punish(banDTO, adminId);

        // 3. 评价联动：降低卖家信誉评分
        applyReputationPenalty(report);

        log.info("管理员 {} 确认违规 reportId={}, 处罚用户 {} type={}", adminId, reportId, report.getUserId(), dto.getType());
    }

    /**
     * 误判放行 —— 撤销违规记录，商品重新上架
     */
    @Transactional(rollbackFor = Exception.class)
    public void dismissViolation(Long reportId, Long adminId) {
        ViolationReport report = violationReportMapper.selectById(reportId);
        if (report == null) {
            throw new BusinessException(ResultCode.NOT_FOUND, "违规记录不存在");
        }
        if (!"PENDING".equals(report.getStatus())) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "该违规记录已处理，不能重复操作");
        }

        // 1. 更新违规记录
        report.setStatus("DISMISSED");
        report.setHandlerId(adminId);
        report.setHandleNote("AI 误判，予以放行");
        report.setHandledAt(LocalDateTime.now());
        violationReportMapper.updateById(report);

        // 2. 评价联动：仅恢复当前违规报告关联的评价
        removeReputationPenalty(report);

        // 3. 商品重新上架
        if (report.getItemId() != null) {
            Item item = itemMapper.selectById(report.getItemId());
            if (item != null && "OFF_SHELF".equals(item.getStatus())) {
                item.setStatus("ON_SALE");
                item.setAiReviewed(true);
                itemMapper.updateById(item);
                log.info("商品 {} 已重新上架", item.getId());
            }
        }

        log.info("管理员 {} 驳回违规 reportId={}（误判放行），发布者 userId={}", adminId, reportId, report.getUserId());
    }

    // ---- 内部工具 ----

    private ViolationVO toVO(ViolationReport r, Map<Long, SysUser> userMap,
                              Map<Long, SysUser> handlerMap, Map<Long, Item> itemMap) {
        ViolationVO vo = new ViolationVO();
        vo.setId(r.getId());
        vo.setUserId(r.getUserId());
        vo.setOriginalTitle(r.getOriginalTitle());
        vo.setOriginalDescription(r.getOriginalDescription());
        vo.setViolationType(r.getViolationType());
        vo.setViolationReason(r.getViolationReason());
        vo.setAiTags(r.getAiTags());
        vo.setStatus(r.getStatus());
        vo.setHandlerId(r.getHandlerId());
        vo.setHandleNote(r.getHandleNote());
        vo.setItemId(r.getItemId());
        vo.setAiReviewError(r.getAiReviewError());
        vo.setCreatedAt(r.getCreatedAt());
        vo.setHandledAt(r.getHandledAt());

        // 商品状态（从预加载的 map 取，避免 N+1）
        if (r.getItemId() != null) {
            Item item = itemMap.get(r.getItemId());
            vo.setItemStatus(item != null ? item.getStatus() : null);
        }

        // 发布者昵称
        if (r.getUserId() != null) {
            SysUser reporter = userMap.get(r.getUserId());
            vo.setReporterName(reporter != null ? reporter.getNickname() : "未知用户");
        } else {
            vo.setReporterName("未知用户");
        }

        // 处理管理员昵称
        if (r.getHandlerId() != null) {
            SysUser handler = handlerMap.get(r.getHandlerId());
            vo.setHandlerName(handler != null ? handler.getNickname() : null);
        }

        return vo;
    }

    /**
     * 用户处罚评分统计（D4：评价联动）
     *
     * 核心逻辑：CONFIRMED 的违规记录 = 有效处罚，DISMISSED = 已恢复。
     * 供 A6 信誉雷达调用，汇总违规记录对信誉的负面影响。
     */
    public PenaltyStatsVO getPenaltyStats(Long userId) {
        PenaltyStatsVO vo = new PenaltyStatsVO();
        vo.setUserId(userId);

        // CONFIRMED 违规 = 有效处罚
        long confirmedCount = violationReportMapper.selectCount(
                new LambdaQueryWrapper<ViolationReport>()
                        .eq(ViolationReport::getUserId, userId)
                        .eq(ViolationReport::getStatus, "CONFIRMED"));
        vo.setConfirmedViolations(confirmedCount);

        // 处罚日志中的警告和封禁次数
        long warningCount = violationLogMapper.selectCount(
                new LambdaQueryWrapper<ViolationLog>()
                        .eq(ViolationLog::getUserId, userId)
                        .eq(ViolationLog::getType, "WARNING"));
        vo.setWarningCount(warningCount);

        long banCount = violationLogMapper.selectCount(
                new LambdaQueryWrapper<ViolationLog>()
                        .eq(ViolationLog::getUserId, userId)
                        .in(ViolationLog::getType, "BAN_TEMP", "BAN_PERM"));
        vo.setBanCount(banCount);

        // 处罚影响分：每次警告 -5，每次封禁 -15，最低 0
        int penalty = (int) (warningCount * 5 + banCount * 15);
        vo.setPenaltyScore(Math.max(0, 100 - penalty));

        return vo;
    }

    // ========================================
    // D4 评价联动：违规处罚 → 信誉降级 / 恢复
    // ========================================

    private static final String SYSTEM_PENALTY_COMMENT = "系统处罚：卖家违规行为";
    private static final String SYSTEM_DOWNGRADE_MARKER = "[系统：卖家因违规行为信誉降级]";

    /**
     * 查找当前违规报告关联的 COMPLETED 订单。
     * 优先匹配违规关联商品的订单，否则取卖家最近一笔 COMPLETED 订单。
     * 返回 null 表示卖家无已完成订单。
     */
    private TradeOrder findPenaltyOrder(ViolationReport report) {
        Long sellerId = report.getUserId();
        TradeOrder order = null;
        if (report.getItemId() != null) {
            order = tradeOrderMapper.selectOne(new LambdaQueryWrapper<TradeOrder>()
                    .eq(TradeOrder::getItemId, report.getItemId())
                    .eq(TradeOrder::getSellerId, sellerId)
                    .eq(TradeOrder::getStatus, "COMPLETED")
                    .orderByDesc(TradeOrder::getCompletedAt)
                    .last("LIMIT 1"));
        }
        if (order == null) {
            order = tradeOrderMapper.selectOne(new LambdaQueryWrapper<TradeOrder>()
                    .eq(TradeOrder::getSellerId, sellerId)
                    .eq(TradeOrder::getStatus, "COMPLETED")
                    .orderByDesc(TradeOrder::getCompletedAt)
                    .last("LIMIT 1"));
        }
        return order;
    }

    /**
     * 确认违规后降低卖家信誉评分（D4 评价联动）
     *
     * 仅针对当前违规报告关联的那一笔订单的评价进行操作：
     * 1. 优先匹配违规关联商品的 COMPLETED 订单，否则取卖家最近一笔 COMPLETED 订单
     * 2. 无订单 → 静默返回
     * 3. 无评价 → 插入系统差评（rating=1, accurate=false）
     * 4. 有评价且 rating > 1 → 降 2 分（最低 1 分），追加降级标记
     */
    private void applyReputationPenalty(ViolationReport report) {
        Long sellerId = report.getUserId();

        TradeOrder order = findPenaltyOrder(report);
        if (order == null) {
            log.info("卖家 {} 无已完成订单，跳过评价降级", sellerId);
            return;
        }

        // 查该订单是否已有评价
        TradeReview existing = tradeReviewMapper.selectOne(new LambdaQueryWrapper<TradeReview>()
                .eq(TradeReview::getOrderId, order.getId()));

        if (existing == null) {
            // 无评价 → 插入系统差评
            TradeReview sys = new TradeReview();
            sys.setOrderId(order.getId());
            sys.setReviewerId(order.getBuyerId());
            sys.setTargetId(sellerId);
            sys.setRating(1);
            sys.setAccurate(false);
            sys.setComment(SYSTEM_PENALTY_COMMENT);
            tradeReviewMapper.insert(sys);
            log.info("卖家 {} 无评价，插入系统处罚评价 orderId={} reportId={}", sellerId, order.getId(), report.getId());
        } else if (existing.getRating() != null && existing.getRating() > 1) {
            // 有评价且大于 1 分 → 降 2 分
            TradeReview patch = new TradeReview();
            patch.setId(existing.getId());
            patch.setRating(Math.max(1, existing.getRating() - 2));
            patch.setAccurate(false);
            String newComment = (existing.getComment() == null ? "" : existing.getComment() + " ")
                    + SYSTEM_DOWNGRADE_MARKER;
            patch.setComment(newComment.trim());
            tradeReviewMapper.updateById(patch);
            log.info("卖家 {} 评价降级：rating {}→{} orderId={} reportId={}", sellerId,
                    existing.getRating(), patch.getRating(), order.getId(), report.getId());
        } else {
            // 已有评价且 rating <= 1 → 仅标记 accurate=false
            TradeReview patch = new TradeReview();
            patch.setId(existing.getId());
            patch.setAccurate(false);
            tradeReviewMapper.updateById(patch);
            log.info("卖家 {} 评价评分已为 {}，仅标记 accurate=false orderId={} reportId={}",
                    sellerId, existing.getRating(), order.getId(), report.getId());
        }
    }

    /**
     * 驳回违规后恢复卖家信誉评分（D4 评价联动）
     *
     * 仅恢复当前违规报告关联的那一笔评价，而非卖家全部被降级评价。
     * 复用与 applyReputationPenalty 相同的订单查找逻辑定位到同一条评价。
     */
    private void removeReputationPenalty(ViolationReport report) {
        Long sellerId = report.getUserId();

        TradeOrder order = findPenaltyOrder(report);
        if (order == null) {
            log.info("卖家 {} 无已完成订单，跳过评价恢复 reportId={}", sellerId, report.getId());
            return;
        }

        // 查该订单的评价
        TradeReview review = tradeReviewMapper.selectOne(new LambdaQueryWrapper<TradeReview>()
                .eq(TradeReview::getOrderId, order.getId()));

        if (review == null) {
            log.info("卖家 {} 订单 {} 无评价记录，跳过评价恢复 reportId={}",
                    sellerId, order.getId(), report.getId());
            return;
        }

        boolean isSystemReview = SYSTEM_PENALTY_COMMENT.equals(review.getComment());
        boolean hasDowngradeMarker = review.getComment() != null
                && review.getComment().contains(SYSTEM_DOWNGRADE_MARKER);

        if (isSystemReview) {
            // 该评价是本系统插入的处罚评价 → 直接删除
            tradeReviewMapper.deleteById(review.getId());
            log.info("删除卖家 {} 的系统处罚评价 orderId={} reportId={}", sellerId, order.getId(), report.getId());
        } else if (hasDowngradeMarker) {
            // 该评价被降级过 → 恢复评分 +2（不超过 5），移除降级标记
            TradeReview patch = new TradeReview();
            patch.setId(review.getId());
            patch.setRating(Math.min(5, (review.getRating() == null ? 3 : review.getRating()) + 2));
            patch.setAccurate(true);
            String cleaned = review.getComment() == null ? ""
                    : review.getComment().replace(SYSTEM_DOWNGRADE_MARKER, "").trim();
            patch.setComment(cleaned.isEmpty() ? null : cleaned);
            tradeReviewMapper.updateById(patch);
            log.info("卖家 {} 评价恢复：rating {}→{} orderId={} reportId={}",
                    sellerId, review.getRating(), patch.getRating(), order.getId(), report.getId());
        } else {
            // 该评价虽是真实评价但没有降级标记（可能因 rating 已 ≤1 只改了 accurate）
            // 恢复 accurate 为 true
            TradeReview patch = new TradeReview();
            patch.setId(review.getId());
            patch.setAccurate(true);
            tradeReviewMapper.updateById(patch);
            log.info("卖家 {} 评价 accurate 恢复 orderId={} reportId={}", sellerId, order.getId(), report.getId());
        }
    }
}
