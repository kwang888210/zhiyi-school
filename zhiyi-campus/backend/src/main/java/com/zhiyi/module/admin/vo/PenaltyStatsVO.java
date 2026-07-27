package com.zhiyi.module.admin.vo;

import lombok.Data;

/**
 * 用户处罚评分统计（D4：评价联动）
 * 供 A6 信誉雷达查询，将违规处罚纳入信誉计算
 */
@Data
public class PenaltyStatsVO {
    private Long userId;
    /** 累计违规确认次数 */
    private long confirmedViolations;
    /** 警告次数 */
    private long warningCount;
    /** 封禁次数（临时+永久） */
    private long banCount;
    /** 处罚对信誉的影响分（0-100，越低影响越大） */
    private int penaltyScore;
}
