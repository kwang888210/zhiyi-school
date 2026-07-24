-- 模块一创新功能增量：school 表 / sys_user 学校与信任标签字段 / trade_review 表。
-- 幂等脚本：可在已有 zhiyi_campus 库上重复执行，不含任何凭据。

SET @schema_name = DATABASE();

-- ------------------------------------------------------------
-- 1. school 表
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS school (
    id              BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '学校ID',
    name            VARCHAR(100)    NOT NULL                 COMMENT '学校名称',
    code            VARCHAR(20)     NOT NULL                 COMMENT '学校代码（如 SHU）',
    email_domain    VARCHAR(100)    DEFAULT NULL             COMMENT '学校邮箱后缀（如 @shu.edu.cn）',
    status          VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE' COMMENT '状态：ACTIVE/DISABLED',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_code (code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='学校字典表';

-- 种子数据（code 唯一，重复执行不重复插入）
INSERT INTO school (name, code, email_domain)
SELECT '上海大学', 'SHU', '@shu.edu.cn'
WHERE NOT EXISTS (SELECT 1 FROM school WHERE code = 'SHU');
INSERT INTO school (name, code, email_domain)
SELECT '东华大学', 'DHU', '@dhu.edu.cn'
WHERE NOT EXISTS (SELECT 1 FROM school WHERE code = 'DHU');

-- ------------------------------------------------------------
-- 2. sys_user 新增列（逐列幂等）
-- ------------------------------------------------------------
SET @add_school_id = IF(
    EXISTS(SELECT 1 FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = @schema_name AND TABLE_NAME = 'sys_user' AND COLUMN_NAME = 'school_id'),
    'SELECT 1',
    'ALTER TABLE sys_user ADD COLUMN school_id BIGINT DEFAULT NULL COMMENT ''所属学校ID'' AFTER phone, ADD INDEX idx_school (school_id)'
);
PREPARE stmt FROM @add_school_id; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @add_school_email = IF(
    EXISTS(SELECT 1 FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = @schema_name AND TABLE_NAME = 'sys_user' AND COLUMN_NAME = 'school_email'),
    'SELECT 1',
    'ALTER TABLE sys_user ADD COLUMN school_email VARCHAR(100) DEFAULT NULL COMMENT ''学校邮箱'' AFTER school_id'
);
PREPARE stmt FROM @add_school_email; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @add_college = IF(
    EXISTS(SELECT 1 FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = @schema_name AND TABLE_NAME = 'sys_user' AND COLUMN_NAME = 'college'),
    'SELECT 1',
    'ALTER TABLE sys_user ADD COLUMN college VARCHAR(50) DEFAULT NULL COMMENT ''学院（自愿补全）'' AFTER school_email'
);
PREPARE stmt FROM @add_college; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @add_grade = IF(
    EXISTS(SELECT 1 FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = @schema_name AND TABLE_NAME = 'sys_user' AND COLUMN_NAME = 'grade'),
    'SELECT 1',
    'ALTER TABLE sys_user ADD COLUMN grade VARCHAR(10) DEFAULT NULL COMMENT ''年级（自愿补全）'' AFTER college'
);
PREPARE stmt FROM @add_grade; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @add_dormitory = IF(
    EXISTS(SELECT 1 FROM information_schema.COLUMNS
           WHERE TABLE_SCHEMA = @schema_name AND TABLE_NAME = 'sys_user' AND COLUMN_NAME = 'dormitory'),
    'SELECT 1',
    'ALTER TABLE sys_user ADD COLUMN dormitory VARCHAR(50) DEFAULT NULL COMMENT ''宿舍楼（自愿补全）'' AFTER grade'
);
PREPARE stmt FROM @add_dormitory; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ------------------------------------------------------------
-- 3. trade_review 表
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS trade_review (
    id          BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '评价ID',
    order_id    BIGINT          NOT NULL                 COMMENT '订单ID（一单一评）',
    reviewer_id BIGINT          NOT NULL                 COMMENT '评价者ID（买家）',
    target_id   BIGINT          NOT NULL                 COMMENT '被评价者ID（卖家）',
    rating      TINYINT         NOT NULL                 COMMENT '评分 1-5 星',
    accurate    TINYINT(1)      NOT NULL DEFAULT 1       COMMENT '描述准确：1 准确 / 0 不符',
    comment     VARCHAR(200)    DEFAULT NULL             COMMENT '评价内容',
    created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '评价时间',
    PRIMARY KEY (id),
    UNIQUE KEY uk_order (order_id),
    INDEX idx_target (target_id),
    CONSTRAINT fk_review_order    FOREIGN KEY (order_id)    REFERENCES trade_order(id),
    CONSTRAINT fk_review_reviewer FOREIGN KEY (reviewer_id) REFERENCES sys_user(id),
    CONSTRAINT fk_review_target   FOREIGN KEY (target_id)   REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='交易评价表';
