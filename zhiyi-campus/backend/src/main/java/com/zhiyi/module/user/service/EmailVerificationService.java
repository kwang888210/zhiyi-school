package com.zhiyi.module.user.service;

import com.baomidou.mybatisplus.core.toolkit.Wrappers;
import com.zhiyi.common.BusinessException;
import com.zhiyi.common.ResultCode;
import com.zhiyi.module.user.entity.SysUser;
import com.zhiyi.module.user.mapper.SysUserMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.SecureRandom;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 学校邮箱验证服务（A3）
 *
 * 验证码发送到学校邮箱 → 用户输入验证码 → email_verified = true → "✅ 已认证"
 * 验证码全局唯一（同一时间只有一个待验证邮箱），60 秒内有效，最多 3 次尝试。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EmailVerificationService {

    private final SysUserMapper userMapper;

    /** 当前待验证的邮箱 → {code, attempts, expiry}（单用户并发场景，全局单槽足够） */
    private final Map<String, VerificationSlot> slots = new ConcurrentHashMap<>();

    private static final int CODE_LENGTH = 6;
    private static final int MAX_ATTEMPTS = 3;
    private static final long TTL_MS = 60_000; // 60 秒

    /**
     * 发送 6 位验证码到指定邮箱。
     * 演示环境不真正发邮件，验证码直接返回（前端可在开发模式下展示）。
     */
    public String sendCode(Long userId, String email) {
        if (email == null || email.isBlank()) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "请先填写学校邮箱");
        }

        // 生成 6 位数字验证码
        String code = String.format("%06d", new SecureRandom().nextInt(1_000_000));
        VerificationSlot slot = new VerificationSlot(code, System.currentTimeMillis());
        slots.put(email, slot);

        log.info("验证码发送至 {}: code={} (演示模式，实际应通过邮件发送)", email, code);
        return code; // 生产环境不应返回，这里用于演示
    }

    /**
     * 验证邮箱：比对验证码 → 标记 email_verified = true
     */
    @Transactional(rollbackFor = Exception.class)
    public void verify(Long userId, String email, String code) {
        if (email == null || email.isBlank()) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "邮箱不能为空");
        }
        if (code == null || code.isBlank()) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "验证码不能为空");
        }

        // 1. 检查验证码槽
        VerificationSlot slot = slots.get(email);
        if (slot == null) {
            throw new BusinessException(ResultCode.BAD_REQUEST, "请先发送验证码");
        }
        if (System.currentTimeMillis() - slot.timestamp > TTL_MS) {
            slots.remove(email);
            throw new BusinessException(ResultCode.BAD_REQUEST, "验证码已过期（60秒），请重新发送");
        }
        if (slot.attempts >= MAX_ATTEMPTS) {
            slots.remove(email);
            throw new BusinessException(ResultCode.BAD_REQUEST, "验证码尝试次数过多，请重新发送");
        }
        slot.attempts++;

        // 2. 比对验证码
        if (!slot.code.equals(code.trim())) {
            throw new BusinessException(ResultCode.BAD_REQUEST,
                    "验证码错误，还剩 " + (MAX_ATTEMPTS - slot.attempts) + " 次机会");
        }

        // 3. 标记邮箱已验证
        SysUser patch = new SysUser();
        patch.setId(userId);
        patch.setSchoolEmail(email);
        patch.setEmailVerified(true);
        userMapper.updateById(patch);

        // 清理验证槽
        slots.remove(email);

        log.info("用户 {} 的学校邮箱 {} 验证通过", userId, email);
    }

    // ---- 内部结构 ----

    private static class VerificationSlot {
        final String code;
        final long timestamp;
        int attempts;

        VerificationSlot(String code, long timestamp) {
            this.code = code;
            this.timestamp = timestamp;
            this.attempts = 0;
        }
    }
}
