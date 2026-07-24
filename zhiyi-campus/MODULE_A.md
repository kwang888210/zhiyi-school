# 模块一：用户认证与成长体系（成员 A）

> 负责人：A | 涉及表：`sys_user`、`school`、`item`、`trade_order`、`trade_review`、`chat_message`、`violation_log`、`exp_log` | 分支：`A`

## 一、已实现功能（对照需求 1.1–1.6 及 A 分支扩展）

| 需求 | 实现 | 验收状态 |
|------|------|---------|
| 1.1 账户注册 | 学号唯一（先查提示 + DB 唯一索引兜底并发竞态）、BCrypt 加密、默认昵称「同学_学号后4位」、注册即登录 | ✅ 自动化测试通过 |
| 1.2 账户登录 | 学号统一小写、JWT（24h）、封禁状态检查、临时封禁到期自动恢复、登录失败限流（5次锁5分钟，最后一次失败重新计时） | ✅ 自动化测试通过 |
| 1.3 密码找回 | 密保三步流程、答案比对忽略首尾空格+大小写、答案 BCrypt 存储、**新密码不得与原密码相同**、重置后旧 Token 全部失效 | ✅ 自动化测试通过 |
| 1.4 角色划分 | `@RoleRequired("ADMIN")` 注解 + RoleInterceptor，管理员由 SQL 初始化 | ✅ 自动化测试通过 |
| 1.5 成长体系 | exp 原子增减且最低为 0、等级只升不降、exp_log 流水、升级事件、进度条数据（VO 内含阈值） | ✅ 自动化测试通过 |
| 1.6 违规封禁 | 警告/限时/永久三级，violation_log 可追溯，封禁立即踢下线，发布处罚事件，到期自动恢复，提前解封（**仅后端接口；管理端 UI 归 D 的超管控制台**） | ✅ 自动化测试通过 |
| 扩展：账号安全 | **修改密码**（验证原密码、新旧不得相同、全端强制下线）、**注销账号**（软注销 CANCELLED：密码二次确认、有进行中订单禁止注销、在售商品自动下架、学号保留占用、管理员可恢复） | ✅ 自动化测试通过 |
| 扩展：学校与校园身份 | 注册必选学校、学校邮箱后缀校验、学院/年级/宿舍资料、同学院/同级/同楼关系标签；商品发布时固化学校，普通商品流量按所属学校隔离 | ✅ 自动化测试通过 |
| 扩展：交易评价与信誉 | 完成订单后一单一评；基于交易完成率、响应速度、描述准确度、历史好评、近 30 天活跃度生成五维信誉雷达 | ✅ 自动化测试通过 |
| 扩展：管理员学校边界 | 管理员由初始化 SQL 默认归属上海大学；访问普通接口时与普通用户一样受学校限制，只有 `/api/admin/**` 保持全平台管理范围 | ✅ 自动化测试通过 |
| 扩展：跨校安全 | 后端拦截跨校下单、收藏、查看卖家联系方式、联系卖家和普通聊天；管理后台客服使用独立管理员接口跨校处理 | ✅ 自动化测试通过 |
| 扩展：界面一致性 | 自定义 `AppSelect`、评价弹窗、卖家详情、信誉雷达，并统一对话框、确认框、下拉菜单、选择器和顶部消息提示的项目视觉与图层 | ✅ 前端测试及构建通过 |

## 二、API 一览

### 公开接口
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/register` | 注册（返回 token + user） |
| POST | `/api/auth/login` | 登录（返回 token + user） |
| GET | `/api/auth/security-question?studentId=` | 查密保问题 |
| GET | `/api/auth/security-questions` | 预设密保问题列表 |
| POST | `/api/auth/reset-password` | 验证密保并重置密码 |
| GET | `/api/school/list` | 启用中的学校列表，供注册与资料页选择 |

### 登录接口
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/user/profile` | 当前用户（含 levelTitle / nextLevelExp / currentLevelBaseExp，前端进度条直接用） |
| PUT | `/api/user/profile` | 更新昵称、手机号、学校、学校邮箱、学院、年级、宿舍 |
| GET | `/api/user/exp-log?page=&size=` | 经验流水（分页） |
| GET | `/api/user/{id}/card` | 用户公开名片，返回昵称、等级和学校名称 |
| GET | `/api/user/{id}/seller-detail` | 本校卖家详情与其主动填写的联系方式/校园资料 |
| GET | `/api/user/{id}/relation` | 当前用户视角的同学院/同级/同楼关系标签 |
| GET | `/api/user/{id}/reputation` | 用户五维信誉分与评价样本数 |
| POST | `/api/order/{id}/review` | 买家对已完成订单进行一单一评 |
| PUT | `/api/user/change-password` | 修改密码 `{oldPassword, newPassword, confirmPassword}`（新旧不得相同） |
| POST | `/api/user/cancel-account` | 注销账号 `{password}`（软注销，进行中订单存在时返回 409） |

### 管理员接口（@RoleRequired("ADMIN")，供 D 的超管控制台前端调用）
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/admin/users?keyword=&page=&size=` | 用户检索（学号/昵称模糊），封禁弹窗选人用 |
| POST | `/api/admin/ban-user` | `{userId, type: WARNING/BAN_TEMP/BAN_PERM, reason, banDays?}` |
| POST | `/api/admin/unban-user` | `{userId}` 提前解封 / 恢复已注销账户 |
| GET | `/api/admin/violation-logs?userId=&page=&size=` | 处罚记录（含被处罚人学号/昵称） |
| GET | `/api/admin/chat/sessions` | 全平台客服会话列表 |
| GET | `/api/admin/chat/messages?conversationId=&peerId=&relatedItemId=` | 跨校读取指定客服会话 |
| POST | `/api/admin/chat/send` | 管理员跨校回复客服消息 |
| GET | `/api/admin/chat/unread?conversationId=` | 管理后台轮询未读客服消息 |

## 三、给 B / C / D 的集成契约

### 1. 加/扣经验（D 确认收货、B/D 强制下架时调用）
```java
@Autowired UserGrowthService growthService;

// D：确认收货事务内（与订单/钱包同事务，一起回滚）
growthService.addExp(order.getBuyerId(),  UserGrowthService.EXP_ORDER_COMPLETED, "买家完成订单");
growthService.addExp(order.getSellerId(), UserGrowthService.EXP_ORDER_COMPLETED, "卖家完成订单");

// B/D：商品被管理员强制下架
growthService.addExp(publisherId, UserGrowthService.EXP_FORCED_OFF_SHELF, "商品被管理员强制下架");
```
内部为**单条 UPDATE 原子增减**，并发安全；等级/流水自动结算，无需自己更新 `level`。

- EXP 最低钳制为 0，等级只升不降；扣分不会让已有等级回退。
- `exp_log.delta` 记录调用方请求的原始变动量。例如剩余 10 EXP 时扣 30：`delta=-30`、`expAfter=0`。
- 只有等级实际提升时才发布 `UserLevelUpEvent`。

### 2. 需要管理员权限的接口
Controller 类或方法上加 `@RoleRequired("ADMIN")` 即可，无需自己判断 role。

### 3. 用户状态变化后
若绕过 `BanService`/`AuthService` 直接改了 `sys_user.status` 或推进 `token_version`，事务内必须调用 `UserStateCache#invalidateAfterCommit(userId)`。该方法只在事务提交后清缓存；事务回滚不会误删现有快照。明确处于非事务场景时可调用 `invalidate(userId)` 立即失效。

### 4. 给 C 的系统消息事件

- `UserLevelUpEvent(userId, oldLevel, newLevel, expAfter)`：仅等级实际提升时发布。
- `UserPunishedEvent(userId, type, reason, banDays, banUntilTime)`：处罚日志落库后发布；警告没有封禁时间，限时封禁携带截止时间。
- C 使用 `@TransactionalEventListener(phase = TransactionPhase.AFTER_COMMIT)` 消费事件，并用 `@Transactional(propagation = Propagation.REQUIRES_NEW)` 在新事务中写入 `chat_message`。
- A 不创建聊天消息；当前没有监听器时，也不影响经验或处罚事务。

### 5. 前端
- 全局用户态：`useUserStore()`（`stores/user.js`），登录后 `setLogin(res.data)`，刷新后 `fetchProfile()`。
- 等级徽章 / 头像 / 价格公共组件：`components/common/LevelBadge.vue`、`UserAvatar.vue`、`PriceTag.vue`。
- 学校选择统一使用 `components/common/AppSelect.vue`，不要再新增原生 `<select>`。
- 信誉展示统一使用 `components/common/ReputationRadar.vue`；订单评价统一使用 `components/trade/OrderReviewDialog.vue`；卖家详情统一使用 `components/user/SellerDetailDialog.vue`。
- Element Plus 浮层的全局视觉与层级规则集中在 `assets/styles/element-overlays.css`，包括普通对话框、确认框、账户菜单、选择器下拉和顶部消息提示。
- 顶部操作提示默认 3 秒自动关闭，并统一显示可提前关闭的“×”按钮。
- 占位页：非 A 页面统一用 `components/common/WipPage.vue` 占位，实现后直接替换。

### 6. 学校范围与管理员边界

- 所有登录账号访问普通商品浏览、搜索、排行、标签和详情接口时，均以 `sys_user.school_id` 作为范围；管理员不会因为 `ADMIN` 身份绕过普通接口的学校限制。
- 钱包、订单、我的发布等普通接口仍按当前账号所有权处理；创建订单时后端额外验证买家、卖家和商品学校一致。
- 收藏、商品详情、卖家资料、商品会话及普通聊天均在服务层执行学校校验，不能依赖前端隐藏按钮。
- 用户可以跨校联系管理员客服；管理员跨校读取和回复只能走带 `@RoleRequired("ADMIN")` 的 `/api/admin/chat/**`。
- 管理统计、商品治理、用户治理和客服收件箱等 `/api/admin/**` 保持全平台范围。
- 通用校验集中在 `com.zhiyi.common.SchoolScopeGuard`；新增普通业务时优先复用，避免各模块自行定义不一致的空学校/跨校行为。

## 四、高并发设计（10000 并发目标）

| 层 | 措施 | 说明 |
|----|------|------|
| 连接层 | Tomcat NIO `max-connections=10000`、`threads.max=500`、`accept-count=1000` | 万级连接挂起，活跃请求由 500 工作线程消化 |
| 鉴权 | JWT 无状态 + **每请求只解析一次**（1 次签名验证拿全部 Claims） | 无 session、无中心化存储瓶颈 |
| 状态校验 | 封禁/Token 版本走 **Caffeine 本地缓存**（60s TTL，事务提交后主动失效） | 10000 并发下 sys_user 不再是每请求热点，DB 压力 ≈ 1 次/用户/分钟 |
| 强制下线 | `token_version` 原子版本字段 | 改密、重置、封禁、注销时版本 +1，旧 Token 立即作废，无需维护 Token 黑名单表 |
| 登录 | 规范化学号 + 失败限流（Caffeine 计数器，5 次锁 300s） | 大小写/首尾空格不能绕过；每次失败刷新完整窗口 |
| 经验值 | `UPDATE ... SET exp = GREATEST(0, exp + ?)` 原子增减 | 并发确认收货不丢加分；等级只升不降 |
| 注册唯一性 | 唯一索引兜底 + 捕获 `DuplicateKeyException` | 实测 5 并发同学号注册只插入 1 条 |
| 连接池 | HikariCP `max=50`、`connection-timeout=3s` | 快进快出；拿不到连接快速失败，避免线程雪崩 |
| 集群扩展 | 本地缓存接口化（`UserStateCache`） | 多实例部署时可平替为 Redis，接口不变 |

**压测结果**（本机单实例，SQL stdout 日志开启状态）：
```
node load-test.mjs — GET /api/user/profile（走 JWT 全链路 + DB 查询）
5000 请求 / 500 并发：ok=5000 fail=0，QPS≈2700，p50=167ms p99=334ms
```
> 压测/生产前请注释 `application.yml` 中 `log-impl` 一行（stdout 打 SQL 是同步 IO 瓶颈），并将 Hikari/threads 按机器核数微调。

## 五、数据库变更（相对初版 SQL）

1. `sys_user` 新增 `token_version INT NOT NULL DEFAULT 0`（Token 版本）。
2. 新增 `exp_log` 表（经验流水，见 `zhiyi_campus_init.sql` 2.10）。
3. 新增 `school` 字典表，初始化上海大学（`SHU`）和东华大学（`DHU`）及学校邮箱后缀。
4. `sys_user` 新增 `school_id`、`school_email`、`college`、`grade`、`dormitory`；`item` 新增并索引 `school_id`。
5. 新增 `trade_review` 表；`order_id` 唯一索引保证一单一评，并保存星级、描述准确性和评价文本。
6. 管理员初始密码占位哈希替换为 BCrypt 哈希，并在初始化 SQL 中直接关联 `code='SHU'` 的上海大学；初始化后请在本地重置管理员密码，不在文档中写明文口令。
7. `sys_user.status` 新增取值 `CANCELLED`（已注销，软注销；无需改表结构，仅枚举语义扩展）。
8. 当前开发环境直接以 `zhiyi_campus_init.sql` 重建数据库，不保留旧库迁移脚本或应用启动回填逻辑。

## 六、本地启动

```bash
# 1. 建库（会 DROP 重建）
mysql -u root -p --default-character-set=utf8mb4 < zhiyi_campus_init.sql

# 2. 后端（MySQL 密码与 JWT 密钥通过环境变量 MYSQL_PASSWORD/JWT_SECRET 提供）
cd zhiyi-campus/backend && mvn spring-boot:run      # → :8080

# 3. 前端
cd zhiyi-campus/frontend && npm install && npm run dev   # → :3000（/api 自动代理）
```

测试账号：管理员账号初始化后请本地重置密码；注册页可自助注册普通用户。

## 七、A → main 合并内容（截至 2026-07-24）

本节按 `main...A` 的实际分支差异及当前已暂存补充整理，作为合并说明。

### 1. 已提交内容

| 提交 | 内容 |
|------|------|
| `7bfb933` | 整理 `.gitignore`，移除不再随项目维护的重复说明与验证材料。 |
| `bf76492` | 增加学校字典、注册/资料学校字段、学校邮箱规则、校园关系标签、商品学校隔离、卖家详情、交易评价与五维信誉体系，并补齐对应前后端测试。 |
| `8ae613d` | 删除废弃数据库迁移脚本，开发环境统一以完整初始化 SQL 建库。 |
| `5d821bd` | 修正 README 中数据库字符集以及前后端启动目录/命令。 |
| `e7b969a` | 引入 `AppSelect` 和项目化浮层样式；统一选择器、确认框、账户菜单、顶部提示，并实现评价弹窗的独立视觉、响应式布局和图层规则。 |

### 2. 当前工作区补充

- 管理员在 `zhiyi_campus_init.sql` 中直接初始化为上海大学账号，不增加旧库迁移或启动兼容代码。
- 管理员访问普通商品、订单、钱包、收藏和聊天等功能时，行为与普通用户一致；访问 `/api/admin/**` 时仅校验 `ADMIN` 身份并保持全平台数据范围。
- 新增 `SchoolScopeGuard`，在后端统一拦截跨校商品查看、收藏、卖家资料、下单、联系卖家及普通聊天。
- 下单前校验买家学校、商品学校和卖家当前学校三者一致，并确保校验发生在钱包扣款之前。
- 管理后台客服改用 `/api/admin/chat/messages`、`/api/admin/chat/send`、`/api/admin/chat/unread`，避免普通聊天学校限制影响跨校客服。
- 普通聊天的发送、读取、会话列表与未读统计全部按学校过滤；用户联系管理员客服仍允许跨校。
- 顶部操作提示保持 3 秒自动关闭，同时提供符合项目视觉的圆形“×”提前关闭按钮。

### 3. 合并前验证

```text
后端：mvn test                     132 tests passed
前端：npm test -- --run             27 tests passed
构建：npm run build                 passed
差异：git diff --check              passed
```

前端构建仅保留依赖中的 PURE 注释和主包超过 500 kB 的既有警告，不影响构建产物生成。
