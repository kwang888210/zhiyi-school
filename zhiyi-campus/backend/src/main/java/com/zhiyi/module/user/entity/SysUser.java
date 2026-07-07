package com.zhiyi.module.user.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("sys_user")
public class SysUser {
    @TableId(type = IdType.AUTO)
    private Long id;
    private String studentId;
    private String password;
    private String nickname;
    private String phone;
    private String role;            // USER / ADMIN
    private String status;          // ACTIVE / BANNED_TEMP / BANNED_PERM / CANCELLED（已注销）
    private LocalDateTime banUntilTime;
    /**
     * Token 失效纪元：签发时间早于此时刻的 JWT 一律拒绝。
     * 重置密码 / 封禁时更新为当前时间，实现"旧 Token 全部强制下线"
     */
    private LocalDateTime tokenInvalidBefore;
    private Integer level;
    private Integer exp;
    private BigDecimal walletBalance;
    private String securityQuestion;
    private String securityAnswer;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
}
