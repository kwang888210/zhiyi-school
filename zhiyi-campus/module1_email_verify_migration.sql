-- 模块一：邮箱验证迁移（A3）
-- 为 sys_user 新增 email_verified 字段
USE zhiyi_campus;

SET @email_verified_exists = (
    SELECT COUNT(*) FROM information_schema.columns
    WHERE table_schema = DATABASE()
      AND table_name = 'sys_user'
      AND column_name = 'email_verified'
);
SET @add_email_verified_sql = IF(
    @email_verified_exists = 0,
    'ALTER TABLE sys_user ADD COLUMN email_verified TINYINT(1) DEFAULT 0 COMMENT ''学校邮箱是否已验证'' AFTER school_email',
    'SELECT 1'
);
PREPARE add_email_verified_stmt FROM @add_email_verified_sql;
EXECUTE add_email_verified_stmt;
DEALLOCATE PREPARE add_email_verified_stmt;
