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
     * Token 版本：重置密码、改密、封禁或注销时原子递增，旧版本 JWT 一律拒绝。
     */
    private Integer tokenVersion;
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
