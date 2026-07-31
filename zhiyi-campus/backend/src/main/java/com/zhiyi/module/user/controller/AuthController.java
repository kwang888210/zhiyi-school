package com.zhiyi.module.user.controller;

import com.zhiyi.common.Result;
import com.zhiyi.module.user.dto.LoginDTO;
import com.zhiyi.module.user.dto.RegisterDTO;
import com.zhiyi.module.user.dto.ResetPasswordDTO;
import com.zhiyi.module.user.service.AuthService;
import com.zhiyi.module.user.service.EmailVerificationService;
import com.zhiyi.module.user.vo.LoginVO;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.RequiredArgsConstructor;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

/**
 * 模块一：认证接口（B.1 附录接口清单）
 *
 * POST /api/auth/register           用户注册
 * POST /api/auth/login              用户登录
 * GET  /api/auth/security-question  获取密保问题（?schoolId=1&studentId=xxx）
 * GET  /api/auth/security-questions 预设密保问题列表（注册页下拉用）
 * POST /api/auth/reset-password     验证密保并重置密码
 */
@Validated
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;
    private final EmailVerificationService emailVerificationService;

    @PostMapping("/register")
    public Result<LoginVO> register(@Valid @RequestBody RegisterDTO dto) {
        return Result.ok("注册成功", authService.register(dto));
    }

    @PostMapping("/login")
    public Result<LoginVO> login(@Valid @RequestBody LoginDTO dto) {
        return Result.ok("登录成功", authService.login(dto));
    }

    @GetMapping("/security-question")
    public Result<Map<String, String>> securityQuestion(
            @RequestParam @NotNull(message = "请选择所属学校") Long schoolId,
            @RequestParam @NotBlank(message = "学号不能为空") String studentId) {
        return Result.ok(Map.of("question", authService.getSecurityQuestion(schoolId, studentId)));
    }

    @GetMapping("/security-questions")
    public Result<List<String>> securityQuestions() {
        return Result.ok(AuthService.SECURITY_QUESTIONS);
    }

    @PostMapping("/reset-password")
    public Result<Void> resetPassword(@Valid @RequestBody ResetPasswordDTO dto) {
        authService.resetPassword(dto);
        return Result.ok("密码重置成功，请重新登录", null);
    }

    /**
     * 发送学校邮箱验证码（A3）
     */
    @PostMapping("/send-verify-code")
    public Result<Map<String, String>> sendVerifyCode(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        String email = request.getParameter("email");
        String code = emailVerificationService.sendCode(userId, email);
        // 演示模式：返回验证码（生产环境应删除此字段）
        return Result.ok(Map.of("code", code, "message", "验证码已发送至 " + email));
    }

    /**
     * 验证学校邮箱（A3）
     */
    @PostMapping("/verify-email")
    public Result<?> verifyEmail(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        String email = request.getParameter("email");
        String code = request.getParameter("code");
        emailVerificationService.verify(userId, email, code);
        return Result.ok("邮箱验证成功 ✅");
    }

}
