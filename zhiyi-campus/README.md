# 🎓 智易校园

基于 AI 辅助审核与闭环生态的校园二手交易平台。

## 技术栈

| 层 | 技术 |
|---|------|
| 后端 | Spring Boot 3.2 + MyBatis-Plus + MySQL 8.0 + JWT |
| 前端 | Vue 3 + Element Plus + Axios + Vite |
| AI | 通义千问 / 文心一言 API（可选接入） |

## 快速启动

### 1. 数据库
```bash
mysql --default-character-set=utf8mb4 -u root -p < zhiyi_campus_init.sql
```

### 2. 后端
```bash
cd zhiyi-campus/backend
mvn spring-boot:run
# → http://localhost:8080
```

### 3. 前端
```bash
cd zhiyi-campus/frontend
npm install
npm run dev
# → http://localhost:3000
```

## 项目结构

```
zhiyi-campus/
├── zhiyi_campus_init.sql          # 数据库建库建表脚本
├── FRONTEND_GUIDE.md              # 前端统一开发规范（必读）
├── 智易校园-功能需求规格说明书.md    # 需求文档
├── backend/                       # Spring Boot 后端
│   └── src/main/java/com/zhiyi/
│       ├── common/                 # 公共类（Result、异常处理）
│       ├── config/                 # 配置（CORS、MyBatis-Plus、JWT）
│       ├── interceptor/            # JWT 拦截器
│       ├── utils/                  # 工具类（JWT）
│       └── module/
│           ├── user/               # 模块一：用户与成长
│           ├── item/               # 模块二：AI 内容发布
│           ├── social/             # 模块三：大厅与社交
│           ├── trade/              # 模块四：钱包与交易
│           └── admin/              # 模块四：管理后台
└── frontend/                      # Vue 3 前端
    └── src/
        ├── api/                    # API 接口封装
        ├── router/                 # 路由
        ├── utils/                  # 工具（axios、auth）
        ├── components/             # 公共组件
        └── views/                  # 页面
```

## 团队分工

| 成员 | 模块 | 分支 |
|------|------|------|
| A | 用户认证与成长体系 | feature/user-auth |
| B | AI 赋能的内容发布 | feature/ai-publish |
| C | 交易大厅与社交互动 | feature/marketplace |
| D | 虚拟钱包与超管后台 | feature/wallet-admin |

## Git 工作流

```
main ←── feature/user-auth      (A)
    ←── feature/ai-publish      (B)
    ←── feature/marketplace     (C)
    ←── feature/wallet-admin    (D)
```

每人独立分支开发，功能完成后 PR → Code Review → 合并至 main。
