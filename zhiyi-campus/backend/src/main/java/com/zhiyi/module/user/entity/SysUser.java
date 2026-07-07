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
    private String status;          // ACTIVE / BANNED_TEMP / BANNED_PERM
    private LocalDateTime banUntilTime;
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
