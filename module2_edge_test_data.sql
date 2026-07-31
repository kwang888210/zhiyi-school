-- ============================================================
-- 🧪 智易校园 · 全模块边缘测试数据 v3.0
-- 使用：mysql -u root -p --default-character-set=utf8mb4 zhiyi_campus < this_file.sql
-- 全部密码：123456
-- 密保答案：answer_用户名
-- ============================================================

SET NAMES utf8mb4;
USE zhiyi_campus;

-- -----------------------------------------------------------
-- 0. 清理
-- -----------------------------------------------------------
SET FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE exp_log;
TRUNCATE TABLE violation_log;
TRUNCATE TABLE violation_report;
TRUNCATE TABLE trade_review;
TRUNCATE TABLE wallet_log;
TRUNCATE TABLE trade_order;
TRUNCATE TABLE chat_message;
TRUNCATE TABLE item_favorite;
TRUNCATE TABLE event_topic;
DELETE FROM item WHERE id > 0;
DELETE FROM sys_user WHERE id > 1;
ALTER TABLE item AUTO_INCREMENT = 1;
ALTER TABLE sys_user AUTO_INCREMENT = 2;
ALTER TABLE trade_order AUTO_INCREMENT = 1;
ALTER TABLE wallet_log AUTO_INCREMENT = 1;
ALTER TABLE violation_report AUTO_INCREMENT = 1;
ALTER TABLE violation_log AUTO_INCREMENT = 1;
ALTER TABLE exp_log AUTO_INCREMENT = 1;
ALTER TABLE chat_message AUTO_INCREMENT = 1;
ALTER TABLE item_favorite AUTO_INCREMENT = 1;
ALTER TABLE trade_review AUTO_INCREMENT = 1;
ALTER TABLE event_topic AUTO_INCREMENT = 1;
SET FOREIGN_KEY_CHECKS = 1;

-- 种子数据（幂等）
INSERT IGNORE INTO school (id, name, code, email_domain) VALUES
(1, '上海大学', 'SHU', '@shu.edu.cn'),
(2, '东华大学', 'DHU', '@dhu.edu.cn');

-- admin（密码 123456）
INSERT IGNORE INTO sys_user (id, student_id, password, nickname, school_id, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (1, 'admin', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K',
    '系统管理员', (SELECT id FROM school WHERE code='SHU'), 'ADMIN', 'ACTIVE', 99, 0, 0.00,
    '系统预设问题', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K');

UPDATE sys_user SET password='$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K' WHERE student_id='admin';

-- ============================================================
-- 1. 用户（全部密码 123456，密保答案 answer_用户名）
-- ============================================================

-- 1.1 资深卖家小王(上大·计算机·南区3号楼·已认证)
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, school_email, email_verified, campus, college, grade, dormitory, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (2, '2024001', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K',
    '资深卖家小王', '13800001001',
    (SELECT id FROM school WHERE code='SHU'), 'wang@shu.edu.cn', 1,
    '宝山校区', '计算机学院', '2024级', '南区3号楼',
    'USER', 'ACTIVE', 5, 420, 500.00,
    '你的小学校名？', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K');

-- 1.2 买家小李(上大·同学院同级同楼——信任标签匹配)
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, school_email, email_verified, campus, college, grade, dormitory, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (3, '2024002', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K',
    '买家小李', '13800001002',
    (SELECT id FROM school WHERE code='SHU'), 'li@shu.edu.cn', 1,
    '宝山校区', '计算机学院', '2024级', '南区3号楼',
    'USER', 'ACTIVE', 3, 180, 2000.00,
    '你的小学校名？', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K');

-- 1.3 毕业学姐(上大·外语学院·南区5号楼)
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, school_email, email_verified, campus, college, grade, dormitory, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (4, '2024003', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K',
    '毕业清仓学姐', '13800001003',
    (SELECT id FROM school WHERE code='SHU'), NULL, 0,
    '宝山校区', '外语学院', '2023级', '南区5号楼',
    'USER', 'ACTIVE', 8, 850, 100.50,
    '你的小学校名？', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K');

-- 1.4 东华新生(东华·纺织学院)
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, school_email, email_verified, campus, college, grade, dormitory, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (5, '2024004', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K',
    '新生小张', '13800001004',
    (SELECT id FROM school WHERE code='DHU'), NULL, 0,
    '松江校区', '纺织学院', '2025级', NULL,
    'USER', 'ACTIVE', 2, 80, 50.00,
    '你的小学校名？', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K');

-- 1.5 临时封禁
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, school_email, email_verified, campus, college, grade, dormitory, role, status, level, exp, wallet_balance, ban_until_time, token_version, security_question, security_answer)
VALUES (6, '2024005', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K',
    '违规用户A', '13800001005',
    (SELECT id FROM school WHERE code='SHU'), NULL, 0,
    NULL, NULL, NULL, NULL,
    'USER', 'BANNED_TEMP', 2, 30, 25.00, DATE_ADD(NOW(), INTERVAL 30 DAY), 1,
    '你的小学校名？', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K');

-- 1.6 永久封禁
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, school_email, email_verified, campus, college, grade, dormitory, role, status, level, exp, wallet_balance, token_version, security_question, security_answer)
VALUES (7, '2024006', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K',
    '永久封禁B', '13800001006',
    (SELECT id FROM school WHERE code='SHU'), NULL, 0,
    NULL, NULL, NULL, NULL,
    'USER', 'BANNED_PERM', 1, 0, 0.00, 10,
    '你的小学校名？', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K');

-- 1.7 已注销
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, school_email, email_verified, campus, college, grade, dormitory, role, status, level, exp, wallet_balance, token_version, security_question, security_answer)
VALUES (8, '2024007', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K',
    '已注销用户C', '13800001007',
    (SELECT id FROM school WHERE code='SHU'), NULL, 0,
    NULL, NULL, NULL, NULL,
    'USER', 'CANCELLED', 1, 50, 10.00, 5,
    '你的小学校名？', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K');

-- 1.8 边缘(零余额零经验)
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, school_email, email_verified, campus, college, grade, dormitory, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (9, '2024008', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K',
    '边缘用户零钱', '13800001008',
    (SELECT id FROM school WHERE code='SHU'), NULL, 0,
    NULL, NULL, NULL, NULL,
    'USER', 'ACTIVE', 1, 0, 0.00,
    '你的小学校名？', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K');

-- 1.9 高等级大佬(东华·材料学院)
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, school_email, email_verified, campus, college, grade, dormitory, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (10, '2024009', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K',
    '大佬陈哥', '13800001009',
    (SELECT id FROM school WHERE code='DHU'), 'chen@dhu.edu.cn', 1,
    '松江校区', '材料学院', '2024级', '松江校区1号楼',
    'USER', 'ACTIVE', 15, 12000, 5000.00,
    '你的小学校名？', '$2a$10$or0s3jeC85J07b8HcY9wfOJDE0gegLcyYkjFLn0yr.BE8koej.A1K');

-- ============================================================
-- 2. 商品（SELL/BUY/SWAP/ERRAND）
-- ============================================================

-- 2.1 iPad（多图·高浏览·上大）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (2, 1, 'SELL',
    '99新 iPad Air5 256G 考研结束出',
    '去年九月购入，主要用于看网课和笔记，全程戴壳贴膜无划痕。配件齐全含原装充电器和包装盒。考研上岸故出。',
    1, 3200.00,
    '["/uploads/items/20260701/ipad1.png","/uploads/items/20260701/ipad2.png","/uploads/items/20260701/ipad3.png"]',
    '["iPad","苹果","考研","平板"]', true, '图书馆门口', 'ON_SALE', 128);

-- 2.2 求购高数（BUY·上大）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (3, 1, 'BUY',
    '求购二手高数上册同济版',
    '大一新生，想收一本有笔记的高数上册，价格可议。',
    2, 15.00,
    '["/uploads/items/20260702/buy_book.png"]',
    '["高数","教材","求购","同济"]', true, '一食堂', 'ON_SALE', 45);

-- 2.3 索尼耳机（9图·上大）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (4, 1, 'SELL',
    '索尼WH-1000XM5 头戴降噪耳机 箱说全',
    '年会抽奖中的，仅拆封试戴过一次，几乎全新。包装配件齐全，发票也在。',
    1, 1800.00,
    '["/uploads/items/20260703/p1.png","/uploads/items/20260703/p2.png","/uploads/items/20260703/p3.png","/uploads/items/20260703/p4.png","/uploads/items/20260703/p5.png","/uploads/items/20260703/p6.png","/uploads/items/20260703/p7.png","/uploads/items/20260703/p8.png","/uploads/items/20260703/p9.png"]',
    '["耳机","索尼","降噪","全新"]', true, '南门快递站', 'ON_SALE', 56);

-- 2.4 台灯（有deadline·上大）—— B5/B6倒计时
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, deadline_time, status, view_count)
VALUES (2, 1, 'SELL',
    'LED触控调光台灯 毕业离校前出',
    '宿舍用LED台灯，触控调光，毕业离校前出手。',
    4, 25.00,
    '["/uploads/items/20260704/lamp.png"]',
    '["台灯","LED","宿舍"]', true, '体育馆', DATE_ADD(NOW(), INTERVAL 5 DAY), 'ON_SALE', 12);

-- 2.5 贴纸0.01元（最低价·上大）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (4, 1, 'SELL',
    '闲置小贴纸免费送',
    '一些闲置的贴纸，需要的同学来拿就好。',
    8, 0.01,
    '["/uploads/items/20260705/sticker.png"]',
    '["贴纸","免费"]', true, '体育馆', 'ON_SALE', 200);

-- 2.6 机械键盘 PENDING（已被下单·上大）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (2, 1, 'SELL',
    '机械键盘Cherry红轴',
    'Cherry红轴机械键盘，用了半年，成色新，送拔键器。',
    1, 200.00,
    '["/uploads/items/20260711/keyboard.png"]',
    '["键盘","机械","Cherry"]', true, '图书馆门口', 'PENDING', 156);

-- 2.7 鼠标 SOLD（已售出·上大）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (2, 1, 'SELL',
    '罗技G502无线鼠标',
    '罗技G502 Lightspeed，95新，箱说全。',
    1, 350.00,
    '["/uploads/items/20260712/mouse.png"]',
    '["鼠标","罗技","无线"]', true, '南门快递站', 'SOLD', 320);

-- 2.8 路由器 OFF_SHELF（用户主动下架·上大）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (4, 1, 'SELL',
    '不卖了的路由器',
    '本来想卖但决定继续用。',
    1, 80.00,
    '["/uploads/items/20260713/router.png"]',
    '["路由器"]', true, '体育馆', 'OFF_SHELF', 22);

-- 2.9 AI违规拦截 OFF_SHELF（关联violation_report·上大）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (2, 1, 'SELL',
    '测试违规商品标题',
    '包含违规信息的测试商品，被AI拦截。',
    8, 99.00,
    '["/uploads/items/20260714/test.png"]',
    '["测试"]', true, '一食堂', 'OFF_SHELF', 5);

-- 2.10 AI异常降级（ON_SALE但ai_reviewed=false·东华）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (5, 2, 'SELL',
    '华为Mate60 Pro手机壳',
    '买错型号了，全新未使用透明防摔手机壳。',
    1, 15.00,
    '["/uploads/items/20260715/case.png"]',
    '["手机壳","华为"]', false, '南门快递站', 'ON_SALE', 11);

-- 2.11 Switch大全套（东华·6标签）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (10, 2, 'SELL',
    'Switch OLED + 塞尔达 + 健身环大全套',
    'Switch OLED白色款，带王国之泪卡带和健身环大冒险，送收纳包和钢化膜。',
    5, 2200.00,
    '["/uploads/items/20260717/switch1.png","/uploads/items/20260717/switch2.png"]',
    '["Switch","塞尔达","健身环","游戏","OLED","大全套"]', true, '图书馆门口', 'ON_SALE', 189);

-- 2.12 软删除（is_deleted=1·不出现在大厅）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (2, 1, 'SELL',
    '已删除的商品',
    '这个商品已被用户删除，不应出现在大厅。',
    8, 1.00,
    '["/uploads/items/20260718/deleted.png"]',
    '["已删除"]', true, '一食堂', 'OFF_SHELF', 3, true);

-- 2.13 iPhone异常低价（OFF_SHELF·价格欺诈拦截·上大）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (2, 1, 'SELL',
    'iPhone 15 Pro Max',
    '全新未拆封。',
    1, 1.00,
    '["/uploads/items/20260721/iphone.png"]',
    '["iPhone","苹果"]', true, '图书馆门口', 'OFF_SHELF', 10);

-- 2.14 iPad配件正常低价（AI不应误判·上大）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (4, 1, 'SELL',
    'iPad Air5保护壳和钢化膜',
    '换新iPad了，旧的保护壳和钢化膜免费送。',
    1, 1.00,
    '["/uploads/items/20260722/ipadcase.png"]',
    '["iPad","保护壳","配件"]', true, '南门快递站', 'ON_SALE', 67);

-- 2.15 SWAP：高数下册换四级真题（上大）—— B1/B2
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (4, 1, 'SWAP',
    '《高等数学（下）》有笔记，换《大学英语四级真题2025版》',
    '高数下册保存完好，笔记工整。想换一本四级真题备考。',
    2, NULL,
    '["/uploads/items/20260723/2d58101ba82d42cb99eb5b99129b32b3.png"]',
    '["高数","教材","换物","四级"]', true, '一食堂', 'ON_SALE', 34);

-- 2.16 SWAP：四级真题换高数下册（上大·与2.15双向匹配）—— B2
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (3, 1, 'SWAP',
    '《大学英语四级真题2025版》换《高数下册》',
    '四级已过，真题几乎全新。需要一本高数下。',
    2, NULL,
    '["/uploads/items/20260723/2d82e606623b4657982ba80453873ee2.png"]',
    '["四级","真题","换物","高数"]', true, '图书馆门口', 'ON_SALE', 28);

-- 2.17 ERRAND：打印跑腿（上大·2小时后截止）—— B3/B4
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, pickup_location, delivery_location, deadline_time, status, view_count)
VALUES (3, 1, 'ERRAND',
    '帮忙去打印店打印5页PPT送到自习室',
    '在图书馆不想动，帮忙去南门打印店打印5页PPT送到自习室三楼。小报酬3元。',
    8, 3.00,
    '["/uploads/items/20260723/2f3b4fe8fa874cc7a6a039c99c85125a.png"]',
    '["跑腿","打印"]', true,
    '南门打印店', '南门打印店', '自习室三楼',
    DATE_ADD(NOW(), INTERVAL 2 HOUR), 'ON_SALE', 15);

-- 2.18 ERRAND：代取快递（东华·4小时后截止）—— B4学校隔离
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, pickup_location, delivery_location, deadline_time, status, view_count)
VALUES (5, 2, 'ERRAND',
    '帮忙去菜鸟驿站取个快递送到宿舍楼下',
    '今天下午5点前送到松江校区2号楼。小件不重，5元报酬。',
    8, 5.00,
    '["/uploads/items/20260724/42e96ddea9d44a5792d1fb572c04122a.png"]',
    '["跑腿","快递"]', true,
    '菜鸟驿站', '菜鸟驿站', '松江校区2号楼',
    DATE_ADD(NOW(), INTERVAL 4 HOUR), 'ON_SALE', 22);

-- 2.19 Mac Pro天价（东华·99999.99·学校隔离验证用）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (10, 2, 'SELL',
    '顶配Mac Pro全套工作站',
    '顶配Mac Pro全套出售，带显示器键鼠打包，价格可小刀。',
    1, 99999.99,
    '["/uploads/items/20260706/macpro.png"]',
    '["Mac","顶配","工作站"]', true, '图书馆门口', 'ON_SALE', 999);

-- 2.20 PS5（emoji标题·上大）—— 以上是原始全部商品，以下是补充边缘测试
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (4, 1, 'SELL',
    '🎮 PS5 光驱版 + 双手柄',
    '港版PS5光驱版，带两个原装手柄和底座，箱说全。',
    5, 3000.00,
    '["/uploads/items/20260720/ps5.png"]',
    '["PS5","游戏机","索尼","手柄"]', true, '体育馆', 'ON_SALE', 234);

-- 2.21 最短标题（2字）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (2, 1, 'SELL',
    '水杯',
    '一个闲置的星巴克联名保温杯用过几次成色不错保温效果很好。',
    4, 35.00,
    '["/uploads/items/20260707/cup.png"]',
    '["水杯","保温杯","星巴克"]', true, '一食堂', 'ON_SALE', 88);

-- 2.22 最长标题（50字·Emoji）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (4, 1, 'SELL',
    '全新未拆封苹果AirPods Pro第二代USB-C接口主动降噪蓝牙耳机白色',
    '朋友送的生日礼物但我已经有一副了所以全新未拆封转卖。',
    1, 1500.00,
    '["/uploads/items/20260708/airpods.png"]',
    '["AirPods","苹果","耳机","全新","降噪"]', true, '图书馆门口', 'ON_SALE', 66);

-- 2.23 最短描述（10字）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (2, 1, 'SELL',
    '羽毛球拍一对',
    '闲置羽毛球拍一对便宜出。',
    5, 50.00,
    '["/uploads/items/20260709/badminton.png"]',
    '["羽毛球","运动"]', true, '体育馆', 'ON_SALE', 33);

-- 2.24 最长描述（约500字·ThinkPad）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (10, 2, 'SELL',
    'ThinkPad X1 Carbon Gen9 商务本',
    '这是一台陪伴我度过三年研究生生涯的笔记本电脑它见证了我从小白成长为能独立完成项目的程序员这台电脑陪我熬过无数深夜陪我完成毕设陪我找到第一份工作现在我换了新设备希望它能继续陪伴下一位有缘人机器的配置是i7处理器16G内存512G固态14寸2K杜比视界屏幕显示效果出色键盘手感是ThinkPad一贯的高水准打字非常舒服重量不到一公斤非常轻薄便携适合每天背着去图书馆或教室电池还能用四到五小时满足一天学习需求外观有些轻微使用痕迹角落有点掉漆但不影响使用整体九成新配件齐全带原装充电器还送一个联想原装笔记本包。',
    1, 4500.00,
    '["/uploads/items/20260710/thinkpad1.png","/uploads/items/20260710/thinkpad2.png"]',
    '["ThinkPad","笔记本","轻薄","i7","商务"]', true, '图书馆门口', 'ON_SALE', 77);

-- 2.25 充电宝（正常商品·东华）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (5, 2, 'SELL',
    '全新未拆封小米充电宝20000mAh',
    '年会发的全新小米充电宝20000mAh未拆封。',
    1, 80.00,
    '["/uploads/items/20260719/charger.png"]',
    '["小米","充电宝","全新"]', true, '南门快递站', 'ON_SALE', 44);

-- 2.26 BUY求购篮球（东华·OFF_SHELF下架状态）
INSERT INTO item (publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count)
VALUES (5, 2, 'BUY',
    '求购二手篮球一个',
    '想收一个二手篮球，室外用的就行，成色无所谓只要还能打。',
    5, 25.00,
    '["/uploads/items/20260716/ball.png"]',
    '["篮球","体育","求购"]', true, '体育馆', 'OFF_SHELF', 8);

-- ============================================================
-- 3. 交易订单
-- ============================================================

-- 3.1 WAITING_MEET：东华新生买了小王的机械键盘(跨校——会被拒绝，仅测试用)
INSERT INTO trade_order (item_id, buyer_id, seller_id, price, status)
VALUES (6, 5, 2, 200.00, 'WAITING_MEET');

-- 3.2 COMPLETED：小李买了小王的鼠标
INSERT INTO trade_order (item_id, buyer_id, seller_id, price, status, completed_at)
VALUES (7, 3, 2, 350.00, 'COMPLETED', DATE_SUB(NOW(), INTERVAL 2 DAY));

-- 3.3 CANCELLED：东华新生取消订单
INSERT INTO trade_order (item_id, buyer_id, seller_id, price, status, cancelled_at)
VALUES (2, 5, 3, 15.00, 'CANCELLED', DATE_SUB(NOW(), INTERVAL 1 DAY));

-- 3.4 COMPLETED：东华新生买了陈哥的Switch
INSERT INTO trade_order (item_id, buyer_id, seller_id, price, status, completed_at)
VALUES (11, 5, 10, 2200.00, 'COMPLETED', DATE_SUB(NOW(), INTERVAL 5 DAY));

-- 3.5 COMPLETED：小李买了学姐的耳机（传承链第一手）
INSERT INTO trade_order (item_id, buyer_id, seller_id, price, status, completed_at)
VALUES (3, 3, 4, 1800.00, 'COMPLETED', DATE_SUB(NOW(), INTERVAL 10 DAY));

-- 3.6 COMPLETED：东华新生从小李处买了耳机（传承链第二手——D3传承链）
INSERT INTO trade_order (item_id, buyer_id, seller_id, price, status, completed_at)
VALUES (3, 5, 3, 1600.00, 'COMPLETED', DATE_SUB(NOW(), INTERVAL 3 DAY));

-- ============================================================
-- 4. 钱包流水
-- ============================================================

INSERT INTO wallet_log (user_id, type, amount, balance_after, remark) VALUES (3, 'RECHARGE', 2000.00, 2000.00, '初始充值');
INSERT INTO wallet_log (user_id, type, amount, balance_after, remark) VALUES (2, 'RECHARGE', 500.00, 500.00, '初始充值');
INSERT INTO wallet_log (user_id, type, amount, balance_after, remark) VALUES (9, 'RECHARGE', 0.01, 0.01, '最小充值测试');
INSERT INTO wallet_log (user_id, type, amount, balance_after, order_id, remark) VALUES (3, 'PAYMENT', -350.00, 1650.00, 2, '购买鼠标');
INSERT INTO wallet_log (user_id, type, amount, balance_after, order_id, remark) VALUES (2, 'INCOME', 350.00, 850.00, 2, '售出鼠标收入');
INSERT INTO wallet_log (user_id, type, amount, balance_after, order_id, remark) VALUES (5, 'PAYMENT', -2200.00, -2150.00, 4, '购买Switch');
INSERT INTO wallet_log (user_id, type, amount, balance_after, order_id, remark) VALUES (10, 'INCOME', 2200.00, 7200.00, 4, '售出Switch收入');
INSERT INTO wallet_log (user_id, type, amount, balance_after, order_id, remark) VALUES (5, 'REFUND', 15.00, -2135.00, 3, '订单取消退款');

-- ============================================================
-- 5. 违规记录
-- ============================================================

-- 5.1 PENDING：AI内容违规(关联item 9)
INSERT INTO violation_report (user_id, item_id, original_title, original_description, violation_type, violation_reason, ai_tags, status, ai_review_error)
VALUES (2, 9, '测试违规商品标题', '包含违规信息的测试商品。', 'CONTENT_VIOLATION', '内容包含平台禁止发布的信息：代写', '["测试","违规"]', 'PENDING', false);

-- 5.2 PENDING：AI异常(关联item 10·东华)
INSERT INTO violation_report (user_id, item_id, original_title, original_description, violation_type, violation_reason, ai_tags, status, ai_review_error)
VALUES (5, 10, '华为Mate60 Pro手机壳', '买错型号了，全新未使用。', 'AI_REVIEW_ERROR', 'AI审核服务暂不可用，已转人工复核', '["手机壳","华为"]', 'PENDING', true);

-- 5.3 PENDING：价格异常(关联item 13·iPhone 1元)
INSERT INTO violation_report (user_id, item_id, original_title, original_description, violation_type, violation_reason, ai_tags, status, ai_review_error)
VALUES (2, 13, 'iPhone 15 Pro Max', '全新未拆封。', 'CONTENT_VIOLATION', '商品价格¥1.00与标题型号明显不符，疑似虚假价格', '["iPhone","苹果"]', 'PENDING', false);

-- 5.4 CONFIRMED：已确认(历史·seller1)——D4评价联动测试
INSERT INTO violation_report (user_id, item_id, original_title, original_description, violation_type, violation_reason, ai_tags, status, handler_id, handle_note, handled_at, ai_review_error)
VALUES (2, NULL, '代写期末论文', '专业代写各科期末论文保证通过。', 'CONTENT_VIOLATION', '涉及代考代写学术不端服务', '["代写","论文"]', 'CONFIRMED', 1, '确认违规，已封禁用户', DATE_SUB(NOW(), INTERVAL 3 DAY), false);

-- 5.5 DISMISSED：已驳回(历史·小李)
INSERT INTO violation_report (user_id, item_id, original_title, original_description, violation_type, violation_reason, ai_tags, status, handler_id, handle_note, handled_at, ai_review_error)
VALUES (3, NULL, '二手教材转让', '转让大学英语四级教材和辅导书。', 'CONTENT_VIOLATION', '疑似广告引流', '["教材","四级"]', 'DISMISSED', 1, '误判，正常教材转让', DATE_SUB(NOW(), INTERVAL 2 DAY), false);

-- 5.6 PENDING：无关联商品(边界测试)
INSERT INTO violation_report (user_id, item_id, original_title, original_description, violation_type, violation_reason, ai_tags, status, ai_review_error)
VALUES (7, NULL, '无商品关联的违规', '边界测试：无关联商品。', 'CONTENT_VIOLATION', '边界测试', '["测试"]', 'PENDING', false);

-- ============================================================
-- 6. 处罚日志
-- ============================================================
INSERT INTO violation_log (user_id, admin_id, type, reason, ban_days) VALUES (6, 1, 'WARNING', '首次违规发布，给予警告。', NULL);
INSERT INTO violation_log (user_id, admin_id, type, reason, ban_days) VALUES (6, 1, 'BAN_TEMP', '再次违规，限时封禁30天。', 30);
INSERT INTO violation_log (user_id, admin_id, type, reason, ban_days) VALUES (7, 1, 'BAN_PERM', '多次严重违规，永久封禁。', NULL);
INSERT INTO violation_log (user_id, admin_id, type, reason, ban_days) VALUES (2, 1, 'WARNING', '发布代写论文信息。', NULL);

-- ============================================================
-- 7. 经验流水
-- ============================================================
INSERT INTO exp_log (user_id, delta, exp_after, level_after, reason) VALUES (2, 50, 420, 5, '订单#2完成：卖家奖励');
INSERT INTO exp_log (user_id, delta, exp_after, level_after, reason) VALUES (3, 50, 180, 3, '订单#2完成：买家奖励');
INSERT INTO exp_log (user_id, delta, exp_after, level_after, reason) VALUES (2, -30, 390, 5, '商品被管理员强制下架');
INSERT INTO exp_log (user_id, delta, exp_after, level_after, reason) VALUES (6, -30, 0, 2, '违规扣经验至零边界');
INSERT INTO exp_log (user_id, delta, exp_after, level_after, reason) VALUES (8, -100, 0, 1, '扣经验超过当前值边界测试');

-- ============================================================
-- 8. 交易评价（A6/A7信誉 + D4评价联动）
-- ============================================================

-- 8.1 高分好评：小李→小王(order#2)
INSERT INTO trade_review (order_id, reviewer_id, target_id, rating, accurate, comment)
VALUES (2, 3, 2, 5, 1, '卖家很靠谱，鼠标成色如描述，当面交易很愉快！');

-- 8.2 低分差评：小张→陈哥(order#4)
INSERT INTO trade_review (order_id, reviewer_id, target_id, rating, accurate, comment)
VALUES (4, 5, 10, 2, 0, '描述说几乎全新但有划痕，不太满意。');

-- 8.3 中等评价：小李→学姐(order#5·传承链第一手)
INSERT INTO trade_review (order_id, reviewer_id, target_id, rating, accurate, comment)
VALUES (5, 3, 4, 3, 1, '耳机不错，学姐人很好。');

-- ============================================================
-- 9. 收藏
-- ============================================================
INSERT INTO item_favorite (user_id, item_id) VALUES (3, 1), (3, 3), (3, 11), (5, 1), (5, 3), (10, 1), (9, 11);

-- ============================================================
-- 10. 聊天消息
-- ============================================================

-- 买卖对话
INSERT INTO chat_message (conversation_id, sender_id, receiver_id, content, related_item_id, is_read)
VALUES ('2_3', 3, 2, '你好，iPad还在吗？', 1, true);
INSERT INTO chat_message (conversation_id, sender_id, receiver_id, content, related_item_id, is_read)
VALUES ('2_3', 2, 3, '在的，成色很新。', 1, true);
INSERT INTO chat_message (conversation_id, sender_id, receiver_id, content, related_item_id, is_read)
VALUES ('2_3', 3, 2, '可以便宜点吗？', 1, false);

-- 客服对话
INSERT INTO chat_message (conversation_id, sender_id, receiver_id, content, is_read)
VALUES ('1_3', 3, 1, '你好客服，我想问一下如何修改昵称？', true);
INSERT INTO chat_message (conversation_id, sender_id, receiver_id, content, is_read)
VALUES ('1_3', 1, 3, '在个人中心页面可以修改昵称。', false);

-- 系统消息
INSERT INTO chat_message (conversation_id, sender_id, receiver_id, content, is_read)
VALUES ('1_2', 1, 2, '🎉 恭喜！你的等级提升至 LV5！继续加油！', false);

-- 东华用户对话
INSERT INTO chat_message (conversation_id, sender_id, receiver_id, content, related_item_id, is_read)
VALUES ('5_10', 5, 10, '陈哥，Switch还在吗？可以面交吗？', 11, true);

-- ============================================================
-- 11. 大事件专题（B8/C5）
-- 专题是智能筛选器：点击首页横幅 → 自动搜索对应分类/标签
-- ============================================================

-- 暑期闲置处理（当前有效——7月30日在这个区间内）
INSERT INTO event_topic (title, start_time, end_time, filter_type, filter_category_id, filter_tag, banner_text, enabled, created_by)
VALUES ('☀️ 暑期闲置处理', '2026-07-01 00:00:00', '2026-08-31 23:59:59', 'SELL', NULL, NULL, '暑假清仓大甩卖！闲置变现，开学有钱花~', 1, 1);

-- 新生入学季（8/25-9/15）
INSERT INTO event_topic (title, start_time, end_time, filter_type, filter_category_id, filter_tag, banner_text, enabled, created_by)
VALUES ('🎓 新生入学季', '2026-08-25 00:00:00', '2026-09-15 23:59:59', 'SELL', 4, NULL, '欢迎新同学！日用品、学习用品一站配齐~', 1, 1);

-- 期末备考季（12/20-1/20）—— 点击自动筛选教材书籍
INSERT INTO event_topic (title, start_time, end_time, filter_type, filter_category_id, filter_tag, banner_text, enabled, created_by)
VALUES ('📝 期末备考季', '2026-12-20 00:00:00', '2027-01-20 23:59:59', 'SELL', 2, NULL, '期末冲刺！笔记、真题、参考资料应有尽有', 1, 1);

-- 毕业清仓季（5/25-6/30）—— 已过期，历史参考
INSERT INTO event_topic (title, start_time, end_time, filter_type, filter_category_id, filter_tag, banner_text, enabled, created_by)
VALUES ('🎉 毕业清仓季', '2026-05-25 00:00:00', '2026-06-30 23:59:59', 'SELL', NULL, '毕业', '又是一年毕业季！学长学姐清仓甩卖，快来捡漏！', 1, 1);

-- ============================================================
-- 完成
-- ============================================================
SELECT '============================================' AS '';
SELECT '  全部测试数据导入完成！' AS '';
SELECT '  🔑 所有账号密码：123456' AS '';
SELECT '============================================' AS '';
