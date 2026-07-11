package com.zhiyi.module.user.dto;

import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

/**
 * 更新个人资料（需求 1.1 昵称可修改 / B.1 PUT /api/user/profile）
 */
@Data
public class UpdateProfileDTO {

    @Size(min = 1, max = 50, message = "昵称须为 1-50 字")
    private String nickname;

    @Pattern(regexp = "^$|^1[3-9]\\d{9}$", message = "手机号格式不正确")
    private String phone;
}
