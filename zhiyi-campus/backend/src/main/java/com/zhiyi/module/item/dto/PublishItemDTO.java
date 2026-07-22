package com.zhiyi.module.item.dto;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.Digits;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotEmpty;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Pattern;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
public class PublishItemDTO {
    @NotBlank(message = "发布类型不能为空")
    @Pattern(regexp = "SELL|BUY", message = "发布类型只能是 SELL 或 BUY")
    private String type;

    @NotBlank(message = "标题不能为空")
    @Size(min = 2, max = 50, message = "标题需为2-50字")
    private String title;

    @NotBlank(message = "描述不能为空")
    @Size(min = 10, max = 500, message = "描述需为10-500字")
    private String description;

    @NotNull(message = "所属大类不能为空")
    private Long categoryId;

    @NotNull(message = "价格不能为空")
    @DecimalMin(value = "0.01", message = "价格不能低于0.01")
    @Digits(integer = 8, fraction = 2, message = "价格最多8位整数和2位小数")
    private BigDecimal price;

    @NotEmpty(message = "至少上传1张图片")
    @Size(max = 9, message = "最多上传9张图片")
    private List<@NotBlank(message = "图片地址不能为空") String> images;

    @NotBlank(message = "交易地点不能为空")
    @Size(max = 255, message = "交易地点不能超过255字")
    private String tradeLocation;
}
