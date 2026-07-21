# Model4 分支完整验证指南

> 涵盖模块四全部功能：钱包充值、担保交易、超管控制台、Bug 修复验证、自动化测试

---

## 〇、环境准备

### 0.1 启动服务

```powershell
# 后端（确保 MySQL 已启动）
cd D:\OneDrive\Desktop\summer\zhiyi-campus\backend
$env:JWT_SECRET = "zhiyi-campus-2026-secret-key-change-in-production"
$env:MYSQL_PASSWORD = "wangke3398"
mvn spring-boot:run

# 前端（新终端）
cd D:\OneDrive\Desktop\summer\zhiyi-campus\frontend
npm run dev
```

### 0.2 准备测试数据

```sql
-- 确保有测试用户（密码 BCrypt 哈希 = "123456"）
INSERT INTO sys_user (student_id, password, nickname, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES ('test_buyer', '$2a$10$8Jcbe5NyLSowgw.3zOB9bOgoKCpwTuoHWLDAv0robpXmRA10hBngS', '测试买家', 'USER', 'ACTIVE', 1, 50, 500.00, '1', '1');

INSERT INTO sys_user (student_id, password, nickname, role, status, level, exp, wallet_balance, security_question, security_answer)
VALUES ('test_seller', '$2a$10$8Jcbe5NyLSowgw.3zOB9bOgoKCpwTuoHWLDAv0robpXmRA10hBngS', '测试卖家', 'USER', 'ACTIVE', 1, 50, 0.00, '1', '1');

-- 记下 ID
SELECT id, student_id, nickname, wallet_balance FROM sys_user WHERE student_id IN ('test_buyer', 'test_seller');

-- 创建一个出售商品（发布者=卖家ID，假设为 3）
INSERT INTO item (publisher_id, type, title, description, category_id, price, images, status, ai_reviewed)
VALUES (3, 'SELL', '二手 iPad 第九代', '九成新，包装齐全，送保护壳', 1, 150.00, '[]', 'ON_SALE', 1);

-- 创建一个求购商品（发布者=买家ID，假设为 2）
INSERT INTO item (publisher_id, type, title, description, category_id, price, images, status, ai_reviewed)
VALUES (2, 'BUY', '求购二手 iPad', '预算 150 以内，要求九成新以上', 1, 150.00, '[]', 'ON_SALE', 1);

-- 记下商品 ID
SELECT id, title, type, status FROM item WHERE title LIKE '%iPad%';
```

---

## 一、钱包功能（4.1）

### 1.1 查看余额

| 步骤 | 操作 | 期望 |
|------|------|------|
| 1 | 用 test_buyer 登录 | 顶部导航栏显示"钱包" |
| 2 | 点击 钱包 → 进入钱包页 | 看到当前余额 ¥500.00 |

### 1.2 模拟充值

| 步骤 | 操作 | 期望 |
|------|------|------|
| 1 | 在钱包页输入金额 100 → 点击充值 | 提示充值成功，余额变为 ¥600.00 |
| 2 | 输入 0.01 → 充值 | 正常到账 |
| 3 | 输入 10001 → 充值 | 提示"单次充值不能超过 10000 元" |
| 4 | 输入 -50 → 充值 | 前端拦截或后端报错 |
| 5 | 不输入金额 → 充值 | 提示"充值金额不能为空" |

### 1.3 资金流水

| 步骤 | 操作 | 期望 |
|------|------|------|
| 1 | 在钱包页查看流水列表 | 显示刚才的 RECHARGE 记录，含金额、余额、时间 |
| 2 | 类型显示 | 充值为"充值"，支付为"支付"，退款为"退款"，收入为"收入" |

### 1.4 SQL 验证

```sql
-- 余额应为充值后的值
SELECT id, nickname, wallet_balance FROM sys_user WHERE student_id = 'test_buyer';

-- 应有充值流水
SELECT * FROM wallet_log WHERE user_id = (SELECT id FROM sys_user WHERE student_id = 'test_buyer') ORDER BY created_at DESC LIMIT 5;
```

---

## 二、担保交易（4.2 - 4.3）

### 2.1 SELL 商品正常购买流程

| 步骤 | 操作 | 期望 |
|------|------|------|
| 1 | test_buyer 登录 → 首页大厅 | 看到"二手 iPad 第九代"商品卡片 |
| 2 | 点击商品卡片 → 进入详情页 | 图片区显示"出售"徽章（橙色） |
| 3 | 底部按钮 | 显示 [收藏] [联系卖家] **[立即购买]** |
| 4 | 点击"立即购买" → 确认弹窗 | 显示金额 ¥150.00，提示"资金将由平台担保冻结" |
| 5 | 确认下单 | 提示"下单成功！资金已冻结" |
| 6 | 返回大厅 → 商品状态 | 显示"交易中"徽章 |
| 7 | 钱包 → 我买到的 | 订单列表有一条 WAITING_MEET 订单 |
| 8 | 点击"确认收货" → 弹窗确认 | 提示"收货确认成功" |
| 9 | 钱包 → 退款后余额 | 应扣掉 150 |
| 10 | test_seller 登录 → 我卖出的 | 订单 COMPLETED，余额 +150 |

### 2.2 BUY 类型 Bug 修复验证 🐛

| 步骤 | 操作 | 期望 |
|------|------|------|
| 1 | test_buyer 登录 → 大厅搜索"求购" | 找到"求购二手 iPad"商品 |
| 2 | 进入详情页 | 图片区显示"求购"徽章（蓝色） |
| 3 | 底部按钮 | 只显示 [收藏] **[我要出售]**，**没有"立即购买"按钮** |
| 4 | 底部文案 | 显示"点击'我要出售'与发布者联系，双方沟通后确认交易细节" |
| 5 | 点击"我要出售" | 跳转聊天页，与发布者对话 |

### 2.3 取消订单 + 退款

| 步骤 | 操作 | 期望 |
|------|------|------|
| 1 | test_buyer 重新下单一个商品 | 订单状态 WAITING_MEET |
| 2 | 进入"我买到的" → 点击"取消订单" | 订单状态变为 CANCELLED |
| 3 | 检查余额 | 已退款，余额恢复 |
| 4 | 检查商品状态 | 商品恢复 ON_SALE |

### 2.4 边界情况

| 场景 | 操作 | 期望 |
|------|------|------|
| 购买自己的商品 | 用发布者账号点击购买 | 提示"不能购买自己发布的商品" |
| 余额不足 | 充值几乎用完再购买 | 提示"余额不足" |
| 商品已下架 | 下架商品后再尝试购买 | 按钮禁用，无法操作 |
| 确认非本人订单 | 用其他账号 API 确认 | 返回 FORBIDDEN 错误 |

### 2.5 SQL 验证

```sql
-- 订单状态流转
SELECT id, item_id, buyer_id, seller_id, price, status, created_at, completed_at
FROM trade_order ORDER BY id DESC LIMIT 5;

-- 钱包流水应有完整的收入/支出/退款记录
SELECT wl.*, u.nickname 
FROM wallet_log wl JOIN sys_user u ON wl.user_id = u.id 
ORDER BY wl.created_at DESC LIMIT 20;

-- 经验值变动
SELECT * FROM exp_log ORDER BY created_at DESC LIMIT 10;
```

---

## 三、超管控制台 - 数据大盘（4.4）

| 步骤 | 操作 | 期望 |
|------|------|------|
| 1 | admin 登录 → 管理后台 → 📊 数据大盘 | 四个统计卡片显示数据 |
| 2 | 查看统计卡片 | 总用户数 > 0、在售商品数 > 0、今日交易额、待处理违规数 |
| 3 | 查看趋势图 | SVG 折线图显示近 7 天交易金额 |
| 4 | 查看待处理违规 | 底部列表显示最近 5 条 PENDING 违规 |

---

## 四、超管控制台 - 违规审核（4.5）

### 4.1 审核流程

| 步骤 | 操作 | 期望 |
|------|------|------|
| 1 | admin → ⚖️ 违规审核 | 默认显示"待处理"标签，有数据则显示列表 |
| 2 | 查看违规卡片 | 显示违规类型徽章、原标题、AI 判定原因、**商品 #ID（状态）** |
| 3 | 点击"确认违规" | 弹出处罚弹窗：选择处罚类型 → 填写原因 → 确认 |
| 4 | 选择"限时封禁" | 封禁天数输入框出现 |
| 5 | 确认处罚 | 提示"处罚已生效"，列表刷新，该记录状态变为"已确认" |
| 6 | 对另一个 PENDING 记录点"误判放行" | 弹窗确认，商品恢复 ON_SALE |

### 4.2 商品 ID 直接下架 🆕

| 步骤 | 操作 | 期望 |
|------|------|------|
| 1 | 在违规卡片 meta 行 | 显示"商品：**#XX**（在售）" |
| 2 | 如果商品仍在售 | 卡片底部出现 [📦 强制下架商品 #XX] 按钮 |
| 3 | 点击强制下架按钮 → 确认 | 提示"商品已强制下架"，商品状态刷新为 OFF_SHELF |
| 4 | 如果商品已下架 | 该按钮自动消失 |

### 4.3 SQL 验证

```sql
-- 确认违规后处罚日志
SELECT vl.*, u.nickname AS punished, a.nickname AS admin_name
FROM violation_log vl
JOIN sys_user u ON vl.user_id = u.id
JOIN sys_user a ON vl.admin_id = a.id
ORDER BY vl.created_at DESC LIMIT 5;

-- 违规记录状态
SELECT id, user_id, original_title, status, handler_id, item_id FROM violation_report ORDER BY created_at DESC LIMIT 10;
```

---

## 五、超管控制台 - 客服收件箱（4.6）

### 5.1 客服聊天

```sql
-- 准备数据：模拟 test_buyer 给客服发消息
SET @uid = (SELECT id FROM sys_user WHERE student_id = 'test_buyer');
SET @admin_id = (SELECT id FROM sys_user WHERE student_id = 'admin');
SET @cid = CONCAT(LEAST(@uid, @admin_id), '_', GREATEST(@uid, @admin_id));
INSERT INTO chat_message (conversation_id, sender_id, receiver_id, content, is_read, created_at)
VALUES (@cid, @uid, @admin_id, '你好，我有个交易问题想问', 0, NOW());
```

| 步骤 | 操作 | 期望 |
|------|------|------|
| 1 | admin → 💬 客服收件箱 | 左侧会话列表出现 test_buyer |
| 2 | 查看未读标记 | test_buyer 会话显示红色未读数字 |
| 3 | 点击会话 | 右侧加载历史消息 |
| 4 | 输入回复 → 回车发送 | 消息发送成功，显示在右侧 |
| 5 | 点击刷新 | 会话列表更新 |
| 6 | 未读标记消失 🐛 | 打开会话后未读计数归零（验证 Bug #14 已修） |

---

## 六、超管控制台 - 内容管理（4.7）

### 6.1 强制下架商品 — 搜索模式 🆕

| 步骤 | 操作 | 期望 |
|------|------|------|
| 1 | admin → 🔧 内容管理 | "强制下架商品"卡片显示搜索框 + 状态筛选下拉 |
| 2 | 输入"iPad" → 搜索 | 列表显示匹配商品，每行：**#ID** / 标题 / 发布者 / 价格 / 状态徽章 |
| 3 | 输入纯数字 ID → 搜索 | 按 ID 精确匹配 或 标题模糊匹配 |
| 4 | 选择状态筛选"在售" → 搜索 | 只显示在售商品 |
| 5 | 点击某行商品 | 行高亮，预览卡片展开（标题、状态、价格、发布者） |
| 6 | 点击"确认下架" → 弹窗确认 | 提示"商品已强制下架，卖家已扣除 30 经验值" |
| 7 | 再次搜索同一商品 | 状态变为"已下架" |

### 6.2 强制重置密码

| 步骤 | 操作 | 期望 |
|------|------|------|
| 1 | 输入"test" → 搜索用户 | 列表显示 test_buyer 和 test_seller |
| 2 | 点击 test_buyer → 预览出现 | 点击"确认重置密码" → 确认 |
| 3 | 退出登录 → test_buyer + 密码 `123456` 登录 | 登录成功 |
| 4 | 不能重置管理员 | 选择 admin 用户后按钮禁用 |

### 6.3 SQL 验证

```sql
-- 强制下架后：商品状态、卖家经验、处罚日志
SELECT id, title, status FROM item WHERE title LIKE '%iPad%';

SELECT u.id, u.nickname, u.exp, el.delta, el.reason
FROM exp_log el JOIN sys_user u ON el.user_id = u.id
ORDER BY el.created_at DESC LIMIT 5;

SELECT * FROM violation_log ORDER BY created_at DESC LIMIT 3;
```

---

## 七、自动化测试

### 7.1 前端测试（npm test）

```powershell
cd D:\OneDrive\Desktop\summer\zhiyi-campus\frontend
npm test
```

期望输出：**17 tests, 0 fail**

涵盖：
- `my-items-query.test.js`：分页参数构建（2 个用例）
- `trade-utils.test.js`：状态映射、金额格式化、经验进度、订单参数（15 个用例）

### 7.2 后端测试（Maven）

```powershell
cd D:\OneDrive\Desktop\summer\zhiyi-campus\backend
mvn test -Dtest="com.zhiyi.module.trade.service.*,com.zhiyi.module.admin.service.*"
```

期望输出：**BUILD SUCCESS**，所有测试通过

涵盖（29 个用例）：
- `OrderServiceTest`：15 个用例
  - 下单：成功、BUY 拒绝、自己商品、已下架、存量冲突、余额不足、扣款失败
  - 确认收货：成功、非买家拒绝、已完成拒绝（并发）
  - 取消：成功、非买家拒绝、已取消拒绝（并发）
- `WalletServiceTest`：7 个用例
  - 查询：正常、用户不存在、零余额
  - 充值：成功、null 用户、null 金额、失败、最小/最大金额
- `AdminServiceTest`：7 个用例
  - 强制下架：成功、不存在、已下架、处罚日志校验
  - 重置密码：拒绝管理员、成功
  - 违规列表：空列表、VO 字段填充

---

## 八、快速冒烟测试（3 分钟）

```sql
-- 一键准备数据
SET @uid = (SELECT COALESCE((SELECT id FROM sys_user WHERE student_id = 'test_buyer'), 0));
SET @aid = (SELECT id FROM sys_user WHERE student_id = 'admin');

-- 创建测试商品
INSERT INTO item (publisher_id, type, title, description, category_id, price, images, status, ai_reviewed)
SELECT @uid + 1, 'SELL', CONCAT('冒烟商品-', FLOOR(RAND() * 9999)), '冒烟测试', 1, 50.00, '[]', 'ON_SALE', 1
WHERE NOT EXISTS (SELECT 1 FROM item WHERE title LIKE '冒烟商品%' AND status = 'ON_SALE' LIMIT 1);

-- 创建求购商品
INSERT INTO item (publisher_id, type, title, description, category_id, price, images, status, ai_reviewed)
SELECT @uid, 'BUY', CONCAT('冒烟求购-', FLOOR(RAND() * 9999)), '冒烟测试', 1, 30.00, '[]', 'ON_SALE', 1
LIMIT 1;
```

然后依次：
1. ✅ `npm test` — 17 pass
2. ✅ `mvn test` — BUILD SUCCESS
3. ✅ 钱包充值 → 余额增加
4. ✅ 购买商品 → 下单成功，资金冻结
5. ✅ 确认收货 → 卖家收款，双方 +50 经验
6. ✅ 求购商品详情页 → **无"立即购买"按钮**，只有"我要出售"
7. ✅ 客服收件箱 → 会话列表、未读标记、回复消息、**未读归零**
8. ✅ 违规审核 → 商品 ID 显示、强制下架按钮
9. ✅ 内容管理 → 搜索商品 → 选中 → 下架
10. ✅ 内容管理 → 搜索用户 → 重置密码

全部通过即 Model4 分支功能完整 ✅
