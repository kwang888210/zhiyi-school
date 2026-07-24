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
