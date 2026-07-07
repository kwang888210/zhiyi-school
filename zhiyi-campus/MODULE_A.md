# 模块一：用户认证与成长体系（成员 A）

> 负责人：A | 涉及表：`sys_user`、`violation_log`、`exp_log` | 分支：`feature/user-auth`

## 一、已实现功能（对照需求 1.1–1.6）

| 需求 | 实现 | 验收状态 |
|------|------|---------|
| 1.1 账户注册 | 学号唯一（先查提示 + DB 唯一索引兜底并发竞态）、BCrypt 加密、默认昵称「同学_学号后4位」、注册即登录 | ✅ 冒烟通过 |
| 1.2 账户登录 | JWT（24h）、封禁状态检查、临时封禁到期自动恢复、登录失败限流（5次锁5分钟） | ✅ 冒烟通过 |
| 1.3 密码找回 | 密保三步流程、答案比对忽略首尾空格+大小写、答案 BCrypt 存储、**新密码不得与原密码相同**、重置后旧 Token 全部失效 | ✅ 冒烟通过 |
| 1.4 角色划分 | `@RoleRequired("ADMIN")` 注解 + RoleInterceptor，管理员由 SQL 初始化 | ✅ 冒烟通过 |
| 1.5 成长体系 | exp 原子增减、等级由 exp 推导（幂等）、exp_log 流水、进度条数据（VO 内含阈值） | ✅ 单测通过 |
| 1.6 违规封禁 | 警告/限时/永久三级，violation_log 可追溯，封禁立即踢下线，到期自动恢复，提前解封（**仅后端接口；管理端 UI 归 D 的超管控制台**） | ✅ 冒烟通过 |
| 扩展：账号安全 | **修改密码**（验证原密码、新旧不得相同、全端强制下线）、**注销账号**（软注销 CANCELLED：密码二次确认、有进行中订单禁止注销、在售商品自动下架、学号保留占用、管理员可恢复） | ✅ 冒烟通过 |

## 二、API 一览

### 公开接口
| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/auth/register` | 注册（返回 token + user） |
| POST | `/api/auth/login` | 登录（返回 token + user） |
| GET | `/api/auth/security-question?studentId=` | 查密保问题 |
| GET | `/api/auth/security-questions` | 预设密保问题列表 |
| POST | `/api/auth/reset-password` | 验证密保并重置密码 |

### 登录接口
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/user/profile` | 当前用户（含 levelTitle / nextLevelExp / currentLevelBaseExp，前端进度条直接用） |
| PUT | `/api/user/profile` | 更新昵称/手机号 |
| GET | `/api/user/exp-log?page=&size=` | 经验流水（分页） |
| GET | `/api/user/{id}/card` | 公开名片（昵称+等级，**B/C 做商品详情/聊天时直接调**） |
| PUT | `/api/user/change-password` | 修改密码 `{oldPassword, newPassword, confirmPassword}`（新旧不得相同） |
| POST | `/api/user/cancel-account` | 注销账号 `{password}`（软注销，进行中订单存在时返回 409） |

### 管理员接口（@RoleRequired("ADMIN")，供 D 的超管控制台前端调用）
| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/admin/users?keyword=&page=&size=` | 用户检索（学号/昵称模糊），封禁弹窗选人用 |
| POST | `/api/admin/ban-user` | `{userId, type: WARNING/BAN_TEMP/BAN_PERM, reason, banDays?}` |
| POST | `/api/admin/unban-user` | `{userId}` 提前解封 / 恢复已注销账户 |
| GET | `/api/admin/violation-logs?userId=&page=&size=` | 处罚记录（含被处罚人学号/昵称） |

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

### 2. 需要管理员权限的接口
Controller 类或方法上加 `@RoleRequired("ADMIN")` 即可，无需自己判断 role。

### 3. 用户状态变化后
若绕过 `BanService`/`AuthService` 直接改了 `sys_user` 的 `status`/`token_invalid_before`，**必须调用 `UserStateCache#invalidate(userId)`**，否则本机缓存最长 60s 后才生效。

### 4. 前端
- 全局用户态：`useUserStore()`（`stores/user.js`），登录后 `setLogin(res.data)`，刷新后 `fetchProfile()`。
- 等级徽章 / 头像 / 价格公共组件：`components/common/LevelBadge.vue`、`UserAvatar.vue`、`PriceTag.vue`。
- 占位页：非 A 页面统一用 `components/common/WipPage.vue` 占位，实现后直接替换。

## 四、高并发设计（10000 并发目标）

| 层 | 措施 | 说明 |
|----|------|------|
| 连接层 | Tomcat NIO `max-connections=10000`、`threads.max=500`、`accept-count=1000` | 万级连接挂起，活跃请求由 500 工作线程消化 |
| 鉴权 | JWT 无状态 + **每请求只解析一次**（1 次签名验证拿全部 Claims） | 无 session、无中心化存储瓶颈 |
| 状态校验 | 封禁/Token 失效纪元走 **Caffeine 本地缓存**（60s TTL，写后主动失效） | 10000 并发下 sys_user 不再是每请求热点，DB 压力 ≈ 1 次/用户/分钟 |
| 强制下线 | `token_invalid_before` 失效纪元字段 | 改密/封禁推进纪元，旧 Token 立即作废，无需维护 Token 黑名单表 |
| 登录 | 失败限流（Caffeine 计数器，5 次锁 300s） | BCrypt 单次 ~100ms，防撞库拖垮 CPU |
| 经验值 | `UPDATE ... SET exp = GREATEST(0, exp + ?)` 原子增减 | 并发确认收货不丢加分；等级由 exp 推导，幂等 |
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

1. `sys_user` 新增 `token_invalid_before DATETIME`（Token 失效纪元）。
2. 新增 `exp_log` 表（经验流水，见 `zhiyi_campus_init.sql` 2.10）。
3. 管理员初始密码占位哈希替换为真实 BCrypt：账号 `admin` / 密码 `admin123`（密保答案 `admin`）。
4. `sys_user.status` 新增取值 `CANCELLED`（已注销，软注销；无需改表结构，仅枚举语义扩展）。

## 六、本地启动

```bash
# 1. 建库（会 DROP 重建）
mysql -u root -p --default-character-set=utf8mb4 < zhiyi_campus_init.sql

# 2. 后端（MySQL 密码不同时用环境变量覆盖：MYSQL_PASSWORD=xxx）
cd zhiyi-campus/backend && mvn spring-boot:run      # → :8080

# 3. 前端
cd zhiyi-campus/frontend && npm install && npm run dev   # → :3000（/api 自动代理）
```

测试账号：`admin / admin123`（管理员）；注册页可自助注册普通用户。
