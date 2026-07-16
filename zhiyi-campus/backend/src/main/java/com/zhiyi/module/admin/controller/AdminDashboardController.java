package com.zhiyi.module.admin.controller;

import com.zhiyi.common.Result;
import com.zhiyi.common.annotation.RoleRequired;
import com.zhiyi.module.admin.service.AdminDashboardService;
import com.zhiyi.module.admin.vo.AdminDashboardVO;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * 超管控制台 · 数据大盘
 *
 * GET /api/admin/dashboard    数据概览（统计卡片 + 最近违规）
 */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@RoleRequired("ADMIN")
public class AdminDashboardController {

    private final AdminDashboardService dashboardService;

    @GetMapping("/dashboard")
    public Result<AdminDashboardVO> dashboard() {
        return Result.ok(dashboardService.getDashboard());
    }
}
