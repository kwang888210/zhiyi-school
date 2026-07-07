package com.zhiyi.module.admin.entity;

import com.baomidou.mybatisplus.annotation.*;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("violation_report")
public class ViolationReport {
    @TableId(type = IdType.AUTO)
    private Long id;
    private Long userId;
    private String originalTitle;
    private String originalDescription;
    private String violationType;
    private String violationReason;
    private String aiTags;
    private String status;          // PENDING / CONFIRMED / DISMISSED
    private Long handlerId;
    private String handleNote;
    private Boolean aiReviewError;

    @TableField(fill = FieldFill.INSERT)
    private LocalDateTime createdAt;

    private LocalDateTime handledAt;
}
