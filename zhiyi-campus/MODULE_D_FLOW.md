# 🔧 模块四：虚拟钱包与超管控制台 —— 系统流程图

> **负责人：D** | **分支：`feature/wallet-admin`** | **后端：`module/trade/` + `module/admin/`** | **前端：`views/wallet/` + `views/admin/`**

---

## 一、模块整体架构

```mermaid
graph TB
    subgraph 普通用户端
        WALLET[💰 我的钱包<br/>WalletPage.vue]
        ORDERS_B[📦 我买的<br/>OrdersBoughtPage.vue]
        ORDERS_S[📤 我卖的<br/>OrdersSoldPage.vue]
    end

    subgraph 管理员端
        DASH[📊 数据大盘<br/>DashboardPage.vue]
        VIOLATION[🛡️ 违规审核<br/>ViolationsPage.vue]
        CHAT_ADMIN[💬 客服收件箱<br/>ChatPage.vue]
    end

    subgraph 后端模块
        TRADE[module/trade<br/>钱包 · 充值 · 担保交易]
        ADMIN_MOD[module/admin<br/>大盘 · 风控 · 客服 · 强制管理]
    end

    subgraph 数据库
        SYS_USER[(sys_user<br/>用户/余额/经验)]
        TRADE_ORDER[(trade_order<br/>订单)]
        WALLET_LOG[(wallet_log<br/>资金流水)]
        VIOLATION_RPT[(violation_report<br/>违规记录)]
        VIOLATION_LOG[(violation_log<br/>处罚日志)]
        CHAT_MSG[(chat_message<br/>聊天消息)]
        ITEM[(item<br/>商品)]
    end

    WALLET --> TRADE
    ORDERS_B --> TRADE
    ORDERS_S --> TRADE
    DASH --> ADMIN_MOD
    VIOLATION --> ADMIN_MOD
    CHAT_ADMIN --> ADMIN_MOD

    TRADE --> SYS_USER
    TRADE --> TRADE_ORDER
    TRADE --> WALLET_LOG
    TRADE --> ITEM

    ADMIN_MOD --> SYS_USER
    ADMIN_MOD --> VIOLATION_RPT
    ADMIN_MOD --> VIOLATION_LOG
    ADMIN_MOD --> CHAT_MSG
    ADMIN_MOD --> ITEM

    style TRADE fill:#409EFF,color:#fff
    style ADMIN_MOD fill:#E6A23C,color:#fff
```

> 模块四横跨两条主线：**普通用户的钱包与交易**（`module/trade`）+ **管理员的后台控制台**（`module/admin`）。

---

## 二、虚拟钱包充值流程

```mermaid
sequenceDiagram
    actor U as 👤 普通用户
    participant FE as WalletPage.vue
    participant API as WalletController
    participant DB as 数据库

    U->>FE: 进入"我的钱包"页面
    FE->>API: GET /api/wallet/balance
    API->>DB: SELECT wallet_balance FROM sys_user
    DB-->>API: 520.50
    API-->>FE: { balance: 520.50 }
    FE-->>U: 💰 当前余额：¥520.50

    U->>FE: 输入充值金额（如 200）
    FE->>FE: 前端校验：1 ≤ 金额 ≤ 10000
    FE->>API: POST /api/wallet/recharge { amount: 200 }
    API->>DB: BEGIN TRANSACTION
    API->>DB: UPDATE sys_user SET wallet_balance = wallet_balance + 200
    API->>DB: INSERT INTO wallet_log (type='RECHARGE', amount=200, balance_after=720.50)
    API->>DB: COMMIT
    API-->>FE: { balance: 720.50 }
    FE-->>U: ✅ 充值成功！当前余额 ¥720.50
```

**关键规则：**

| 规则 | 说明 |
|------|------|
| 充值范围 | 单次 ≥ 0.01，≤ ¥10,000 |
| 幂等性 | 每次充值独立写入 `wallet_log` |
| 事务保证 | 余额更新 + 流水写入在同一事务中 |

---

## 三、担保交易核心流程 🔥

### 3.1 完整交易时序图

```mermaid
sequenceDiagram
    actor BUYER as 👤 买家
    actor SELLER as 👤 卖家
    participant FE_B as 买家前端
    participant FE_S as 卖家前端
    participant API as OrderController
    participant DB as 数据库
    participant GROWTH as UserGrowthService

    Note over BUYER,SELLER: === 步骤1：买家下单 ===
    BUYER->>FE_B: 商品详情页点击"立即购买"
    FE_B->>API: POST /api/order/create { itemId, price }
    API->>DB: 🔒 BEGIN TRANSACTION
    API->>DB: 检查商品状态 = ON_SALE
    API->>DB: 检查买家余额 ≥ 商品价格
    API->>DB: UPDATE sys_user SET wallet_balance = balance - price<br/>(买家扣款，资金进入平台担保)
    API->>DB: INSERT INTO trade_order (status='WAITING_MEET')
    API->>DB: INSERT INTO wallet_log (type='PAYMENT', amount=-price)
    API->>DB: UPDATE item SET status='PENDING'
    API->>DB: 🔒 COMMIT
    API-->>FE_B: { orderId, status: 'WAITING_MEET' }
    FE_B-->>BUYER: ✅ 下单成功，请联系卖家线下见面

    Note over BUYER,SELLER: === 步骤2：线下见面交易 ===
    Note over BUYER,SELLER: 买卖双方通过聊天约定地点<br/>当面验货，无需系统操作

    Note over BUYER,SELLER: === 步骤3：买家确认收货 ===
    BUYER->>FE_B: 点击"确认收货"
    FE_B->>API: PUT /api/order/{id}/confirm
    API->>DB: 🔒 BEGIN TRANSACTION
    API->>DB: 校验订单状态 = WAITING_MEET
    API->>DB: 校验操作人是买家本人
    API->>DB: UPDATE trade_order SET status='COMPLETED', completed_at=NOW()
    API->>DB: UPDATE sys_user SET wallet_balance = balance + price<br/>(卖家收款，资金解冻)
    API->>DB: INSERT INTO wallet_log (type='INCOME', amount=+price)
    API->>DB: UPDATE item SET status='SOLD'
    API->>GROWTH: addExp(buyerId, +50)
    API->>GROWTH: addExp(sellerId, +50)
    API->>DB: 🔒 COMMIT
    API-->>FE_B: { status: 'COMPLETED' }
    FE_B-->>BUYER: ✅ 收货确认成功
    FE_S-->>SELLER: 💰 收到款项通知
```

### 3.2 订单取消（退款）流程

```mermaid
sequenceDiagram
    actor BUYER as 👤 买家
    participant FE as 前端
    participant API as OrderController
    participant DB as 数据库

    BUYER->>FE: 点击"取消订单"
    FE->>FE: ElMessageBox.confirm('确定取消订单？')
    BUYER->>FE: 确认取消
    FE->>API: PUT /api/order/{id}/cancel
    API->>DB: 🔒 BEGIN TRANSACTION
    API->>DB: 校验订单状态 = WAITING_MEET
    API->>DB: 校验操作人是买家本人
    API->>DB: UPDATE trade_order SET status='CANCELLED', cancelled_at=NOW()
    API->>DB: UPDATE sys_user SET wallet_balance = balance + price<br/>(买家退款到账)
    API->>DB: INSERT INTO wallet_log (type='REFUND', amount=+price)
    API->>DB: UPDATE item SET status='ON_SALE'<br/>(商品重新上架)
    API->>DB: 🔒 COMMIT
    API-->>FE: { status: 'CANCELLED' }
    FE-->>BUYER: ✅ 订单已取消，退款已到账
```

---

## 四、订单 & 商品状态机

```mermaid
stateDiagram-v2
    direction LR

    state "商品状态" as ITEM_STATE
    state "订单状态" as ORDER_STATE

    state ITEM_STATE {
        ON_SALE: 🟢 在售中
        PENDING: 🟡 交易中
        SOLD: 🔴 已售出
        OFF_SHELF: ⚫ 已下架

        ON_SALE --> PENDING: 买家下单
        PENDING --> SOLD: 买家确认收货
        PENDING --> ON_SALE: 买家取消订单
        ON_SALE --> OFF_SHELF: 卖家/管理员下架
        OFF_SHELF --> ON_SALE: 卖家重新上架
    }

    state ORDER_STATE {
        WAITING_MEET: 🟡 待线下见面
        COMPLETED: 🟢 已完成
        CANCELLED: 🔴 已取消

        WAITING_MEET --> COMPLETED: 买家确认收货<br/>→ 卖家收款<br/>→ 双方 +50 EXP
        WAITING_MEET --> CANCELLED: 买家取消<br/>→ 买家退款<br/>→ 商品重新上架
    }
```

> **核心约束**：同一商品同一时间只能有一个活跃订单（状态为 `PENDING` 时他人不可再购买）。

---

## 五、管理员数据大盘

```mermaid
graph TB
    subgraph 数据来源
        U[(sys_user)]
        I[(item)]
        O[(trade_order)]
        V[(violation_report)]
    end

    subgraph 统计计算
        STAT1[COUNT: role='USER'<br/>→ 注册用户数]
        STAT2[COUNT: status='ON_SALE'<br/>AND is_deleted=false<br/>→ 活跃商品数]
        STAT3[SUM: status='COMPLETED'<br/>AND DATE=今天<br/>→ 今日交易额]
        STAT4[COUNT: DATE=今天<br/>→ 拦截违规数]
    end

    subgraph 前端展示
        CARD1[👥 注册用户<br/>1,280]
        CARD2[📦 活跃商品<br/>356]
        CARD3[💰 今日交易额<br/>¥12,500]
        CARD4[🛡️ 拦截违规<br/>23]
    end

    U --> STAT1 --> CARD1
    I --> STAT2 --> CARD2
    O --> STAT3 --> CARD3
    V --> STAT4 --> CARD4
```

```mermaid
sequenceDiagram
    actor ADMIN as 🛡️ 管理员
    participant FE as DashboardPage.vue
    participant API as AdminController
    participant DB as 数据库

    ADMIN->>FE: 登录后自动跳转数据大盘
    FE->>API: GET /api/admin/dashboard
    API->>DB: SELECT COUNT(*) FROM sys_user WHERE role='USER'
    API->>DB: SELECT COUNT(*) FROM item WHERE status='ON_SALE'
    API->>DB: SELECT SUM(price) FROM trade_order<br/>WHERE status='COMPLETED' AND DATE=今天
    API->>DB: SELECT COUNT(*) FROM violation_report WHERE DATE=今天
    API->>DB: SELECT * FROM violation_report<br/>ORDER BY created_at DESC LIMIT 5
    DB-->>API: 统计数据 + 最近违规列表
    API-->>FE: { userCount, activeItems, todayTrade, violations, recentReports }
    FE-->>ADMIN: 📊 展示四张统计卡片 + 最近违规列表
```

---

## 六、违规审核与处罚流程

```mermaid
sequenceDiagram
    actor ADMIN as 🛡️ 管理员
    participant FE as ViolationsPage.vue
    participant API as AdminController
    participant DB as 数据库
    participant BAN as BanService (A模块)

    ADMIN->>FE: 进入"违规审核"工作台
    FE->>API: GET /api/admin/violations?status=PENDING
    API->>DB: SELECT * FROM violation_report<br/>WHERE status='PENDING' ORDER BY created_at DESC
    DB-->>API: 待处理违规列表
    API-->>FE: [{ id, userId, violationType, violationReason, originalTitle, ... }]
    FE-->>ADMIN: 📋 展示违规列表

    alt 确认违规 → 一键封禁
        ADMIN->>FE: 点击"确认违规" → 弹出封禁对话框
        ADMIN->>FE: 选择处罚类型 + 填写原因
        FE->>API: PUT /api/admin/violations/{id}/confirm<br/>{ type, reason, banDays? }
        API->>DB: 🔒 BEGIN TRANSACTION
        API->>DB: UPDATE violation_report SET status='CONFIRMED'
        API->>BAN: POST /api/admin/ban-user<br/>{ userId, type, reason, banDays }
        API->>DB: INSERT INTO violation_log
        API->>DB: 🔒 COMMIT
        API-->>FE: { success: true }
        FE-->>ADMIN: ✅ 处罚已生效

    else 误判放行
        ADMIN->>FE: 点击"误判放行"
        FE->>API: PUT /api/admin/violations/{id}/dismiss
        API->>DB: UPDATE violation_report SET status='DISMISSED'
        API->>DB: UPDATE item SET status='ON_SALE'<br/>(商品正常发布)
        API-->>FE: { success: true }
        FE-->>ADMIN: ✅ 已放行，商品正常上架
    end
```

### 违规记录状态流转

```mermaid
stateDiagram-v2
    PENDING: 🟡 待处理<br/>(AI 拦截后等待人工复核)
    CONFIRMED: 🔴 已确认<br/>(管理员确认违规，已处罚)
    DISMISSED: 🟢 已驳回<br/>(AI 误判，商品正常放行)

    PENDING --> CONFIRMED: 管理员确认违规<br/>→ 封禁用户<br/>→ 记录 violation_log
    PENDING --> DISMISSED: 管理员标记误判<br/>→ 商品状态改为 ON_SALE
```

---

## 七、客服聊天流程

```mermaid
sequenceDiagram
    actor USER as 👤 普通用户
    actor ADMIN as 🛡️ 管理员
    participant FE_U as 用户聊天页
    participant FE_A as ChatPage.vue (管理员)
    participant API as ChatController
    participant DB as 数据库

    Note over USER,ADMIN: === 用户发起客服会话 ===
    USER->>FE_U: 点击"联系客服"
    FE_U->>API: POST /api/chat/send<br/>{ receiverId: admin, content: "..." }
    API->>DB: INSERT INTO chat_message<br/>(conversation_id='{userId}_admin')
    DB-->>API: OK

    Note over USER,ADMIN: === 管理员查看客服列表 ===
    ADMIN->>FE_A: 进入"客服收件箱"
    FE_A->>API: GET /api/admin/chat/sessions
    API->>DB: SELECT DISTINCT conversation_id<br/>FROM chat_message<br/>WHERE conversation_id LIKE '%_admin'
    DB-->>API: [{ conversationId, lastMessage, unreadCount, userName }]
    API-->>FE_A: 活跃会话列表
    FE_A-->>ADMIN: 📋 展示所有客服会话（类似工单列表）

    Note over USER,ADMIN: === 管理员回复 ===
    ADMIN->>FE_A: 点击某个会话
    FE_A->>API: GET /api/chat/messages?conversation_id={id}
    API-->>FE_A: 历史消息列表
    ADMIN->>FE_A: 输入回复内容 → 发送
    FE_A->>API: POST /api/chat/send<br/>{ conversationId, content }
    API->>DB: INSERT INTO chat_message
    DB-->>API: OK
    FE_U-->>USER: 💬 收到客服回复（轮询刷新）
```

---

## 八、强制管理流程

```mermaid
sequenceDiagram
    actor ADMIN as 🛡️ 管理员
    participant FE as 管理后台
    participant API as AdminController
    participant DB as 数据库
    participant GROWTH as UserGrowthService

    alt 强制下架商品
        ADMIN->>FE: 商品详情页 → "强制下架"
        FE->>FE: ElMessageBox.confirm + 输入下架原因
        ADMIN->>FE: 确认
        FE->>API: PUT /api/admin/item/{id}/force-off-shelf<br/>{ reason }
        API->>DB: 🔒 BEGIN TRANSACTION
        API->>DB: UPDATE item SET status='OFF_SHELF'
        API->>GROWTH: addExp(publisherId, -30)<br/>(卖家扣经验)
        API->>DB: INSERT INTO violation_log<br/>(type='WARNING', reason=下架原因)
        API->>DB: 🔒 COMMIT
        API-->>FE: { success: true }
        FE-->>ADMIN: ✅ 商品已强制下架，卖家已扣经验

    else 强制重置密码
        ADMIN->>FE: 用户管理 → "重置密码"
        FE->>API: POST /api/admin/reset-password<br/>{ userId }
        API->>DB: UPDATE sys_user SET password=BCrypt('123456')
        API->>DB: UPDATE sys_user SET token_version = token_version + 1<br/>(强制下线)
        API-->>FE: { success: true, newPassword: '123456' }
        FE-->>ADMIN: ✅ 密码已重置为 123456
    end
```

---

## 九、数据流汇总：模块四涉及的表

```mermaid
graph LR
    subgraph 模块四直接操作的表
        TO[(trade_order<br/>订单表)]
        WL[(wallet_log<br/>资金流水)]
    end

    subgraph 模块四读取/间接操作的表
        SU[(sys_user<br/>用户/余额/经验)]
        IT[(item<br/>商品)]
        VR[(violation_report<br/>违规上报)]
        VL[(violation_log<br/>处罚日志)]
        CM[(chat_message<br/>聊天)]
    end

    subgraph 操作者
        USER[普通用户]
        ADMIN[管理员]
    end

    USER -->|充值/下单/确认/取消| TO
    USER -->|充值/下单/确认/取消| WL
    ADMIN -->|数据大盘| SU
    ADMIN -->|数据大盘| IT
    ADMIN -->|数据大盘| TO
    ADMIN -->|违规审核| VR
    ADMIN -->|违规审核| VL
    ADMIN -->|强制下架| IT
    ADMIN -->|强制下架| VL
    ADMIN -->|重置密码| SU
    ADMIN -->|客服聊天| CM
```

---

## 十、后端 Package 结构

```
backend/src/main/java/com/zhiyi/module/
├── trade/                          # 钱包与交易
│   ├── controller/
│   │   ├── WalletController.java   # 余额、充值、流水
│   │   └── OrderController.java    # 下单、确认、取消、订单列表
│   ├── entity/
│   │   ├── TradeOrder.java
│   │   └── WalletLog.java
│   ├── mapper/
│   │   ├── TradeOrderMapper.java
│   │   └── WalletLogMapper.java
│   └── service/
│       ├── WalletService.java
│       └── OrderService.java       # 🔥 @Transactional 担保交易核心
│
└── admin/                          # 超管控制台
    ├── controller/
    │   ├── AdminDashboardController.java   # 数据大盘
    │   ├── AdminViolationController.java   # 违规审核
    │   ├── AdminChatController.java        # 客服收件箱
    │   └── AdminManageController.java      # 强制下架、重置密码
    ├── entity/
    │   └── ViolationReport.java
    ├── mapper/
    │   └── ViolationReportMapper.java
    └── service/
        ├── AdminDashboardService.java
        ├── AdminViolationService.java
        └── AdminManageService.java
```

---

## 十一、前端页面与 API 对照

| 页面 | 调用的 API | 说明 |
|------|-----------|------|
| `wallet/WalletPage.vue` | `GET /api/wallet/balance`、`POST /api/wallet/recharge`、`GET /api/wallet/logs` | 钱包首页 |
| `wallet/OrdersBoughtPage.vue` | `GET /api/order/my-bought`、`PUT /api/order/{id}/confirm`、`PUT /api/order/{id}/cancel` | 我买的 |
| `wallet/OrdersSoldPage.vue` | `GET /api/order/my-sold` | 我卖的 |
| `admin/DashboardPage.vue` | `GET /api/admin/dashboard` | 数据大盘 |
| `admin/ViolationsPage.vue` | `GET /api/admin/violations`、`PUT .../{id}/confirm`、`PUT .../{id}/dismiss`、`POST /api/admin/ban-user` | 违规审核 |
| `admin/ChatPage.vue` | `GET /api/admin/chat/sessions`、`GET /api/chat/messages`、`POST /api/chat/send` | 客服收件箱 |

---

> 📝 **编写日期**：2026-07-11 | 基于《智易校园-功能需求规格说明书.md》v2.0 模块四编写
