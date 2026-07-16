package com.zhiyi.module.admin.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.zhiyi.common.BusinessException;
import com.zhiyi.common.ResultCode;
import com.zhiyi.module.admin.dto.ConfirmViolationDTO;
import com.zhiyi.module.admin.entity.ViolationReport;
import com.zhiyi.module.admin.mapper.ViolationReportMapper;
import com.zhiyi.module.admin.vo.ViolationVO;
import com.zhiyi.module.item.entity.Item;
import com.zhiyi.module.item.mapper.ItemMapper;
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

    /**
     * 分页查询违规记录列表
     */
    public IPage<ViolationVO> getViolations(int page, int size, String status) {
        LambdaQueryWrapper<ViolationReport> q = new LambdaQueryWrapper<ViolationReport>()
                .eq(status != null && !status.isEmpty(), ViolationReport::getStatus, status)
                .orderByDesc(ViolationReport::getCreatedAt);

        Page<ViolationReport> p = new Page<>(page, size);
        IPage<ViolationReport> result = violationReportMapper.selectPage(p, q);

        return result.convert(r -> toVO(r));
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

        // 2. 商品重新上架
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

    private ViolationVO toVO(ViolationReport r) {
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

        // 商品状态（管理员可直接看到目标商品能不能下架）
        if (r.getItemId() != null) {
            Item item = itemMapper.selectById(r.getItemId());
            vo.setItemStatus(item != null ? item.getStatus() : null);
        }

        // 填充用户昵称
        if (r.getUserId() != null) {
            SysUser reporter = sysUserMapper.selectById(r.getUserId());
            vo.setReporterName(reporter != null ? reporter.getNickname() : "未知用户");
        } else {
            vo.setReporterName("未知用户");
        }

        if (r.getHandlerId() != null) {
            SysUser handler = sysUserMapper.selectById(r.getHandlerId());
            vo.setHandlerName(handler != null ? handler.getNickname() : null);
        }

        return vo;
    }
}
