package com.zhiyi.interceptor;

import com.zhiyi.common.WebResponseUtil;
import com.zhiyi.module.user.support.UserAuthState;
import com.zhiyi.module.user.support.UserStateCache;
import com.zhiyi.utils.JwtUtils;
import io.jsonwebtoken.Claims;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.time.LocalDateTime;
import java.time.ZoneId;

/**
 * JWT 登录拦截器 —— 校验每个请求的 Token，把 userId 和 role 放入 Request 供后续 Controller 使用。
 *
 * 高并发设计：
 * - Token 只解析一次（一次签名验证拿到全部 Claims）；
 * - 封禁状态 / Token 失效纪元走 Caffeine 本地缓存（UserStateCache），不逐请求查库；
 * - 借助失效纪元（token_invalid_before），重置密码/封禁后旧 Token 立刻作废（需求 1.3/1.6）。
 */
@Component
public class JwtInterceptor implements HandlerInterceptor {

    private final JwtUtils jwtUtils;
    private final UserStateCache userStateCache;

    public JwtInterceptor(JwtUtils jwtUtils, UserStateCache userStateCache) {
        this.jwtUtils = jwtUtils;
        this.userStateCache = userStateCache;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response,
                             Object handler) throws Exception {
        // OPTIONS 预检请求直接放行
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }

        String token = request.getHeader("Authorization");
        if (token == null || !token.startsWith("Bearer ")) {
            WebResponseUtil.writeJson(response, 401, 401, "未登录");
            return false;
        }

        Claims claims = jwtUtils.parse(token.substring(7)); // 去掉 "Bearer " 前缀，只解析一次
        if (claims == null) {
            WebResponseUtil.writeJson(response, 401, 401, "Token 无效或已过期");
            return false;
        }

        Long userId = Long.parseLong(claims.getSubject());
        UserAuthState state = userStateCache.get(userId);
        if (state == null) {
            WebResponseUtil.writeJson(response, 401, 401, "用户不存在");
            return false;
        }

        // 失效纪元：重置密码 / 被封禁后签发的旧 Token 一律拒绝
        if (state.getTokenInvalidBefore() != null) {
            LocalDateTime issuedAt = LocalDateTime.ofInstant(
                    claims.getIssuedAt().toInstant(), ZoneId.systemDefault());
            if (issuedAt.isBefore(state.getTokenInvalidBefore())) {
                WebResponseUtil.writeJson(response, 401, 401, "登录状态已失效，请重新登录");
                return false;
            }
        }

        // 封禁/注销校验：永久封禁与已注销直接拒绝；临时封禁未到期拒绝（到期由登录流程恢复 ACTIVE）
        if ("CANCELLED".equals(state.getStatus())) {
            WebResponseUtil.writeJson(response, 401, 1008, "该账户已注销");
            return false;
        }
        if ("BANNED_PERM".equals(state.getStatus())) {
            WebResponseUtil.writeJson(response, 403, 1003, "该账户已被永久封禁");
            return false;
        }
        if ("BANNED_TEMP".equals(state.getStatus())
                && state.getBanUntilTime() != null
                && state.getBanUntilTime().isAfter(LocalDateTime.now())) {
            WebResponseUtil.writeJson(response, 403, 1003, "账户已被封禁");
            return false;
        }

        // 把 userId 和 role 放入 request attribute，Controller 里直接取
        request.setAttribute("userId", userId);
        request.setAttribute("role", claims.get("role", String.class));
        return true;
    }
}
