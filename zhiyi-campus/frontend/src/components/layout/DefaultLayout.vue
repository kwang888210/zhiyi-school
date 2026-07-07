<template>
  <el-container class="layout">
    <!-- 顶部导航栏 -->
    <el-header class="layout-header">
      <div class="header-left">
        <router-link to="/" class="logo">🎓 智易校园</router-link>
      </div>
      <div class="header-right">
        <template v-if="isLoggedIn()">
          <el-badge :value="unreadCount" :hidden="!unreadCount">
            <router-link to="/chat">
              <el-button type="text">💬 消息</el-button>
            </router-link>
          </el-badge>
          <router-link to="/wallet">
            <el-button type="text">💰 钱包</el-button>
          </router-link>
          <router-link to="/publish">
            <el-button type="primary" size="small">发布</el-button>
          </router-link>
          <el-dropdown>
            <span class="user-dropdown">
              {{ getNickname() }} <el-icon><ArrowDown /></el-icon>
            </span>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item>
                  <router-link to="/user/profile">个人中心</router-link>
                </el-dropdown-item>
                <el-dropdown-item>
                  <router-link to="/user/my-items">我的发布</router-link>
                </el-dropdown-item>
                <el-dropdown-item v-if="isAdmin()">
                  <router-link to="/admin/dashboard">管理后台</router-link>
                </el-dropdown-item>
                <el-dropdown-item divided @click="handleLogout">退出登录</el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </template>
        <template v-else>
          <router-link to="/login">
            <el-button type="text">登录</el-button>
          </router-link>
          <router-link to="/register">
            <el-button type="primary" size="small">注册</el-button>
          </router-link>
        </template>
      </div>
    </el-header>

    <!-- 页面内容 -->
    <el-main class="layout-main">
      <slot />
    </el-main>
  </el-container>
</template>

<script setup>
import { isLoggedIn, isAdmin, getNickname, clearAuth } from '@/utils/auth'
import { useRouter } from 'vue-router'

const router = useRouter()

// 未读消息数（后续接入真实接口）
const unreadCount = 0

function handleLogout() {
  clearAuth()
  router.push('/login')
}
</script>

<style scoped>
.layout {
  min-height: 100vh;
  flex-direction: column;
}

.layout-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  height: 60px;
  background: #fff;
  border-bottom: 1px solid var(--border-color);
  padding: 0 var(--spacing-lg);
  position: sticky;
  top: 0;
  z-index: 100;
}

.logo {
  font-size: var(--font-xl);
  font-weight: 700;
  color: var(--color-primary);
  text-decoration: none;
}

.header-right {
  display: flex;
  align-items: center;
  gap: var(--spacing-md);
}

.user-dropdown {
  cursor: pointer;
  display: flex;
  align-items: center;
  gap: 4px;
}

.layout-main {
  max-width: 1200px;
  width: 100%;
  margin: 0 auto;
  padding: var(--spacing-md);
}

a {
  text-decoration: none;
  color: inherit;
}
</style>
