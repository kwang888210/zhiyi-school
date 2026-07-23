# 模块三：交易大厅与社交互动（成员 C）

> 负责人：C | 涉及表：`item`、`category`、`item_favorite`、`chat_message`、`sys_user` | 分支：`feature/marketplace`

## 一、已实现功能（对照需求 3.1–3.6）

| 需求 | 实现 | 验收状态 |
|------|------|---------|
| 3.1 首页商品大厅 | 首页从 `WipPage` 替换为真实商品大厅，展示在售商品卡片、主图、标题、价格、分类、收藏数、浏览数、卖家等级；支持分页与“换一批” | ✅ 编译/构建通过 |
| 3.2 商品搜索与筛选 | 关键词模糊搜索标题、描述、AI 标签；支持大类、价格区间、出售/求购类型、智能乱序/最新/价格/浏览排序组合筛选；爆款榜统计全部在售商品的高频 AI 标签 Top 10，标签可点击搜索 | ✅ 接口联调通过 |
| 3.3 商品详情页 | 详情页展示图片、标题、价格、分类、标签、浏览/收藏、卖家等级、描述、交易地点；标签可跳回大厅搜索 | ✅ 构建通过 |
| 3.4 商品收藏 | 登录用户可收藏/取消收藏；唯一索引防重复；我的收藏列表可分页展示；详情/大厅即时更新收藏数 | ✅ 后端编译通过 |
| 3.5 近期爆款榜单 | 按收藏数聚合 Top 10，只展示在售商品；收藏变化后前端刷新榜单 | ✅ 公开接口 200 |
| 3.6 内置聊天系统 | 商品页一键联系卖家；消息列表、对话详情、发送消息、未读统计；前端 2.5s 轮询；打开会话批量已读 | ✅ 登录接口联调通过 |
| 扩展：联系客服 | 用户可从消息页进入管理员客服会话；A 模块升级/处罚事件提交后写入系统消息 | ✅ 后端测试通过 |

## 二、API 一览

### 公开接口
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/category/list` | 商品大类列表 |
| GET | `/api/item/list?page=&size=&keyword=&categoryId=&minPrice=&maxPrice=&type=&sort=` | 商品大厅列表（默认 `sort=random`） |
| GET | `/api/item/search?page=&size=&keyword=&categoryId=&minPrice=&maxPrice=&type=&sort=` | 商品搜索（默认 `sort=latest`） |
| GET | `/api/item/ranking?limit=10` | 近期爆款榜单 |
| GET | `/api/item/{id}` | 商品详情；读取时浏览数 +1 |

### 登录接口
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/item/{id}/favorite` | 收藏/取消收藏，返回 `{ itemId, favorite, favoriteCount }` |
| GET | `/api/item/my-favorites?page=&size=` | 我的收藏 |
| GET | `/api/item/my-items?page=&size=&status=` | 我的发布列表（供 A 页面联调） |
| PUT | `/api/item/{id}/off-shelf` | 用户下架自己的在售商品 |
| PUT | `/api/item/{id}/relist` | 用户重新上架自己的已下架商品 |
| DELETE | `/api/item/{id}` | 用户删除自己的非交易中商品 |
| POST | `/api/chat/start` | 基于商品 `{ itemId }` 创建/获取买卖双方会话元信息 |
| POST | `/api/chat/customer-service` | 创建/获取当前用户与管理员客服会话 |
| GET | `/api/chat/conversations` | 当前用户会话列表，按最新消息倒序 |
| GET | `/api/chat/messages?conversationId=&peerId=&relatedItemId=` | 会话历史；打开后将当前用户收到的未读消息标记已读 |
| POST | `/api/chat/send` | 发送消息 `{ conversationId, receiverId, relatedItemId?, content }` |
| GET | `/api/chat/unread-count` | 当前用户未读消息总数 |
| GET | `/api/chat/unread?conversationId=` | 当前用户未读消息列表 |

## 三、前端页面与文件归属

| 页面 | 文件 | 说明 |
|------|------|------|
| 商品大厅 | `frontend/src/views/home/HomePage.vue` | C 模块主入口，含搜索筛选与排行榜 |
| 商品详情 | `frontend/src/views/item/ItemDetailPage.vue` | B/C 共用；当前已接入 C 的收藏与联系卖家 |
| 消息列表 | `frontend/src/views/chat/ChatListPage.vue` | 会话聚合、未读红点、联系客服 |
| 对话详情 | `frontend/src/views/chat/ChatDetailPage.vue` | 历史消息、轮询刷新、发送消息、关联商品 |
| API 封装 | `frontend/src/api/item.js`、`frontend/src/api/chat.js` | 统一走 `@/utils/request.js` |
| 顶栏红点 | `frontend/src/components/layout/DefaultLayout.vue` | 5 秒轮询 `/api/chat/unread-count` |

## 四、给 A / B / D 的集成契约

### 1. A 模块：用户与成长体系

- C 使用 `request.getAttribute("userId")` 获取当前登录用户，不自行解析 JWT。
- 商品卡片和聊天会话展示卖家/对方等级，称号使用 A 模块 `LevelRule.titleOf(level)`。
- C 已监听：
  - `UserLevelUpEvent(userId, oldLevel, newLevel, expAfter)`
  - `UserPunishedEvent(userId, type, reason, banDays, banUntilTime)`
- 监听器使用 `@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)`，并在 `REQUIRES_NEW` 事务内写入 `chat_message`，不会影响 A 的原事务提交。

### 2. B 模块：商品发布与 AI 审核

- B 发布商品后只要写入 `item` 表且 `status='ON_SALE'`，商品会自动出现在大厅、搜索和榜单。
- `images` 与 `ai_tags` 按 JSON 数组字符串存储，C 后端会解析为 `List<String>` 给前端。
- `ItemDetailPage.vue` 现在已具备完整详情展示，B 后续可继续补充编辑、AI 审核结果展示、发布入口。

### 3. D 模块：交易与管理后台

- 详情页保留“立即购买”按钮位，当前置灰，D 接入订单接口后可直接打开。
- 管理员客服入口使用 `role='ADMIN'` 且 `status='ACTIVE'` 的第一个管理员账号。
- D 的客服收件箱可复用 `/api/chat/conversations`、`/api/chat/messages`、`/api/chat/send`，或在管理端外层增加筛选。

## 五、数据库与并发设计

| 表 | 用途 | 关键约束/索引 |
|----|------|--------------|
| `category` | 商品大类 | `uk_name` 保证分类名唯一 |
| `item` | 商品/求购主体 | `idx_status`、`idx_category`、`idx_created` 支撑大厅筛选 |
| `item_favorite` | 收藏关系 | `UNIQUE (user_id, item_id)` 防重复收藏，`idx_item` 支撑收藏统计 |
| `chat_message` | 聊天消息 | `idx_conversation(conversation_id, created_at)` 查历史，`idx_receiver_unread(receiver_id, is_read)` 查未读 |

并发处理：

- 收藏切换先查现有记录，再插入/删除；并发重复插入由唯一索引兜底，捕获 `DuplicateKeyException` 后返回已收藏状态。
- 浏览数使用单条 `UPDATE item SET view_count = view_count + 1` 原子累加。
- 聊天不引入 WebSocket，使用前端 2.5 秒轮询，降低实现复杂度，满足课程演示场景。
- 会话 ID 使用用户小 ID + 大 ID（如 `2_8`），不额外建会话表；会话列表由 `chat_message` 聚合生成。

## 六、本地启动

```bash
# 1. 建库（会 DROP 重建；本机 MySQL 路径含空格时建议用 cmd）
cmd /c '"C:\Program Files\MySQL\MySQL Server 9.6\bin\mysql.exe" -u root -p --default-character-set=utf8mb4 < "E:\Project\zhiyi-school\zhiyi_campus_init.sql"'

# 2. 后端（MySQL 密码与 JWT 密钥通过环境变量 MYSQL_PASSWORD/JWT_SECRET 提供）
cd zhiyi-campus/backend
mvn spring-boot:run

# 3. 前端
cd zhiyi-campus/frontend
npm install
npm run dev
```

访问地址：

- 后端：`http://localhost:8080`
- 前端：`http://127.0.0.1:3000`

测试账号：

- 管理员：初始化后请在本地重置密码，不在文档中写明文口令
- 普通用户：注册页自助注册

## 七、验证记录

```bash
mvn -q -DskipTests compile      # 后端编译通过
mvn -q test                     # 后端测试通过
npm install                     # 前端依赖安装完成
npm run build                   # 前端生产构建通过
npm test                        # 前端已有单测通过
```

联调检查：

- `GET /api/category/list`：200
- `GET /api/item/list?page=1&size=12`：200
- `GET /api/item/search?keyword=iPad&page=1&size=12`：200
- `GET /api/item/ranking?limit=10`：200
- 管理员登录后 `GET /api/chat/unread-count`：200，返回 `0`
