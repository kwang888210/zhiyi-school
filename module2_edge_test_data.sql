-- ============================================================
-- 🧪 智易校园 · 全模块边缘测试数据 v1.0
-- 覆盖：A(用户) / B(AI发布) / C(大厅社交) / D(交易管理)
-- 使用方式：mysql -u root -p zhiyi_campus < this_file.sql
-- 密码：所有测试用户密码 = 用户名本身（如 seller1/seller1）
--       密保答案 = answer_用户名
-- ============================================================

-- 修复 Windows 终端 GBK 乱码：强制客户端使用 utf8mb4
SET NAMES utf8mb4;

USE zhiyi_campus;

-- -----------------------------------------------------------
-- 0. 清理已有测试数据（保留表结构）
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
DELETE FROM item WHERE id > 0;
DELETE FROM sys_user WHERE id > 1;   -- 保留 init.sql 的 admin
DELETE FROM school WHERE id NOT IN (1, 2);  -- 保留种子数据：上海大学、东华大学
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
SET FOREIGN_KEY_CHECKS = 1;

-- ============================================================
-- 1. 用户表 sys_user（模块 A 边缘数据）
-- 密码均为用户名本身；密保答案 = answer_用户名
-- ============================================================

-- 1.1 正常卖家（经验丰富）
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, college, grade, dormitory, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (2, '2024001', '$2b$12$LE/f2Hagvn9EYF.3FA9vnukVHee4b108VaNBNGldpCKlltMQ6.qDG',
        '资深卖家小王', '13800001001', (SELECT id FROM school WHERE code = 'SHU'), '计算机学院', '2024', '南区3号楼',
        'USER', 'ACTIVE', 5, 420, 500.00,
        '你的小学校名？', '$2b$12$pEQMRAg0AbN5Zc7s99o9Xe2ojCwYH/jthbtw.altR5Ferzqt6AMk.');

-- 1.2 正常买家
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, college, grade, dormitory, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (3, '2024002', '$2b$12$iCYPARzgkO44117qVXzaluww/rRM0zjFUfwHYzeVYNi462kOMb4EC',
        '买家小李', '13800001002', (SELECT id FROM school WHERE code = 'SHU'), '计算机学院', '2024', '南区3号楼',
        'USER', 'ACTIVE', 3, 180, 2000.00,
        '你的小学校名？', '$2b$12$xU9Y5czXUwy3R.fuqGVYeu9s1GligF4b7SMuvtS8Uq60Fgy/vtk8u');

-- 1.3 第二个卖家（高等级）
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, college, grade, dormitory, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (4, '2024003', '$2b$12$0fJ.ul4047LbL6AIAfLgb.97ykm0ejHJfgO4bcPdSYWOn5h40lzgS',
        '毕业清仓学姐', '13800001003', (SELECT id FROM school WHERE code = 'SHU'), '外语学院', '2023', '南区5号楼',
        'USER', 'ACTIVE', 8, 850, 100.50,
        '你的小学校名？', '$2b$12$cEl.qsAVbDrdlVIfZLclue4my5SIEp3fOLRrI1z18RJa2s3rq1Bv2');

-- 1.4 第二个买家（新手）
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, college, grade, dormitory, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (5, '2024004', '$2b$12$dgbVshqtVdtFdX3SGPjniepiQ29BtSsOrX3BNLRTf1LCO4PcAJll.',
        '新生小张', '13800001004', (SELECT id FROM school WHERE code = 'DHU'), '纺织学院', '2025', NULL,
        'USER', 'ACTIVE', 2, 80, 50.00,
        '你的小学校名？', '$2b$12$eloHX5HjQIhkGFmt9oVqIOnebOP/EofgG0rIUkXvCpWd49zedaTuW');

-- 1.5 临时封禁用户（封禁至未来30天）
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, college, grade, dormitory, role, status, level, exp, wallet_balance, ban_until_time, token_version, security_question, security_answer)
VALUES (6, '2024005', '$2b$12$ukr9WdiA1eGLLrrfw/5LueF6U5FRVV9w.WKVCSKm4i4U0FLbyQ/tu',
        '违规用户A', '13800001005', (SELECT id FROM school WHERE code = 'SHU'), NULL, NULL, NULL,
        'USER', 'BANNED_TEMP', 2, 30, 25.00,
        DATE_ADD(NOW(), INTERVAL 30 DAY), 1,
        '你的小学校名？', '$2b$12$3TSUF7kG4YxLiaT5PpgILunGzvvM0ynSexQrkjQLyBdsY0HHkU.o2');

-- 1.6 永久封禁用户
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, college, grade, dormitory, role, status, level, exp, wallet_balance, token_version, security_question, security_answer)
VALUES (7, '2024006', '$2b$12$6t56hYPtAWVq/DpaXfLQyOnhRvw2zO4kLa6EFbjRBmp3bSWCJtP0e',
        '永久封禁B', '13800001006', (SELECT id FROM school WHERE code = 'SHU'), NULL, NULL, NULL,
        'USER', 'BANNED_PERM', 1, 0, 0.00,
        10,
        '你的小学校名？', '$2b$12$MJWYB9Ydvp/9C0sUsZzts.Go.aUGSNOWXCQXhcLgQDKiGHZPlaD0S');

-- 1.7 已注销用户
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, college, grade, dormitory, role, status, level, exp, wallet_balance, token_version, security_question, security_answer)
VALUES (8, '2024007', '$2b$12$bboUbpYgckEPU065Qg2fk.E5DEfzjolD330rMr1PF/8./MSTG7Wma',
        '已注销用户C', '13800001007', (SELECT id FROM school WHERE code = 'SHU'), NULL, NULL, NULL,
        'USER', 'CANCELLED', 1, 50, 10.00,
        5,
        '你的小学校名？', '$2b$12$6UDfTkFud8jJ/EM/cXo0hOb2F57lY6IUCieMaNlTXev0DDEAutmdO');

-- 1.8 边缘用户（零余额、零经验、最低等级）
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, college, grade, dormitory, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (9, '2024008', '$2b$12$kaJOHij6IleUCnjW0nMafOW9GFYFs.gZqQRB.292MqGoEfEGJa3yu',
        '边缘用户零钱', '13800001008', (SELECT id FROM school WHERE code = 'SHU'), NULL, NULL, NULL,
        'USER', 'ACTIVE', 1, 0, 0.00,
        '你的小学校名？', '$2b$12$.88gJYi3Fl/vjfrT3FTGheCPKt2lgB8jSkl1uZCwfIHOc0x0d/xfu');

-- 1.9 高等级用户（接近满级）
INSERT INTO sys_user (id, student_id, password, nickname, phone, school_id, college, grade, dormitory, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES (10, '2024009', '$2b$12$A8aOzHUTbQIAkMBS/i/DmeVWMlohu04oMHUoJqh3hBbWeV7FiC5oK',
        '大佬陈哥', '13800001009', (SELECT id FROM school WHERE code = 'DHU'), '材料学院', '2024', '松江校区1号楼',
        'USER', 'ACTIVE', 15, 12000, 5000.00,
        '你的小学校名？', '$2b$12$7L09/Ss3rmzNetH6I1rqDu7vE3WEh3AFU/gYREgK18YHTuFC/CoAu');

SELECT '✅ 1. 用户数据插入完成' AS '';


-- ============================================================
-- 2. 商品表 item（模块 B 边缘数据）
-- 分类：1=数码电子 2=教材书籍 3=服饰鞋包 4=生活日用
--       5=运动娱乐 6=零食饮品 7=学习用品 8=其他
-- ============================================================

-- === 2.1 正常在售商品（SELL）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (1, 2, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        '99新 iPad Air5 256G 考研结束出',
        '去年九月购入，主要用于看网课和笔记，全程戴壳贴膜无划痕。配件齐全含原装充电器和包装盒。考研上岸故出。',
        1, 3200.00,
        '["/uploads/items/20260701/ipad1.png","/uploads/items/20260701/ipad2.png","/uploads/items/20260701/ipad3.png"]',
        '["iPad","苹果","考研","99新","平板"]',
        true, '图书馆门口', 'ON_SALE', 128, false);

-- === 2.2 求购商品（BUY）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (2, 3, (SELECT id FROM school WHERE code = 'SHU'), 'BUY',
        '求购二手高数上册同济版',
        '大一新生，想收一本有笔记的高数上册，价格可议，诚心收。',
        2, 15.00,
        '["/uploads/items/20260702/buy_book.png"]',
        '["高数","教材","求购","同济"]',
        true, '一食堂', 'ON_SALE', 45, false);

-- === 2.3 最多图片（9张）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (3, 4, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        '索尼WH-1000XM5 头戴降噪耳机 箱说全',
        '年会抽奖中的，仅拆封试戴过一次，几乎全新。包装配件齐全，发票也在。',
        1, 1800.00,
        '["/uploads/items/20260703/p1.png","/uploads/items/20260703/p2.png","/uploads/items/20260703/p3.png","/uploads/items/20260703/p4.png","/uploads/items/20260703/p5.png","/uploads/items/20260703/p6.png","/uploads/items/20260703/p7.png","/uploads/items/20260703/p8.png","/uploads/items/20260703/p9.png"]',
        '["耳机","索尼","降噪","全新"]',
        true, '南门快递站', 'ON_SALE', 56, false);

-- === 2.4 单张图片（边界：最少1张）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (4, 2, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        '台灯',
        '普通LED台灯一个触控调光宿舍用很合适需要的来看看',
        4, 25.00,
        '["/uploads/items/20260704/lamp.png"]',
        '["台灯","LED","宿舍"]',
        true, '体育馆', 'ON_SALE', 12, false);

-- === 2.5 最低价格 0.01 ===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (5, 4, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        '一元夺宝小贴纸',
        '一些闲置的贴纸免费送也行需要的同学来拿就好不包邮当面交易',
        8, 0.01,
        '["/uploads/items/20260705/sticker.png"]',
        '["贴纸","免费","闲置"]',
        true, '体育馆', 'ON_SALE', 200, false);

-- === 2.6 高价格 99999999.99 ===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (6, 10, (SELECT id FROM school WHERE code = 'DHU'), 'SELL',
        '限量版顶配Mac Pro全套',
        '顶配Mac Pro 全套工作站出售带显示器键鼠打包价格可小刀',
        1, 99999999.99,
        '["/uploads/items/20260706/macpro.png"]',
        '["Mac","顶配","工作站"]',
        true, '图书馆门口', 'ON_SALE', 999, false);

-- === 2.7 最短标题（2字）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (7, 2, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        '水杯',
        '一个闲置的星巴克联名保温杯用过几次成色不错保温效果很好',
        4, 35.00,
        '["/uploads/items/20260707/cup.png"]',
        '["水杯","保温杯","星巴克"]',
        true, '一食堂', 'ON_SALE', 88, false);

-- === 2.8 最长标题（50字）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (8, 4, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        '全新未拆封苹果AirPods Pro第二代USB-C接口主动降噪蓝牙耳机白色',
        '朋友送的生日礼物但我已经有一副了所以全新未拆封转卖',
        1, 1500.00,
        '["/uploads/items/20260708/airpods.png"]',
        '["AirPods","苹果","耳机","全新","降噪"]',
        true, '图书馆门口', 'ON_SALE', 66, false);

-- === 2.9 最短描述（10字）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (9, 2, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        '羽毛球拍一对',
        '闲置羽毛球拍一对便宜出。',
        5, 50.00,
        '["/uploads/items/20260709/badminton.png"]',
        '["羽毛球","运动"]',
        true, '体育馆', 'ON_SALE', 33, false);

-- === 2.10 最长描述（500字）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (10, 10, (SELECT id FROM school WHERE code = 'DHU'), 'SELL',
        'ThinkPad X1 Carbon Gen9 商务本',
        '这是一台陪伴我度过了三年研究生生涯的笔记本电脑它见证了我从一个小白成长为一个能够独立完成项目的程序员的全部过程这台电脑陪伴我熬过了无数个深夜陪伴我完成了毕设陪伴我找到了第一份工作现在我已经换了新的设备希望它能继续陪伴下一位有缘人继续它的使命机器的配置是i7处理器16G内存512G固态硬盘屏幕是14寸的2K分辨率杜比视界屏幕显示效果非常出色键盘手感是ThinkPad一贯的高水准打字非常舒服重量只有不到一公斤非常轻薄便携适合每天背着去图书馆或者教室电池还能用大约四到五个小时满足一天的学习需求没有问题外观有一些轻微的使用痕迹比如角落有一点掉漆但是不影响使用整体成色九成新配件齐全带原装充电器还送一个联想原装的笔记本包。',
        1, 4500.00,
        '["/uploads/items/20260710/thinkpad1.png","/uploads/items/20260710/thinkpad2.png"]',
        '["ThinkPad","笔记本","轻薄","i7","商务"]',
        true, '图书馆门口', 'ON_SALE', 77, false);

-- === 2.11 交易中商品（PENDING）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (11, 2, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        '机械键盘Cherry红轴',
        'Cherry红轴机械键盘，用了半年，成色新，送拔键器。',
        1, 200.00,
        '["/uploads/items/20260711/keyboard.png"]',
        '["键盘","机械","Cherry","红轴"]',
        true, '图书馆门口', 'PENDING', 156, false);

-- === 2.12 已售出商品（SOLD）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (12, 2, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        '罗技G502无线鼠标',
        '已售出——罗技G502 Lightspeed，95新，箱说全。',
        1, 350.00,
        '["/uploads/items/20260712/mouse.png"]',
        '["鼠标","罗技","无线","游戏"]',
        true, '南门快递站', 'SOLD', 320, false);

-- === 2.13 用户主动下架（OFF_SHELF）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (13, 4, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        '不想卖了交换机',
        '本来想卖的路由器但现在决定继续用所以下架。',
        1, 80.00,
        '["/uploads/items/20260713/router.png"]',
        '["路由器","网络"]',
        true, '体育馆', 'OFF_SHELF', 22, false);

-- === 2.14 AI违规拦截后下架（OFF_SHELF + violation_report关联）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (14, 2, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        '测试违规商品标题',
        '这是一个被AI拦截的测试违规商品描述内容包含违规信息被系统自动下架等待管理员审核。',
        8, 99.00,
        '["/uploads/items/20260714/test.png"]',
        '["测试"]',
        true, '一食堂', 'OFF_SHELF', 5, false);

-- === 2.15 AI审核异常降级（ai_reviewed=false 但仍 ON_SALE）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (15, 5, (SELECT id FROM school WHERE code = 'DHU'), 'SELL',
        '华为Mate60 Pro手机壳',
        '买错型号了，全新未使用，适合Mate60 Pro的透明防摔手机壳。',
        1, 15.00,
        '["/uploads/items/20260715/case.png"]',
        '["手机壳","华为","配件"]',
        false, '南门快递站', 'ON_SALE', 11, false);

-- === 2.16 求购下架商品 ===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (16, 3, (SELECT id FROM school WHERE code = 'SHU'), 'BUY',
        '求购二手篮球一个',
        '想收一个二手篮球，室外用的就行，成色无所谓只要还能打。',
        5, 25.00,
        '["/uploads/items/20260716/ball.png"]',
        '["篮球","体育","求购"]',
        true, '体育馆', 'OFF_SHELF', 8, false);

-- === 2.17 满标签（6个AI标签）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (17, 10, (SELECT id FROM school WHERE code = 'DHU'), 'SELL',
        'Switch OLED + 塞尔达 + 健身环大全套',
        'Switch OLED白色款，带王国之泪卡带和健身环大冒险，送收纳包和钢化膜。买来玩了两个月通关就吃灰了。',
        5, 2200.00,
        '["/uploads/items/20260717/switch1.png","/uploads/items/20260717/switch2.png"]',
        '["Switch","塞尔达","健身环","游戏","OLED","大全套"]',
        true, '图书馆门口', 'ON_SALE', 189, false);

-- === 2.18 软删除商品（is_deleted=1）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (18, 2, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        '已删除的商品测试',
        '这个商品已被用户删除，不应该出现在任何大厅列表或搜索结果中。',
        8, 1.00,
        '["/uploads/items/20260718/deleted.png"]',
        '["已删除","测试"]',
        true, '一食堂', 'OFF_SHELF', 3, true);

-- === 2.19 空ai_tags ===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (19, 5, (SELECT id FROM school WHERE code = 'DHU'), 'SELL',
        '全新未拆封小米充电宝',
        '年会发的全新小米充电宝20000mAh未拆封',
        1, 80.00,
        '["/uploads/items/20260719/charger.png"]',
        '["小米","充电宝","全新"]',
        true, '南门快递站', 'ON_SALE', 44, false);

-- === 2.20 带特殊字符的标题（Emoji + 标点）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (20, 4, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        '🎮 PS5 光驱版 + 双手柄',
        '港版PS5光驱版，带两个原装手柄和底座，箱说全。玩了一年，成色好无暗病。',
        5, 3000.00,
        '["/uploads/items/20260720/ps5.png"]',
        '["PS5","游戏机","索尼","手柄"]',
        true, '体育馆', 'ON_SALE', 234, false);

-- === 2.21 异常低价的数码产品（测试AI价格检测）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (21, 2, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        'iPhone 15 Pro Max',
        '全新未拆封。',
        1, 1.00,
        '["/uploads/items/20260721/iphone.png"]',
        '["iPhone","苹果","手机"]',
        true, '图书馆门口', 'OFF_SHELF', 10, false);

-- === 2.22 正常价格的配件（AI价格检测不应误判）===
INSERT INTO item (id, publisher_id, school_id, type, title, description, category_id, price, images, ai_tags, ai_reviewed, trade_location, status, view_count, is_deleted)
VALUES (22, 4, (SELECT id FROM school WHERE code = 'SHU'), 'SELL',
        'iPad Air5保护壳和钢化膜',
        '换新iPad了，旧的保护壳和钢化膜免费送。保护壳是透明防摔的，钢化膜全新未贴。',
        1, 1.00,
        '["/uploads/items/20260722/ipadcase.png"]',
        '["iPad","保护壳","贴膜","配件"]',
        true, '南门快递站', 'ON_SALE', 67, false);

SELECT '✅ 2. 商品数据插入完成' AS '';


-- ============================================================
-- 3. 交易订单 trade_order（模块 D 边缘数据）
-- ============================================================

-- 3.1 待线下见面（WAITING_MEET）—— 买家5买了卖家2的商品11
INSERT INTO trade_order (id, item_id, buyer_id, seller_id, price, status)
VALUES (1, 11, 5, 2, 200.00, 'WAITING_MEET');

-- 3.2 已完成（COMPLETED）—— 买家3买了卖家2的商品12
INSERT INTO trade_order (id, item_id, buyer_id, seller_id, price, status, completed_at)
VALUES (2, 12, 3, 2, 350.00, 'COMPLETED', DATE_SUB(NOW(), INTERVAL 2 DAY));

-- 3.3 已取消（CANCELLED）—— 买家5取消了对商品16的订单
INSERT INTO trade_order (id, item_id, buyer_id, seller_id, price, status, cancelled_at)
VALUES (3, 16, 5, 3, 25.00, 'CANCELLED', DATE_SUB(NOW(), INTERVAL 1 DAY));

-- 3.4 已完成（另一笔）—— 高等级用户买卖
INSERT INTO trade_order (id, item_id, buyer_id, seller_id, price, status, completed_at)
VALUES (4, 8, 5, 4, 1500.00, 'COMPLETED', DATE_SUB(NOW(), INTERVAL 5 DAY));

SELECT '✅ 3. 订单数据插入完成' AS '';


-- ============================================================
-- 4. 钱包流水 wallet_log（模块 D 边缘数据）
-- ============================================================

-- 4.1 充值记录
INSERT INTO wallet_log (id, user_id, type, amount, balance_after, remark)
VALUES (1, 3, 'RECHARGE', 2000.00, 2000.00, '新生充值');
INSERT INTO wallet_log (id, user_id, type, amount, balance_after, remark)
VALUES (2, 2, 'RECHARGE', 500.00, 500.00, '初始充值');
INSERT INTO wallet_log (id, user_id, type, amount, balance_after, remark)
VALUES (3, 9, 'RECHARGE', 0.01, 0.01, '最小充值金额测试');

-- 4.2 支付（冻结资金）
INSERT INTO wallet_log (id, user_id, type, amount, balance_after, order_id, remark)
VALUES (4, 5, 'PAYMENT', -200.00, 50.00, 1, '购买机械键盘');
INSERT INTO wallet_log (id, user_id, type, amount, balance_after, order_id, remark)
VALUES (5, 3, 'PAYMENT', -350.00, 1650.00, 2, '购买鼠标');

-- 4.3 卖家收入
INSERT INTO wallet_log (id, user_id, type, amount, balance_after, order_id, remark)
VALUES (6, 2, 'INCOME', 350.00, 500.00, 2, '售出鼠标');
INSERT INTO wallet_log (id, user_id, type, amount, balance_after, order_id, remark)
VALUES (7, 4, 'INCOME', 1500.00, 100.50, 4, '售出AirPods');

-- 4.4 退款
INSERT INTO wallet_log (id, user_id, type, amount, balance_after, order_id, remark)
VALUES (8, 5, 'REFUND', 25.00, 75.00, 3, '订单取消退款');

-- 4.5 边缘：退款后余额刚好为0
INSERT INTO wallet_log (id, user_id, type, amount, balance_after, remark)
VALUES (9, 9, 'PAYMENT', -0.01, 0.00, '测试清零');

SELECT '✅ 4. 钱包流水插入完成' AS '';


-- ============================================================
-- 5. 违规记录 violation_report（模块 B→D 边缘数据）
-- ============================================================

-- 5.1 PENDING（AI内容违规拦截，待管理员审核）—— 关联item 14
INSERT INTO violation_report (id, user_id, item_id, original_title, original_description,
    violation_type, violation_reason, ai_tags, status, ai_review_error)
VALUES (1, 2, 14,
        '测试违规商品标题',
        '这是一个被AI拦截的测试违规商品描述内容包含违规信息被系统自动下架等待管理员审核。',
        'CONTENT_VIOLATION', '内容包含平台禁止发布的信息：代写',
        '["测试","违规"]', 'PENDING', false);

-- 5.2 PENDING（AI审核异常，待人工复核）—— 关联item 15
INSERT INTO violation_report (id, user_id, item_id, original_title, original_description,
    violation_type, violation_reason, ai_tags, status, ai_review_error)
VALUES (2, 5, 15,
        '华为Mate60 Pro手机壳',
        '买错型号了，全新未使用，适合Mate60 Pro的透明防摔手机壳。',
        'AI_REVIEW_ERROR', 'AI 审核服务暂不可用，已转人工复核',
        '["手机壳","华为"]', 'PENDING', true);

-- 5.3 PENDING（价格异常检测拦截）—— 关联item 21
INSERT INTO violation_report (id, user_id, item_id, original_title, original_description,
    violation_type, violation_reason, ai_tags, status, ai_review_error)
VALUES (3, 2, 21,
        'iPhone 15 Pro Max',
        '全新未拆封。',
        'CONTENT_VIOLATION', '商品价格 ¥1.00 与标题、型号或成色明显不符，疑似虚假价格或交易欺诈',
        '["iPhone","苹果"]', 'PENDING', false);

-- 5.4 CONFIRMED（管理员确认违规，已处罚）
INSERT INTO violation_report (id, user_id, item_id, original_title, original_description,
    violation_type, violation_reason, ai_tags, status, handler_id, handle_note, handled_at, ai_review_error)
VALUES (4, 2, NULL,
        '代写期末论文',
        '专业代写各科期末论文，保证通过。',
        'CONTENT_VIOLATION', '涉及代考代写学术不端服务',
        '["代写","论文"]', 'CONFIRMED', 1, '确认违规，已封禁用户', DATE_SUB(NOW(), INTERVAL 3 DAY), false);

-- 5.5 DISMISSED（管理员误判放行）
INSERT INTO violation_report (id, user_id, item_id, original_title, original_description,
    violation_type, violation_reason, ai_tags, status, handler_id, handle_note, handled_at, ai_review_error)
VALUES (5, 3, NULL,
        '二手教材转让',
        '转让大学英语四级教材和辅导书。',
        'CONTENT_VIOLATION', '疑似广告引流',
        '["教材","四级"]', 'DISMISSED', 1, '误判，正常教材转让', DATE_SUB(NOW(), INTERVAL 2 DAY), false);

-- 5.6 无关联商品的违规记录（item_id=NULL）
INSERT INTO violation_report (id, user_id, item_id, original_title, original_description,
    violation_type, violation_reason, ai_tags, status, ai_review_error)
VALUES (6, 7, NULL,
        '测试无商品关联的违规记录',
        '这个违规记录没有关联任何商品，测试 item_id 为 NULL 的边界情况。',
        'CONTENT_VIOLATION', '边缘测试：无关联商品',
        '["测试"]', 'PENDING', false);

SELECT '✅ 5. 违规记录插入完成' AS '';


-- ============================================================
-- 6. 处罚日志 violation_log（模块 A/D 边缘数据）
-- ============================================================

-- 6.1 警告
INSERT INTO violation_log (id, user_id, admin_id, type, reason, ban_days)
VALUES (1, 6, 1, 'WARNING', '首次违规发布，给予警告。', NULL);

-- 6.2 限时封禁
INSERT INTO violation_log (id, user_id, admin_id, type, reason, ban_days)
VALUES (2, 6, 1, 'BAN_TEMP', '再次违规，限时封禁30天。', 30);

-- 6.3 永久封禁
INSERT INTO violation_log (id, user_id, admin_id, type, reason, ban_days)
VALUES (3, 7, 1, 'BAN_PERM', '多次严重违规，永久封禁。', NULL);

-- 6.4 确认违规后的处罚（关联violation_report id=4）
INSERT INTO violation_log (id, user_id, admin_id, type, reason, ban_days)
VALUES (4, 2, 1, 'WARNING', '发布代写论文信息，给予警告。', NULL);

SELECT '✅ 6. 处罚日志插入完成' AS '';


-- ============================================================
-- 7. 经验流水 exp_log（模块 A 边缘数据）
-- ============================================================

-- 7.1 完成订单加经验
INSERT INTO exp_log (id, user_id, delta, exp_after, level_after, reason)
VALUES (1, 2, 50, 420, 5, '买家完成订单 (order #2)');
INSERT INTO exp_log (id, user_id, delta, exp_after, level_after, reason)
VALUES (2, 3, 50, 180, 3, '卖家完成订单 (order #2)');

-- 7.2 强制下架扣经验（最低钳制为0）
INSERT INTO exp_log (id, user_id, delta, exp_after, level_after, reason)
VALUES (3, 2, -30, 420, 5, '商品被管理员强制下架（扣30，等级只升不降）');

-- 7.3 边缘：扣到0（起始exp=30，扣30→0）
INSERT INTO exp_log (id, user_id, delta, exp_after, level_after, reason)
VALUES (4, 6, -30, 0, 2, '违规扣经验至零边界测试');

-- 7.4 边缘：扣超过当前exp（起始exp=50，扣100→0，不应变负）
INSERT INTO exp_log (id, user_id, delta, exp_after, level_after, reason)
VALUES (5, 8, -100, 0, 1, '扣经验超过当前值边界测试');

SELECT '✅ 7. 经验流水插入完成' AS '';


-- ============================================================
-- 7.5 交易评价 trade_review（模块 A/D 信誉体系 + D4 评价联动）
-- ============================================================

-- 7.5.1 正常评价：买家3评价卖家2（order#2，COMPLETED）
INSERT INTO trade_review (id, order_id, reviewer_id, target_id, rating, accurate, comment)
VALUES (1, 2, 3, 2, 5, 1, '卖家很靠谱，鼠标成色如描述，当面交易很愉快！');

-- 7.5.2 低分评价：买家5评价卖家4（order#4，COMPLETED）
INSERT INTO trade_review (id, order_id, reviewer_id, target_id, rating, accurate, comment)
VALUES (2, 4, 5, 4, 2, 0, '描述说几乎全新但耳机有划痕，不太满意。');

-- 7.5.3 边缘：最低评分（准确但非常不满意）
-- 需要一个额外的 COMPLETED 订单来承载这笔评价
INSERT INTO trade_order (id, item_id, buyer_id, seller_id, price, status, completed_at)
VALUES (5, 3, 5, 4, 1800.00, 'COMPLETED', DATE_SUB(NOW(), INTERVAL 10 DAY));
INSERT INTO trade_review (id, order_id, reviewer_id, target_id, rating, accurate, comment)
VALUES (3, 5, 5, 4, 1, 1, '描述准确但耳机有严重质量问题，不推荐。');

SELECT '✅ 7.5. 交易评价插入完成' AS '';


-- ============================================================
-- 8. 收藏 item_favorite（模块 C 边缘数据）
-- ============================================================

-- 8.1 正常收藏
INSERT INTO item_favorite (id, user_id, item_id) VALUES (1, 3, 1);
INSERT INTO item_favorite (id, user_id, item_id) VALUES (2, 3, 3);
INSERT INTO item_favorite (id, user_id, item_id) VALUES (3, 3, 17);
INSERT INTO item_favorite (id, user_id, item_id) VALUES (4, 5, 1);
INSERT INTO item_favorite (id, user_id, item_id) VALUES (5, 5, 3);
INSERT INTO item_favorite (id, user_id, item_id) VALUES (6, 10, 1);
INSERT INTO item_favorite (id, user_id, item_id) VALUES (7, 9, 17);

-- 8.2 收藏已删除商品（边缘：软删除商品仍有关联收藏）
INSERT INTO item_favorite (id, user_id, item_id) VALUES (8, 3, 18);

SELECT '✅ 8. 收藏数据插入完成' AS '';


-- ============================================================
-- 9. 聊天消息 chat_message（模块 C 边缘数据）
-- ============================================================

-- 9.1 买卖双方正常对话（conversation_id = "2_3"）
INSERT INTO chat_message (id, conversation_id, sender_id, receiver_id, content, related_item_id, is_read)
VALUES (1, '2_3', 3, 2, '你好，iPad还在吗？', 1, true);
INSERT INTO chat_message (id, conversation_id, sender_id, receiver_id, content, related_item_id, is_read)
VALUES (2, '2_3', 2, 3, '在的，成色很新。', 1, true);
INSERT INTO chat_message (id, conversation_id, sender_id, receiver_id, content, related_item_id, is_read)
VALUES (3, '2_3', 3, 2, '可以便宜点吗？', 1, false);

-- 9.2 客服对话（conversation_id = "3_admin"）
INSERT INTO chat_message (id, conversation_id, sender_id, receiver_id, content, is_read)
VALUES (4, '3_admin', 3, 1, '你好客服，我想问一下如何修改昵称？', true);
INSERT INTO chat_message (id, conversation_id, sender_id, receiver_id, content, is_read)
VALUES (5, '3_admin', 1, 3, '在个人中心页面可以修改昵称。', false);

-- 9.3 系统消息（升级通知）
INSERT INTO chat_message (id, conversation_id, sender_id, receiver_id, content, is_read)
VALUES (6, '2_admin', 1, 2, '🎉 恭喜！你的等级提升至 LV5！继续加油！', false);

-- 9.4 未读消息批量（边缘：同一会话多条未读）
INSERT INTO chat_message (id, conversation_id, sender_id, receiver_id, content, related_item_id, is_read)
VALUES (7, '4_5', 5, 4, '学姐你好，我对耳机感兴趣', 3, true);
INSERT INTO chat_message (id, conversation_id, sender_id, receiver_id, content, related_item_id, is_read)
VALUES (8, '4_5', 5, 4, '还在吗？', 3, false);
INSERT INTO chat_message (id, conversation_id, sender_id, receiver_id, content, related_item_id, is_read)
VALUES (9, '4_5', 5, 4, '可以面交吗？', 3, false);

-- 9.5 无关联商品的纯聊天
INSERT INTO chat_message (id, conversation_id, sender_id, receiver_id, content, is_read)
VALUES (10, '2_4', 2, 4, '你那个路由器出了吗？', true);

SELECT '✅ 9. 聊天消息插入完成' AS '';


-- ============================================================
-- ✅ 全部测试数据插入完成
-- ============================================================
SELECT '' AS '';
SELECT '🎉 全部测试数据插入完成！共覆盖以下边缘场景：' AS '';
SELECT '  👤 用户：正常/封禁(临时+永久)/注销/零余额/高等级' AS '';
SELECT '  📦 商品：SELL/BUY、各种状态、价格边界、标题/描述边界、图片1-9张、AI降级、school_id隔离' AS '';
SELECT '  📋 订单：WAITING_MEET/COMPLETED/CANCELLED' AS '';
SELECT '  ⭐ 交易评价：高/中/低分、描述准确/不符' AS '';
SELECT '  💰 钱包：RECHARGE/PAYMENT/REFUND/INCOME、最小充值' AS '';
SELECT '  🛡️ 违规：PENDING/CONFIRMED/DISMISSED、AI异常、内容违规、价格异常' AS '';
SELECT '  ⭐ 收藏：正常/软删除商品关联' AS '';
SELECT '  💬 聊天：买卖对话/客服/系统消息/未读批量' AS '';
SELECT '  📊 经验：加经验/扣经验/扣至零/扣超过当前值' AS '';
