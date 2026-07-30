-- Existing database migration: add the optional campus profile field.
USE zhiyi_campus;

ALTER TABLE sys_user
    ADD COLUMN campus VARCHAR(50) DEFAULT NULL
        COMMENT 'Campus for profile and marketplace proximity ranking'
        AFTER school_email;
