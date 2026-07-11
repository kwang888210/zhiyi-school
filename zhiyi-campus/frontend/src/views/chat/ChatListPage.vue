<template>
  <DefaultLayout>
    <div class="chat-list-page">
      <section class="chat-shell rise">
        <aside class="conv-list" aria-label="会话列表">
          <div class="conv-list__head">
            <h1>消息</h1>
            <button class="btn btn--primary btn--sm" :disabled="serviceLoading" @click="contactService">
              <el-icon><Service /></el-icon>
              联系客服
            </button>
          </div>

          <div class="conv-search">
            <el-icon><Search /></el-icon>
            <input v-model="keyword" type="search" placeholder="搜索会话…" aria-label="搜索会话">
          </div>

          <el-skeleton v-if="loading" :rows="8" animated />

          <div v-else-if="filteredConversations.length" class="conv-items">
            <button
              v-for="conversation in filteredConversations"
              :key="conversation.conversationId"
              class="conv-item"
              @click="openConversation(conversation)"
            >
              <UserAvatar
                :nickname="conversation.peer?.nickname || '同学'"
                :user-id="conversation.peer?.id || 0"
                size="m"
              />
              <div class="conv-item__body">
                <div class="conv-item__top">
                  <span class="conv-item__name">
                    {{ conversation.peer?.nickname || '同学' }}
                    <LevelBadge :level="conversation.peer?.level || 1" />
                  </span>
                  <span class="conv-item__time">{{ formatTime(conversation.lastMessageTime) }}</span>
                </div>
                <div class="conv-item__preview">{{ conversation.lastMessage }}</div>
                <div v-if="conversation.relatedItem" class="conv-item__goods">关联商品：{{ conversation.relatedItem.title }}</div>
              </div>
              <span v-if="conversation.unreadCount > 0" class="conv-item__unread">{{ conversation.unreadCount }}</span>
            </button>
          </div>

          <div v-else class="conv-empty">
            <p class="muted">还没有聊天记录</p>
            <router-link to="/" class="btn btn--primary btn--sm">去大厅看看</router-link>
          </div>
        </aside>

        <section class="chat-placeholder">
          <h2>选择一个会话</h2>
          <p class="muted">从左侧打开聊天，或联系平台客服。</p>
          <button class="btn btn--yellow" :disabled="serviceLoading" @click="contactService">联系客服</button>
        </section>
      </section>
    </div>
  </DefaultLayout>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Search, Service } from '@element-plus/icons-vue'
import DefaultLayout from '@/components/layout/DefaultLayout.vue'
import LevelBadge from '@/components/common/LevelBadge.vue'
import UserAvatar from '@/components/common/UserAvatar.vue'
import { getConversations, startCustomerService } from '@/api/chat'

const router = useRouter()
const conversations = ref([])
const loading = ref(false)
const serviceLoading = ref(false)
const keyword = ref('')

const filteredConversations = computed(() => {
  const value = keyword.value.trim()
  if (!value) return conversations.value
  return conversations.value.filter((conversation) => {
    return (conversation.peer?.nickname || '').includes(value)
      || (conversation.lastMessage || '').includes(value)
      || (conversation.relatedItem?.title || '').includes(value)
  })
})

function formatTime(value) {
  if (!value) return ''
  const text = String(value).replace('T', ' ')
  return text.slice(5, 16)
}

async function fetchConversations() {
  loading.value = true
  try {
    const res = await getConversations()
    conversations.value = res.data || []
  } finally {
    loading.value = false
  }
}

function openConversation(conversation) {
  router.push({
    name: 'ChatDetail',
    params: { conversationId: conversation.conversationId },
    query: {
      peerId: conversation.peer?.id,
      relatedItemId: conversation.relatedItem?.id,
    },
  })
}

async function contactService() {
  serviceLoading.value = true
  try {
    const res = await startCustomerService()
    router.push({
      name: 'ChatDetail',
      params: { conversationId: res.data.conversationId },
      query: { peerId: res.data.peer?.id },
    })
  } finally {
    serviceLoading.value = false
  }
}

onMounted(fetchConversations)
</script>

<style scoped>
.chat-list-page {
  margin: 4px 0;
}

.chat-shell {
  display: grid;
  grid-template-columns: 360px 1fr;
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-l);
  background: var(--white);
  box-shadow: var(--shadow-l);
  overflow: hidden;
  min-height: 620px;
}

.conv-list {
  border-right: var(--bw) solid var(--ink);
  display: flex;
  flex-direction: column;
  background: var(--paper);
}

.conv-list__head {
  padding: 18px 20px 12px;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
}

.conv-list__head h1 {
  font-family: var(--font-display);
  font-size: 23px;
  letter-spacing: 1px;
}

.conv-search {
  margin: 8px 20px 12px;
  position: relative;
}

.conv-search input {
  width: 100%;
  padding: 9px 14px 9px 36px;
  font-size: 13.5px;
  font-family: inherit;
  border: var(--bw) solid var(--ink);
  border-radius: 999px;
  background: var(--white);
}

.conv-search input:focus {
  outline: none;
  box-shadow: 2px 2px 0 var(--ink);
}

.conv-search .el-icon {
  position: absolute;
  left: 12px;
  top: 50%;
  translate: 0 -50%;
  width: 16px;
  height: 16px;
  color: var(--ink-soft);
}

.conv-items {
  overflow-y: auto;
  flex: 1;
}

.conv-item {
  width: 100%;
  display: flex;
  gap: 12px;
  padding: 13px 20px;
  cursor: pointer;
  border: none;
  border-bottom: 1.5px dashed #E0D6C2;
  background: transparent;
  color: var(--ink);
  text-align: left;
  transition: background .15s;
  position: relative;
}

.conv-item:hover {
  background: var(--paper-deep);
}

.conv-item__body {
  flex: 1;
  min-width: 0;
}

.conv-item__top {
  display: flex;
  justify-content: space-between;
  align-items: baseline;
  gap: 8px;
}

.conv-item__name {
  min-width: 0;
  font-weight: 800;
  font-size: 14.5px;
  display: flex;
  align-items: center;
  gap: 6px;
}

.conv-item__time {
  flex-shrink: 0;
  font-size: 11.5px;
  color: var(--ink-soft);
}

.conv-item__preview,
.conv-item__goods {
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.conv-item__preview {
  font-size: 13px;
  color: var(--ink-soft);
  margin-top: 3px;
}

.conv-item__goods {
  font-size: 12px;
  color: var(--green-deep);
}

.conv-item__unread {
  position: absolute;
  right: 18px;
  bottom: 14px;
  min-width: 19px;
  height: 19px;
  padding: 0 5px;
  border-radius: 10px;
  background: var(--red);
  color: #fff;
  font-size: 11px;
  font-weight: 800;
  display: grid;
  place-items: center;
  border: 1.5px solid var(--ink);
}

.conv-empty,
.chat-placeholder {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: var(--spacing-md);
  min-height: 320px;
  padding: 24px;
  text-align: center;
}

.chat-placeholder {
  background: var(--paper-deep);
}

.chat-placeholder h2 {
  font-family: var(--font-display);
  font-size: 30px;
  letter-spacing: 1px;
}

@media (max-width: 640px) {
  .chat-shell {
    grid-template-columns: 1fr;
  }

  .conv-list {
    border-right: none;
  }

  .chat-placeholder {
    display: none;
  }
}
</style>
