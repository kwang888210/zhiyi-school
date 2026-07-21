package com.zhiyi.module.admin.controller;

import com.zhiyi.common.Result;
import com.zhiyi.common.annotation.RoleRequired;
import com.zhiyi.module.admin.service.AdminChatService;
import com.zhiyi.module.social.vo.ConversationVO;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 超管控制台 · 客服收件箱（4.6）
 *
 * GET /api/admin/chat/sessions    客服会话列表
 */
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@RoleRequired("ADMIN")
public class AdminChatController {

    private final AdminChatService adminChatService;

    @GetMapping("/chat/sessions")
    public Result<List<ConversationVO>> sessions() {
        return Result.ok(adminChatService.getSessions());
    }
}
