package com.zhiyi.module.item.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("item")
public class Item {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long publisherId;
    private String type;            // SELL / BUY
    private String title;
    private String description;
    private Long categoryId;
    private BigDecimal price;
    private String images;          // JSON 数组
    private String aiTags;          // JSON 数组
    private Boolean aiReviewed;
    private String tradeLocation;
    private String status;          // ON_SALE / PENDING / SOLD / OFF_SHELF
    private Integer viewCount;
    @TableLogic
    private Boolean isDeleted;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    @TableField(fill = FieldFill.INSERT_UPDATE)
    private LocalDateTime updatedAt;
}
