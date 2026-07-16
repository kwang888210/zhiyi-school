package com.zhiyi.module.admin.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.zhiyi.module.admin.entity.ViolationReport;
import com.zhiyi.module.admin.mapper.ViolationReportMapper;
import com.zhiyi.module.admin.vo.AdminDashboardVO;
import com.zhiyi.module.item.entity.Item;
import com.zhiyi.module.item.mapper.ItemMapper;
import com.zhiyi.module.trade.entity.TradeOrder;
import com.zhiyi.module.trade.mapper.TradeOrderMapper;
import com.zhiyi.module.user.entity.SysUser;
import com.zhiyi.module.user.mapper.SysUserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 超管数据大盘服务
 *
 * 日期计算全部委托 MySQL（CURDATE / DATE / DATE_SUB），避免 Java JVM
 * 时区与 MySQL serverTimezone 不一致导致"今日"统计为 0。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AdminDashboardService {

    private final SysUserMapper sysUserMapper;
    private final ItemMapper itemMapper;
    private final TradeOrderMapper orderMapper;
    private final ViolationReportMapper violationReportMapper;

    /**
     * 聚合大盘统计数据 + 近 7 日趋势 + 最近 5 条待审核违规
     */
    public AdminDashboardVO getDashboard() {
        AdminDashboardVO vo = new AdminDashboardVO();

        // 1. 统计
        vo.setTotalUsers(sysUserMapper.selectCount(null));

        vo.setOnSaleItems(itemMapper.selectCount(
                new LambdaQueryWrapper<Item>()
                        .eq(Item::getStatus, "ON_SALE")
                        .eq(Item::getIsDeleted, false)));

        // 今日交易总额 —— 委托 MySQL CURDATE()，避免 JVM 时区偏差
        LambdaQueryWrapper<TradeOrder> todayCompletedQ = new LambdaQueryWrapper<TradeOrder>()
                .apply("status = 'COMPLETED' AND DATE(completed_at) = CURDATE()");
        List<TradeOrder> todayOrders = orderMapper.selectList(todayCompletedQ);
        BigDecimal todaySum = todayOrders.stream()
                .map(TradeOrder::getPrice)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        vo.setTodayTradeAmount(todaySum.setScale(2, RoundingMode.HALF_UP).toString());
        log.info("今日交易额查询：status=COMPLETED, CURDATE()={}, 订单数={}, 总额={}",
                LocalDate.now(), todayOrders.size(), vo.getTodayTradeAmount());

        LambdaQueryWrapper<ViolationReport> pendingQ = new LambdaQueryWrapper<ViolationReport>()
                .eq(ViolationReport::getStatus, "PENDING");
        vo.setPendingViolations(violationReportMapper.selectCount(pendingQ));

        // 2. 最近 5 条待审核违规
        LambdaQueryWrapper<ViolationReport> recentQ = new LambdaQueryWrapper<ViolationReport>()
                .eq(ViolationReport::getStatus, "PENDING")
                .orderByDesc(ViolationReport::getCreatedAt)
                .last("LIMIT 5");

        List<ViolationReport> recent = violationReportMapper.selectList(recentQ);
        List<AdminDashboardVO.RecentViolation> rvList = new ArrayList<>();

        if (!recent.isEmpty()) {
            List<Long> userIds = recent.stream()
                    .map(ViolationReport::getUserId)
                    .distinct()
                    .collect(Collectors.toList());
            List<SysUser> users = sysUserMapper.selectBatchIds(userIds);
            Map<Long, String> nickMap = users.stream()
                    .collect(Collectors.toMap(SysUser::getId, SysUser::getNickname, (a, b) -> a));

            for (ViolationReport r : recent) {
                AdminDashboardVO.RecentViolation rv = new AdminDashboardVO.RecentViolation();
                rv.setId(r.getId());
                rv.setUserId(r.getUserId());
                rv.setReporterName(nickMap.getOrDefault(r.getUserId(), "未知用户"));
                rv.setOriginalTitle(r.getOriginalTitle());
                rv.setViolationType(r.getViolationType());
                rv.setViolationReason(r.getViolationReason());
                rv.setCreatedAt(r.getCreatedAt());
                rvList.add(rv);
            }
        }
        vo.setRecentViolations(rvList);

        // 3. 近 7 日交易趋势 —— 委托 MySQL DATE_SUB
        List<AdminDashboardVO.TradeTrendPoint> trendPoints = computeTrend();
        vo.setTrend(trendPoints);

        return vo;
    }

    /**
     * 计算近 7 日交易趋势（委托 MySQL 做日期运算）。
     *
     * 先用 MySQL DATE_SUB 查出近 7 天所有已完成订单，
     * 再在 Java 中按 DATE(completed_at) 分组后补齐无数据的日期。
     */
    private List<AdminDashboardVO.TradeTrendPoint> computeTrend() {
        // 委托 MySQL 做日期过滤，消除 JVM 时区偏差
        List<TradeOrder> completedOrders = orderMapper.selectList(
                new LambdaQueryWrapper<TradeOrder>()
                        .apply("status = 'COMPLETED' AND completed_at >= DATE_SUB(CURDATE(), INTERVAL 6 DAY)"));

        // 按日期分组（订单数 + 交易额）
        Map<LocalDate, Long> dayCount = new java.util.LinkedHashMap<>();
        Map<LocalDate, BigDecimal> dayAmount = new java.util.LinkedHashMap<>();
        for (TradeOrder o : completedOrders) {
            if (o.getCompletedAt() == null) continue;
            LocalDate d = o.getCompletedAt().toLocalDate();
            dayCount.merge(d, 1L, Long::sum);
            dayAmount.merge(d, o.getPrice(), BigDecimal::add);
        }

        // 补齐 7 天
        LocalDate today = LocalDate.now();
        LocalDate start = today.minusDays(6);
        List<AdminDashboardVO.TradeTrendPoint> points = new ArrayList<>();
        for (LocalDate d = start; !d.isAfter(today); d = d.plusDays(1)) {
            AdminDashboardVO.TradeTrendPoint p = new AdminDashboardVO.TradeTrendPoint();
            p.setDate(d.toString());
            p.setCount(dayCount.getOrDefault(d, 0L));
            p.setTotalAmount(dayAmount.getOrDefault(d, BigDecimal.ZERO)
                    .setScale(2, RoundingMode.HALF_UP).toString());
            points.add(p);
        }

        log.info("近7日趋势：日期范围={} ~ {}, 完成订单数={}, 趋势点={}",
                start, today, completedOrders.size(), points.size());
        return points;
    }
}
