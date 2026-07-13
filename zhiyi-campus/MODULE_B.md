# 模块二：AI 赋能的内容发布中枢（成员 B）

> 负责人：B | 涉及表：`item`、`category`、`violation_report` | 分支：`feature/ai-publish`

## 一、已实现功能（对照需求 2.1–2.5）

| 需求 | 实现 | 验收状态 |
|------|------|---------|
| 2.1 商品分类体系 | 发布页从 `/api/category/list` 读取预设大类；发布时后端校验 `category_id` 必须存在 | ✅ 联调通过 |
| 2.2 双向发布流 | 支持 `SELL` 出售和 `BUY` 求购；发布后写入 `item`，默认 `status=ON_SALE`、`view_count=0` | ✅ 联调通过 |
| 2.3 商品图片上传 | `POST /api/item/upload-image` 上传 jpg/png/webp，单张 ≤ 5MB，存储到 `/uploads/items/yyyyMMdd/`，数据库只存 URL JSON 数组 | ✅ 联调通过 |
| 2.4 AI 智能机审与动态打标 | 当前实现为本地规则审核 + 自动标签生成：明显违规词拦截并写入 `violation_report`；合规内容自动生成 `ai_tags` | ✅ 联调通过 |
| 2.5 商品管理 | 复用 C 模块已实现的我的发布、下架、重新上架、删除接口；发布页提供“我的发布”入口 | ✅ 编译通过 |

> 说明：为了不依赖第三方 AI Key，当前版本先实现“可演示、可测试”的本地规则审核。`application.yml` 已保留 `zhiyi.ai.api-url/api-key/timeout` 配置位，后续可把 `ItemPublishService#review` 替换为真实大模型调用，外部契约不变。

## 二、API 一览

### 登录接口
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/item/upload-image` | 上传商品图片，`multipart/form-data`，字段名 `file`，返回 `{ url }` |
| POST | `/api/item/publish` | 发布商品，返回 `ItemCardVO` |

### 发布参数

`POST /api/item/publish`

```json
{
  "type": "SELL",
  "title": "99新 iPad Air5",
  "description": "考研结束出，配件齐全。",
  "categoryId": 1,
  "price": 2500.00,
  "images": ["/uploads/items/20260711/xxx.png"],
  "tradeLocation": "图书馆门口"
}
```

校验规则：

- `type` 只能是 `SELL` 或 `BUY`
- `title` 必填，2–50 字
- `description` 必填，10–500 字
- `categoryId` 必填且必须存在
- `price >= 0.01`，最多 2 位小数
- `images` 必须来自平台上传接口，1–9 张
- `tradeLocation` 必填

### 返回示例

```json
{
  "code": 200,
  "message": "发布成功",
  "data": {
    "id": 1,
    "type": "SELL",
    "title": "测试发布 iPad 支架",
    "status": "ON_SALE",
    "viewCount": 0,
    "aiTags": ["数码电子", "iPad", "支架"]
  }
}
```

违规拦截：

```json
{
  "code": 2002,
  "message": "内容包含平台禁止发布的信息：代写",
  "data": null
}
```

## 三、前端页面与文件归属

| 页面/文件 | 说明 |
|-----------|------|
| `frontend/src/views/item/PublishItemPage.vue` | 发布表单、图片上传、预览、前端校验、提交后跳详情页 |
| `frontend/src/api/item.js` | 新增 `uploadItemImage(file)`、`publishItem(data)` |
| `frontend/src/router/index.js` | 已有 `/publish` 登录路由，发布页直接替换占位 |

发布页体验：

- 类型单选：出闲置 / 求购
- 标题、分类、价格、地点、描述完整表单
- 图片上传前限制格式与大小，上传后缩略图预览，首图自动作为封面
- 右侧发布检查面板，实时提示哪些关键项已完成
- 发布成功后跳转 `/item/{id}`，可立即测试模块三详情、收藏、聊天入口

## 四、给 A / C / D 的集成契约

### 1. A 模块：登录态

- 发布和上传接口都走 JWT 拦截器，使用 `@RequestAttribute("userId")` 获取发布者。
- 被封禁/注销用户会被 A 模块拦截器拒绝，无需 B 单独判断。

### 2. C 模块：大厅、搜索、详情、聊天

- B 写入 `item.images` 为 JSON 数组字符串，C 已解析为 `images` / `coverImage`。
- B 写入 `item.ai_tags` 为 JSON 数组字符串，C 搜索可用 `LIKE` 命中标签。
- 发布成功时 `status=ON_SALE`，商品自动进入：
  - `/api/item/list`
  - `/api/item/search`
  - `/api/item/ranking`
  - `/item/{id}` 详情页
- 发布成功返回 `ItemCardVO`，不会增加浏览数；只有访问详情页才会 `view_count + 1`。

### 3. D 模块：管理后台

- 本地审核拦截的违规发布会写入 `violation_report`：
  - `violation_type=CONTENT_VIOLATION`
  - `status=PENDING`
  - `ai_review_error=false`
- D 后续管理后台可按 `status=PENDING` 拉取待处理记录，确认/驳回后更新 `handler_id/handle_note/handled_at`。

## 五、数据库写入说明

### 合规发布

写入 `item`：

| 字段 | 值 |
|------|----|
| `publisher_id` | 当前登录用户 ID |
| `type` | `SELL` / `BUY` |
| `images` | 图片 URL JSON 数组 |
| `ai_tags` | 自动标签 JSON 数组 |
| `ai_reviewed` | `true` |
| `status` | `ON_SALE` |
| `view_count` | `0` |
| `is_deleted` | `false` |

### 违规发布

不写入 `item`，写入 `violation_report` 并返回 `AI_VIOLATION(2002)`。

## 六、本地启动

```bash
# 后端
# MySQL 密码与 JWT 密钥通过环境变量 MYSQL_PASSWORD/JWT_SECRET 提供
cd zhiyi-campus/backend
mvn spring-boot:run

# 前端
cd zhiyi-campus/frontend
npm install
npm run dev
```

访问发布页：

- `http://127.0.0.1:3000/publish`

测试账号：

- 管理员：初始化后请在本地重置密码，不在文档中写明文口令
- 普通用户：注册页自助注册

## 七、验证记录

```bash
mvn -q -DskipTests compile      # 后端编译通过
mvn -q test                     # 后端测试通过
npm run build                   # 前端构建通过
npm test                        # 前端已有单测通过
```

真实联调：

- `POST /api/item/upload-image`：200，返回 `/uploads/items/20260711/...png`
- `POST /api/item/publish`：200，测试商品 ID = 1，`status=ON_SALE`
- `GET /api/item/list?keyword=iPad`：能查到刚发布商品
- 违规标题“测试代写论文”：返回 `code=2002`，发布被拦截
