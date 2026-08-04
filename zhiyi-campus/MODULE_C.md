# 模块三：交易大厅与社交（成员 C）

> 对照文档：`创新功能方案.md` 的 C1-C10
> 当前分支：`codex/module3-campus-social`
> 涉及表：`item`、`category`、`item_favorite`、`chat_message`、`sys_user`、`trade_order`

## 一、C1-C10 完成情况

| 编号 | 功能 | 实现说明 | 状态 |
|:--:|------|---------|:--:|
| C1 | 学校隔离 | 大厅、搜索、AI 标签、排行榜、详情和聊天均要求登录；普通接口始终使用当前账号的 `school_id`，未登录首页只显示登录引导 | 已完成 |
| C2 | 楼友优先 | “智能推荐”读取用户宿舍楼和校区，按同楼、同校区、全校分组后组内随机；价格、时间等显式排序保持原语义 | 已完成 |
| C3 | 楼友标签 | `ItemCardVO.dormitoryRelation` 返回 `SAME_BUILDING` / `SAME_CAMPUS`，卡片显示“本楼”或“本校区” | 已完成 |
| C4 | 信任标签 | 商品详情调用 `GET /api/user/{id}/relation`，展示同学院、同级、同校区、同楼等关系标签 | 已完成 |
| C5 | 大事件专题 | 首页按日期展示新生入学季、期末备考季、毕业清仓季专题条，并可一键带入分类/关键词筛选 | 已完成 |
| C6 | 排行榜入口 | 首页吸顶侧栏增加“查看完整榜单”入口，跳转 `/ranking` | 已完成 |
| C7 | 传承树 | 教材类商品详情调用同校可见的传承接口，按发布者、历次已完成订单展示时间轴 | 已完成 |
| C8 | AI 标签卡片 | 大厅及排行榜卡片展示 AI 标签，点击后跳转 `/?keyword=标签` 并执行搜索 | 已完成 |
| C9 | 认证标识 | 卡片和详情页支持“已认证”标识；当前兼容主分支 A 模块，以已填写且通过学校后缀校验的 `schoolEmail` 判定 | 已完成 |
| C10 | 价格筛选触发 | 最低价、最高价增加 450ms 防抖监听；失焦或回车立即执行尚未触发的筛选 | 已完成 |

## 二、核心行为

### 1. 学校数据边界

- `/api/item/list`、`/api/item/search`、`/api/item/tags`、`/api/item/ranking`、`/api/item/ranking/tags` 和 `/api/item/{id}` 均经过 JWT 拦截。
- `MarketplaceService` 从当前用户读取学校，不接受前端传入 `schoolId`，避免越权修改查询范围。
- 收藏、商品详情、聊天发起、聊天发送、会话读取和未读消息均校验用户、卖家与商品属于同一学校。
- `/api/admin/**` 保持管理员全平台视角，不复用普通大厅的数据范围。

### 2. 楼友推荐

仅当用户选择“智能推荐”且个人资料填写了宿舍楼或校区时启用：

1. 规范化宿舍和校区文本中的空格。
2. 同一学校、同一校区且宿舍楼完全相同的用户归入“同楼”。
3. 校区相同但宿舍楼不同或未填写宿舍楼的用户归入“同校区”。
4. 查询顺序为同楼、同校区、全校，各组内部使用随机顺序。
5. 若双方校区冲突，即使宿舍楼文本相同也不会误判为同楼。
6. 排序语句只拼接数据库返回的数字用户 ID，不拼接校区或宿舍文本。

### 3. 专题时段

| 专题 | 时段 | 一键筛选 |
|------|------|---------|
| 新生入学季 | 08.25-09.15 | 生活日用 |
| 期末备考季 | 12.20-01.20 | 教材书籍 + “真题” |
| 毕业清仓季 | 05.25-06.30 | “毕业”关键词 |

当前专题规则作为 C 模块前端兜底配置。B8 的后台专题配置接口完成后，可将常量替换为接口数据，页面结构和筛选函数无需重写。

## 三、API

### 公开接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/category/list` | 启用中的商品分类 |
| GET | `/api/school/list` | 登录/注册页学校列表 |

### 登录接口

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/item/list` | 本校在售商品；支持关键词、分类、价格、类型、AI 标签和排序 |
| GET | `/api/item/search` | 本校商品搜索 |
| GET | `/api/item/tags` | 本校在售商品 AI 标签分组统计 |
| GET | `/api/item/ranking?limit=20` | 本校收藏热度榜 |
| GET | `/api/item/ranking/tags?limit=10` | 本校高频 AI 标签 Top 10 |
| GET | `/api/item/{id}` | 本校商品详情 |
| GET | `/api/item/{id}/lineage` | 本校商品传承链 |
| POST | `/api/item/{id}/favorite` | 收藏或取消收藏 |
| GET | `/api/chat/conversations` | 当前用户可访问的同校会话 |
| GET | `/api/chat/messages` | 会话消息并标记已读 |
| POST | `/api/chat/start` | 发起本校商品会话 |
| POST | `/api/chat/send` | 发送消息并校验会话范围 |
| GET | `/api/chat/unread-count` | 当前用户可访问会话的未读数 |

## 四、主要文件

| 文件 | 职责 |
|------|------|
| `backend/.../item/service/MarketplaceService.java` | 同校查询、楼友排序、卡片标签、收藏、排行榜与 AI 标签统计 |
| `backend/.../item/controller/ItemController.java` | 商品大厅、详情、排行与传承链接口 |
| `backend/.../social/service/ChatService.java` | 同校聊天范围、会话、消息与未读统计 |
| `frontend/src/views/home/HomePage.vue` | 大厅、搜索筛选、专题、卡片、吸顶排行榜 |
| `frontend/src/views/ranking/RankingPage.vue` | 独立榜单和热门 AI 标签 |
| `frontend/src/views/item/ItemDetailPage.vue` | 信任标签、认证标识和教材传承时间轴 |
| `frontend/src/router/index.js` | 排行榜与详情登录保护 |

## 五、环境变量

项目不在源码或文档中保存真实凭据。启动后端前由本机环境提供：

```powershell
$env:MYSQL_PASSWORD = "<本机 MySQL 密码>"
$env:JWT_SECRET = "<至少 32 字节的随机密钥>"
$env:AI_API_KEY = "<AI 服务密钥>"
mvn spring-boot:run
```

`MYSQL_USERNAME`、`AI_API_URL` 和 `AI_MODEL` 也可按环境覆盖。不要提交 `.env`、终端历史或包含真实密钥的截图。

## 六、验证记录

- `mvn -q test`：后端全部测试通过。
- `npm run build`：前端生产构建通过。
- 桌面浏览器：未登录引导、搜索框和首屏动画正常。
- 390px 窄屏：无横向溢出，搜索栏、登录引导和按钮正常换行。
- 本机现有数据库缺少最新版 `school` 表，未执行会覆盖数据的初始化脚本；联调前应先备份并使用项目 SQL 做增量升级。

## 七、依赖说明

- C9 使用已通过学校邮箱后缀校验的 `schoolEmail` 判定认证标识，无需额外验证码状态。
- C5 最终应消费 B8 的后台专题配置接口。当前主分支尚无该接口，因此保留前端时段配置。
- C7 的链路数据复用 D3 已有的 `AdminLineageService` 聚合逻辑，普通入口额外增加本校可见性校验。
