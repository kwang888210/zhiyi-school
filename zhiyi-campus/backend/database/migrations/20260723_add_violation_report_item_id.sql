-- Keep violation reports linked to the item created by the publish workflow.
-- This migration is idempotent on MySQL 9.x and contains no credentials.

SET @schema_name = DATABASE();

SET @add_item_id = IF(
    EXISTS(
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = @schema_name
          AND TABLE_NAME = 'violation_report'
          AND COLUMN_NAME = 'item_id'
    ),
    'SELECT 1',
    'ALTER TABLE violation_report ADD COLUMN item_id BIGINT NULL AFTER user_id'
);
PREPARE add_item_id_statement FROM @add_item_id;
EXECUTE add_item_id_statement;
DEALLOCATE PREPARE add_item_id_statement;

SET @add_item_id_index = IF(
    EXISTS(
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = @schema_name
          AND TABLE_NAME = 'violation_report'
          AND INDEX_NAME = 'idx_violation_report_item_id'
    ),
    'SELECT 1',
    'ALTER TABLE violation_report ADD INDEX idx_violation_report_item_id (item_id)'
);
PREPARE add_item_id_index_statement FROM @add_item_id_index;
EXECUTE add_item_id_index_statement;
DEALLOCATE PREPARE add_item_id_index_statement;
