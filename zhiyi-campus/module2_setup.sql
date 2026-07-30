-- 模块二数据库增量：可在已有 zhiyi_campus 库上重复执行。
USE zhiyi_campus;

SET @item_id_exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'violation_report'
      AND column_name = 'item_id'
);
SET @add_item_id_sql = IF(
    @item_id_exists = 0,
    'ALTER TABLE violation_report ADD COLUMN item_id BIGINT NULL COMMENT ''关联商品ID'' AFTER ai_tags, ADD INDEX idx_vr_item (item_id)',
    'SELECT 1'
);
PREPARE add_item_id_stmt FROM @add_item_id_sql;
EXECUTE add_item_id_stmt;
DEALLOCATE PREPARE add_item_id_stmt;

ALTER TABLE item MODIFY COLUMN price DECIMAL(10,2) NULL COMMENT '价格/跑腿悬赏；SWAP为空';

SET @item_feature_columns = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE() AND table_name = 'item' AND column_name = 'deadline_time'
);
SET @add_item_feature_sql = IF(
    @item_feature_columns = 0,
    'ALTER TABLE item ADD COLUMN pickup_location VARCHAR(255) NULL COMMENT ''跑腿取件地点'' AFTER trade_location, ADD COLUMN delivery_location VARCHAR(255) NULL COMMENT ''跑腿送达地点'' AFTER pickup_location, ADD COLUMN deadline_time DATETIME NULL COMMENT ''期望出手/跑腿截止时间'' AFTER delivery_location, ADD INDEX idx_type_deadline (school_id, type, deadline_time)',
    'SELECT 1'
);
PREPARE add_item_feature_stmt FROM @add_item_feature_sql;
EXECUTE add_item_feature_stmt;
DEALLOCATE PREPARE add_item_feature_stmt;

CREATE TABLE IF NOT EXISTS event_topic (
    id BIGINT NOT NULL AUTO_INCREMENT,
    title VARCHAR(100) NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    filter_type VARCHAR(10) NULL,
    filter_category_id BIGINT NULL,
    filter_tag VARCHAR(50) NULL,
    banner_text VARCHAR(255) NOT NULL,
    enabled TINYINT(1) NOT NULL DEFAULT 1,
    created_by BIGINT NOT NULL,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (id),
    INDEX idx_topic_active (enabled, start_time, end_time),
    CONSTRAINT fk_topic_category FOREIGN KEY (filter_category_id) REFERENCES category(id),
    CONSTRAINT fk_topic_creator FOREIGN KEY (created_by) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='大事件专题配置';

INSERT INTO category (name, icon, sort_order) VALUES
    ('数码电子', '💻', 10),
    ('教材书籍', '📖', 20),
    ('服饰鞋包', '👟', 30),
    ('生活日用', '🛏️', 40),
    ('运动娱乐', '⚽', 50),
    ('零食饮品', '🥤', 60),
    ('学习用品', '✏️', 70),
    ('其他', '📦', 80)
ON DUPLICATE KEY UPDATE name = VALUES(name);
