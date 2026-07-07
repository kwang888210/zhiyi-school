# 🎨 智易校园 —— 前端统一开发规范

> 全员遵守。写完一个页面就在下面表格打勾。

---

## 一、技术栈（已锁定，不可自行更换）

| 层 | 选型 | 版本 | 用途 |
|---|------|------|------|
| 框架 | **Vue 3**（Composition API） | 3.4+ | 组件开发 |
| UI 库 | **Element Plus** | 2.4+ | 按钮/表单/表格/弹窗等 |
| 图标 | **@element-plus/icons-vue** | 2.3+ | 所有图标统一用这个，不引入第三方图标库 |
| 路由 | **vue-router** | 4.2+ | 页面跳转 |
| 状态 | **Pinia** | 2.1+ | 跨组件共享数据（如用户信息） |
| 请求 | **axios** | 1.6+ | 通过 `@/utils/request.js` 发请求 |
| 构建 | **Vite** | 5.0+ | 开发 & 打包 |

---

## 二、目录结构（全员一致）

```
src/
├── api/                    # 接口封装，一个模块一个文件
│   ├── auth.js             # 登录/注册/找回密码
│   ├── item.js             # 商品相关
│   ├── order.js            # 订单相关
│   ├── wallet.js           # 钱包相关
│   ├── chat.js             # 聊天相关
│   └── admin.js            # 管理后台
├── router/index.js         # 路由表（新页面在这里注册）
├── utils/
│   ├── request.js          # axios 实例（统一拦截器）
│   └── auth.js             # Token 读写工具
├── assets/styles/
│   └── global.css          # 全局 CSS 变量（颜色/字号/间距）
├── components/
│   ├── common/             # 通用组件（可被任何页面复用）
│   │   ├── LevelBadge.vue  # 等级徽章
│   │   ├── PriceTag.vue    # 价格展示
│   │   └── UserAvatar.vue  # 头像
│   └── layout/
│       └── DefaultLayout.vue  # 通用页面布局（顶栏+内容区）
└── views/                  # 页面，按模块分文件夹
    ├── login/              # A 负责
    ├── home/               # C 负责
    ├── item/               # B 负责
    ├── user/               # A 负责
    ├── chat/               # C 负责
    ├── wallet/             # D 负责
    └── admin/              # D 负责
```

---

## 三、CSS 变量（必须用，禁止 hardcode 颜色）

`src/assets/styles/global.css` 已定义好了所有变量。**页面里需要颜色/字号/间距时，一律用变量，不要写死 `#xxx` 或 `px`**。

```css
/* ✅ 正确 */
.title { color: var(--text-primary); font-size: var(--font-xl); }
.card { background: var(--bg-card); border-radius: var(--border-radius); }
.price { color: var(--color-danger); }   /* 价格统一红色 */

/* ❌ 错误 */
.title { color: #333333; font-size: 18px; }
.card { background: white; border-radius: 10px; }
.price { color: #ff0000; }
```

**核心变量速查：**

| 用途 | 变量名 | 值 |
|------|--------|-----|
| 主色 | `--color-primary` | `#409EFF` |
| 成功色 | `--color-success` | `#67C23A` |
| 危险色/价格 | `--color-danger` | `#F56C6C` |
| 页面背景 | `--bg-page` | `#F5F7FA` |
| 卡片背景 | `--bg-card` | `#FFFFFF` |
| 圆角 | `--border-radius` | `8px` |
| 卡片阴影 | `--shadow-card` | `0 2px 12px rgba(0,0,0,0.06)` |

---

## 四、组件开发规范

### 4.1 所有页面用 Composition API（`<script setup>`）

```vue
<!-- ✅ 正确：Vue 3 setup -->
<template>
  <div class="page">
    <p>{{ title }}</p>
    <el-button @click="handleClick">确认</el-button>
  </div>
</template>

<script setup>
import { ref } from 'vue'
const title = ref('Hello')
function handleClick() { /* ... */ }
</script>

<style scoped>
.page { padding: var(--spacing-md); }
</style>
```

```vue
<!-- ❌ 错误：Options API -->
<script>
export default {
  data() { return { title: '' } },
  methods: { handleClick() {} }
}
</script>
```

### 4.2 发请求用 `@/utils/request.js`

```js
// ✅ 正确：用封装好的 request
import request from '@/utils/request'
const res = await request.get('/item/list', { params: { page: 1 } })
const res = await request.post('/item/publish', formData)

// ❌ 错误：直接用 axios 或 fetch
import axios from 'axios'
axios.get('/api/item/list')
```

### 4.3 API 接口封装到 `@/api/` 下

```js
// src/api/item.js
import request from '@/utils/request'

export function getItemList(params) {
  return request.get('/item/list', { params })
}

export function getItemDetail(id) {
  return request.get(`/item/${id}`)
}

export function publishItem(data) {
  return request.post('/item/publish', data)
}
```

### 4.4 图标统一用 Element Plus Icons

```vue
<!-- ✅ 正确 -->
<el-icon><Search /></el-icon>
<el-icon><UserFilled /></el-icon>

<!-- ❌ 错误：不要自己找 SVG 或引入其他图标库 -->
<img src="..." />
<i class="iconfont ..." />
```

---

## 五、页面布局规范

### 5.1 需要登录才能看到的页面 → 包一层 `DefaultLayout`

```vue
<template>
  <DefaultLayout>
    <div class="my-page">
      <!-- 你的页面内容 -->
    </div>
  </DefaultLayout>
</template>

<script setup>
import DefaultLayout from '@/components/layout/DefaultLayout.vue'
</script>
```

### 5.2 不需要布局的（登录/注册）→ 直接写

```vue
<template>
  <div class="login-page">
    <!-- 全屏居中登录表单 -->
  </div>
</template>
```

### 5.3 4 个人都要用到 `DefaultLayout`，**不要各写各的导航栏**

---

## 六、命名规则

| 类别 | 规则 | 示例 |
|------|------|------|
| 页面文件名 | PascalCase + Page 后缀 | `HomePage.vue`, `ItemDetailPage.vue` |
| 组件文件名 | PascalCase | `PriceTag.vue`, `UserAvatar.vue` |
| CSS class | kebab-case | `.item-card`, `.price-text` |
| JS 函数 | camelCase | `handleLogin`, `fetchItems` |
| JS 常量 | UPPER_SNAKE | `ORDER_STATUS_MAP` |
| 路由 path | kebab-case | `/item/:id`, `/user/my-items` |

---

## 七、Element Plus 使用约定

| 场景 | 用这个组件 |
|------|-----------|
| 表单 | `el-form` + `el-form-item` + `el-input` |
| 按钮 | `el-button`，主要操作用 `type="primary"` |
| 表格 | `el-table` + `el-table-column` |
| 弹窗 | `el-dialog` |
| 消息提示 | `ElMessage.success()` / `.error()` |
| 确认框 | `ElMessageBox.confirm()` |
| 分页 | `el-pagination` |
| 下拉选择 | `el-select` + `el-option` |
| 标签 | `el-tag`（商品标签用这个） |
| 栅格 | `el-row` + `el-col` |
| 头像 | `el-avatar` |
| 徽标 | `el-badge`（未读消息红点） |
| 输入框 | `el-input`，多行用 `type="textarea"` |

---

## 八、代码审查清单（PR 合并前自查）

- [ ] `<style scoped>` 加了吗？（不然会污染别人的样式）
- [ ] 颜色/字号用的 CSS 变量吗？（不是 hardcode）
- [ ] 发请求走 `@/utils/request.js` 吗？
- [ ] 页面路由在 `router/index.js` 注册了吗？
- [ ] 图片资源放在 `src/assets/` 下了吗？
- [ ] 用过 `ElMessage` 提示成功/失败吗？
- [ ] 按钮加了 `loading` 状态吗？（防止重复提交）

---

## 九、页面分工与文件归属

| 成员 | 模块 | 负责的页面文件（views 下） |
|------|------|--------------------------|
| **A** | 用户认证与成长 | `login/LoginPage.vue`, `login/RegisterPage.vue`, `user/UserProfilePage.vue`, `user/MyItemsPage.vue`, `user/MyFavoritesPage.vue` |
| **B** | AI 内容发布 | `item/PublishItemPage.vue`, `item/ItemDetailPage.vue`（含 AI 审核结果展示） |
| **C** | 大厅与社交 | `home/HomePage.vue`, `item/ItemDetailPage.vue`（收藏、联系卖家部分）, `chat/ChatListPage.vue`, `chat/ChatDetailPage.vue` |
| **D** | 钱包与管理 | `wallet/WalletPage.vue`, `wallet/OrdersBoughtPage.vue`, `wallet/OrdersSoldPage.vue`, `admin/DashboardPage.vue`, `admin/ViolationsPage.vue`, `admin/ChatPage.vue` |

> ⚠️ `ItemDetailPage.vue` 同时被 B 和 C 使用 —— B 负责展示商品信息，C 负责收藏按钮 + 联系卖家按钮。建议 C 把收藏/聊天入口做成独立组件（`FavoriteButton.vue`、`ContactSellerButton.vue`），B 在详情页里引入即可，互不冲突。

---

## 十、启动前端项目

```bash
cd frontend
npm install                # 安装依赖（第一次）
npm run dev                # 启动开发服务器 → http://localhost:3000
```

> 后端先启动（8080 端口），Vite 会将 `/api` 请求自动代理到后端。
