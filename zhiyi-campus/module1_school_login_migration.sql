-- Existing database migration: identify an account by school + student ID.
-- Run once against the zhiyi_campus database after backing up production data.
USE zhiyi_campus;

SET @default_school_id = (
    SELECT id
    FROM school
    WHERE code = 'SHU'
    LIMIT 1
);

UPDATE sys_user
SET school_id = @default_school_id
WHERE school_id IS NULL;

ALTER TABLE sys_user
    DROP INDEX uk_student_id,
    MODIFY school_id BIGINT NOT NULL,
    ADD UNIQUE KEY uk_school_student (school_id, student_id);
