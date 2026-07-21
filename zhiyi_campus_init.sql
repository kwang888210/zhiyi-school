-- ============================================================
-- 🎓 智易校园 - 数据库初始化脚本
-- 版本：v2.0
-- 日期：2026-07-07
-- 数据库：MySQL 8.0+
-- 字符集：utf8mb4（完整支持中文 + Emoji）
-- ============================================================

-- -----------------------------------------------------------
-- 1. 创建数据库
-- -----------------------------------------------------------
DROP DATABASE IF EXISTS zhiyi_campus;
CREATE DATABASE zhiyi_campus
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE zhiyi_campus;

-- ============================================================
-- 2. 建表
-- ============================================================

-- -----------------------------------------------------------
-- 2.1 sys_user — 用户表
-- -----------------------------------------------------------
CREATE TABLE sys_user (
    id              BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '用户ID',
    student_id      VARCHAR(20)     NOT NULL                 COMMENT '学号（登录凭证）',
    password        VARCHAR(255)    NOT NULL                 COMMENT 'BCrypt加密密码',
    nickname        VARCHAR(50)     NOT NULL                 COMMENT '昵称',
    phone           VARCHAR(20)     DEFAULT NULL             COMMENT '手机号',
    role            VARCHAR(20)     NOT NULL DEFAULT 'USER'  COMMENT '角色：USER/ADMIN',
    status          VARCHAR(20)     NOT NULL DEFAULT 'ACTIVE' COMMENT '状态：ACTIVE/BANNED_TEMP/BANNED_PERM/CANCELLED（已注销）',
    ban_until_time  DATETIME        DEFAULT NULL             COMMENT '封禁截止时间（临时封禁）',
    token_version   INT             NOT NULL DEFAULT 0       COMMENT 'Token版本：改密、重置、封禁和注销时原子递增',
    level           INT             NOT NULL DEFAULT 1       COMMENT '用户等级',
    exp             INT             NOT NULL DEFAULT 0       COMMENT '累计经验值',
    wallet_balance  DECIMAL(10,2)   NOT NULL DEFAULT 0.00    COMMENT '钱包余额',
    security_question VARCHAR(255)  NOT NULL                 COMMENT '密保问题',
    security_answer  VARCHAR(255)   NOT NULL                 COMMENT '密保答案（BCrypt加密）',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '注册时间',
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    UNIQUE KEY  uk_student_id (student_id),
    INDEX       idx_status (status),
    INDEX       idx_role (role)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='用户表';


-- -----------------------------------------------------------
-- 2.2 category — 大类字典表
-- -----------------------------------------------------------
CREATE TABLE category (
    id          BIGINT      NOT NULL AUTO_INCREMENT  COMMENT '分类ID',
    name        VARCHAR(50) NOT NULL                 COMMENT '分类名称',
    icon        VARCHAR(50) DEFAULT NULL             COMMENT '图标标识',
    sort_order  INT         NOT NULL DEFAULT 0       COMMENT '排序权重',
    created_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',

    PRIMARY KEY (id),
    UNIQUE KEY uk_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品大类字典表';


-- -----------------------------------------------------------
-- 2.3 item — 商品/需求表
-- -----------------------------------------------------------
CREATE TABLE item (
    id              BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '商品ID',
    publisher_id    BIGINT          NOT NULL                 COMMENT '发布者ID',
    type            VARCHAR(10)     NOT NULL                 COMMENT '类型：SELL出售/BUY求购',
    title           VARCHAR(100)    NOT NULL                 COMMENT '商品标题',
    description     TEXT            NOT NULL                 COMMENT '商品描述',
    category_id     BIGINT          NOT NULL                 COMMENT '所属大类ID',
    price           DECIMAL(10,2)   NOT NULL                 COMMENT '价格',
    images          TEXT            NOT NULL                 COMMENT '图片URL列表（JSON数组）',
    ai_tags         TEXT            DEFAULT NULL             COMMENT 'AI动态标签（JSON数组）',
    ai_reviewed     TINYINT(1)      NOT NULL DEFAULT 0       COMMENT 'AI是否已完成审核：0未审核/1已审核',
    trade_location  VARCHAR(255)    DEFAULT NULL             COMMENT '交易地点',
    status          VARCHAR(20)     NOT NULL DEFAULT 'ON_SALE' COMMENT '状态：ON_SALE/PENDING/SOLD/OFF_SHELF',
    view_count      INT             NOT NULL DEFAULT 0       COMMENT '浏览次数',
    is_deleted      TINYINT(1)      NOT NULL DEFAULT 0       COMMENT '软删除标记：0正常/1已删除',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
    updated_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',

    PRIMARY KEY (id),
    INDEX idx_status (status),
    INDEX idx_category (category_id),
    INDEX idx_publisher (publisher_id),
    INDEX idx_type (type),
    INDEX idx_created (created_at),
    CONSTRAINT fk_item_publisher  FOREIGN KEY (publisher_id) REFERENCES sys_user(id),
    CONSTRAINT fk_item_category   FOREIGN KEY (category_id)  REFERENCES category(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品/需求表';


-- -----------------------------------------------------------
-- 2.4 item_favorite — 商品收藏关联表
-- -----------------------------------------------------------
CREATE TABLE item_favorite (
    id          BIGINT      NOT NULL AUTO_INCREMENT  COMMENT '记录ID',
    user_id     BIGINT      NOT NULL                 COMMENT '收藏者ID',
    item_id     BIGINT      NOT NULL                 COMMENT '商品ID',
    created_at  DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '收藏时间',

    PRIMARY KEY (id),
    UNIQUE KEY uk_user_item (user_id, item_id),
    INDEX       idx_item (item_id),
    CONSTRAINT  fk_fav_user  FOREIGN KEY (user_id) REFERENCES sys_user(id),
    CONSTRAINT  fk_fav_item  FOREIGN KEY (item_id) REFERENCES item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品收藏关联表';


-- -----------------------------------------------------------
-- 2.5 trade_order — 交易订单表
-- -----------------------------------------------------------
CREATE TABLE trade_order (
    id              BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '订单ID',
    item_id         BIGINT          NOT NULL                 COMMENT '商品ID',
    buyer_id        BIGINT          NOT NULL                 COMMENT '买家ID',
    seller_id       BIGINT          NOT NULL                 COMMENT '卖家ID',
    price           DECIMAL(10,2)   NOT NULL                 COMMENT '成交价格',
    status          VARCHAR(20)     NOT NULL DEFAULT 'WAITING_MEET' COMMENT '状态：WAITING_MEET/COMPLETED/CANCELLED',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '下单时间',
    completed_at    DATETIME        DEFAULT NULL             COMMENT '完成时间（确认收货）',
    cancelled_at    DATETIME        DEFAULT NULL             COMMENT '取消时间',

    PRIMARY KEY (id),
    INDEX idx_buyer (buyer_id),
    INDEX idx_seller (seller_id),
    INDEX idx_status (status),
    INDEX idx_item (item_id),
    CONSTRAINT fk_order_item   FOREIGN KEY (item_id)   REFERENCES item(id),
    CONSTRAINT fk_order_buyer  FOREIGN KEY (buyer_id)  REFERENCES sys_user(id),
    CONSTRAINT fk_order_seller FOREIGN KEY (seller_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='交易订单表';


-- -----------------------------------------------------------
-- 2.6 wallet_log — 钱包资金变动流水表
-- -----------------------------------------------------------
CREATE TABLE wallet_log (
    id              BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '流水ID',
    user_id         BIGINT          NOT NULL                 COMMENT '用户ID',
    type            VARCHAR(20)     NOT NULL                 COMMENT '类型：RECHARGE充值/PAYMENT支付/REFUND退款/INCOME收入',
    amount          DECIMAL(10,2)   NOT NULL                 COMMENT '变动金额（正=收入，负=支出）',
    balance_after   DECIMAL(10,2)   NOT NULL                 COMMENT '变动后余额',
    order_id        BIGINT          DEFAULT NULL             COMMENT '关联订单ID（充值时为空）',
    remark          VARCHAR(255)    DEFAULT NULL             COMMENT '备注',
    created_at      DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '变动时间',

    PRIMARY KEY (id),
    INDEX idx_user (user_id),
    INDEX idx_order (order_id),
    INDEX idx_type (type),
    INDEX idx_created (created_at),
    CONSTRAINT fk_wallet_user  FOREIGN KEY (user_id)  REFERENCES sys_user(id),
    CONSTRAINT fk_wallet_order FOREIGN KEY (order_id) REFERENCES trade_order(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='钱包资金变动流水表';


-- -----------------------------------------------------------
-- 2.7 chat_message — 聊天消息记录表
-- -----------------------------------------------------------
CREATE TABLE chat_message (
    id                BIGINT        NOT NULL AUTO_INCREMENT  COMMENT '消息ID',
    conversation_id   VARCHAR(50)   NOT NULL                 COMMENT '会话ID（格式：小ID_大ID 或 userID_admin）',
    sender_id         BIGINT        NOT NULL                 COMMENT '发送者ID',
    receiver_id       BIGINT        NOT NULL                 COMMENT '接收者ID',
    content           TEXT          NOT NULL                 COMMENT '消息内容',
    related_item_id   BIGINT        DEFAULT NULL             COMMENT '关联商品ID',
    is_read           TINYINT(1)    NOT NULL DEFAULT 0       COMMENT '是否已读：0未读/1已读',
    created_at        DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发送时间',

    PRIMARY KEY (id),
    INDEX idx_conversation (conversation_id, created_at),
    INDEX idx_receiver_unread (receiver_id, is_read),
    INDEX idx_sender (sender_id),
    CONSTRAINT fk_chat_sender   FOREIGN KEY (sender_id)       REFERENCES sys_user(id),
    CONSTRAINT fk_chat_receiver FOREIGN KEY (receiver_id)     REFERENCES sys_user(id),
    CONSTRAINT fk_chat_item     FOREIGN KEY (related_item_id) REFERENCES item(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='聊天消息记录表';


-- -----------------------------------------------------------
-- 2.8 violation_report — AI违规上报记录表
-- -----------------------------------------------------------
CREATE TABLE violation_report (
    id                      BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '记录ID',
    user_id                 BIGINT          NOT NULL                 COMMENT '发布者ID',
    original_title          VARCHAR(100)    NOT NULL                 COMMENT '原始标题',
    original_description    TEXT            NOT NULL                 COMMENT '原始描述',
    violation_type          VARCHAR(50)     NOT NULL                 COMMENT 'AI判定违规类型',
    violation_reason        TEXT            NOT NULL                 COMMENT 'AI判定原因',
    ai_tags                 TEXT            DEFAULT NULL             COMMENT 'AI提取的标签（备用）',
    status                  VARCHAR(20)     NOT NULL DEFAULT 'PENDING' COMMENT '处理状态：PENDING待处理/CONFIRMED已确认/DISMISSED已驳回',
    handler_id              BIGINT          DEFAULT NULL             COMMENT '处理的管理员ID',
    handle_note             VARCHAR(500)    DEFAULT NULL             COMMENT '处理备注',
    item_id                 BIGINT          DEFAULT NULL             COMMENT '关联商品ID（AI拦截时创建的OFF_SHELF商品，管理员放行后改为ON_SALE）',
    ai_review_error         TINYINT(1)      NOT NULL DEFAULT 0       COMMENT 'AI是否异常：0正常/1超时或异常（待人工复核）',
    created_at              DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '上报时间',
    handled_at              DATETIME        DEFAULT NULL             COMMENT '处理时间',

    PRIMARY KEY (id),
    INDEX idx_status (status),
    INDEX idx_user (user_id),
    INDEX idx_item_id (item_id),
    CONSTRAINT fk_vr_user    FOREIGN KEY (user_id)    REFERENCES sys_user(id),
    CONSTRAINT fk_vr_handler FOREIGN KEY (handler_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='AI违规上报记录表';


-- -----------------------------------------------------------
-- 2.9 violation_log — 违规处罚日志表
-- -----------------------------------------------------------
CREATE TABLE violation_log (
    id          BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '记录ID',
    user_id     BIGINT          NOT NULL                 COMMENT '被处罚用户ID',
    admin_id    BIGINT          NOT NULL                 COMMENT '操作管理员ID',
    type        VARCHAR(20)     NOT NULL                 COMMENT '处罚类型：WARNING警告/BAN_TEMP限时封禁/BAN_PERM永久封禁',
    reason      VARCHAR(500)    NOT NULL                 COMMENT '处罚原因',
    ban_days    INT             DEFAULT NULL             COMMENT '封禁天数（限时封禁时填写）',
    created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '处罚时间',

    PRIMARY KEY (id),
    INDEX idx_user (user_id),
    INDEX idx_admin (admin_id),
    CONSTRAINT fk_vl_user  FOREIGN KEY (user_id)  REFERENCES sys_user(id),
    CONSTRAINT fk_vl_admin FOREIGN KEY (admin_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='违规处罚日志表';


-- -----------------------------------------------------------
-- 2.10 exp_log — 经验值变动记录表（模块一成长体系）
-- -----------------------------------------------------------
CREATE TABLE exp_log (
    id          BIGINT          NOT NULL AUTO_INCREMENT  COMMENT '记录ID',
    user_id     BIGINT          NOT NULL                 COMMENT '用户ID',
    delta       INT             NOT NULL                 COMMENT '变动量（+50完成订单/-30违规下架）',
    exp_after   INT             NOT NULL                 COMMENT '变动后累计经验',
    level_after INT             NOT NULL                 COMMENT '变动后等级',
    reason      VARCHAR(255)    NOT NULL                 COMMENT '变动原因',
    created_at  DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '变动时间',

    PRIMARY KEY (id),
    INDEX idx_user (user_id),
    CONSTRAINT fk_exp_user FOREIGN KEY (user_id) REFERENCES sys_user(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='经验值变动记录表';


-- ============================================================
-- 3. 初始数据
-- ============================================================

-- -----------------------------------------------------------
-- 3.1 系统管理员（账号 admin；密码与密保答案均以 BCrypt 哈希形式保存，初始化后请在本地重置）
-- -----------------------------------------------------------
INSERT INTO sys_user (student_id, password, nickname, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (
    'admin',
    '$2a$10$8Jcbe5NyLSowgw.3zOB9bOgoKCpwTuoHWLDAv0robpXmRA10hBngS',  -- BCrypt 哈希
    '系统管理员',
    'ADMIN',
    'ACTIVE',
    99,
    0,
    0.00,
    '系统预设问题',
    '$2a$10$UpZYvV84lq5Ukv7V4X154eYi795.l8klweRTlunpaf6kptgei.TJC'  -- "admin" 的 BCrypt 哈希
);

-- -----------------------------------------------------------
-- 3.2 预设商品大类（8个）
-- -----------------------------------------------------------
INSERT INTO category (name, icon, sort_order) VALUES
('数码电子', '📱', 1),
('教材书籍', '📚', 2),
('服饰鞋包', '👕', 3),
('生活日用', '🏠', 4),
('运动娱乐', '🎮', 5),
('零食饮品', '🍜', 6),
('学习用品', '📝', 7),
('其他',     '📦', 99);
