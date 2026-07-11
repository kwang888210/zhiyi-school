<template>
  <DefaultLayout>
    <div class="chat-list-page">
      <section class="chat-head">
        <div>
          <h1 class="page-title">消息 <span class="stamp">CHAT</span></h1>
          <p class="muted">买卖双方站内沟通，打开会话后自动标记已读。</p>
        </div>
        <button class="btn btn--primary" :disabled="serviceLoading" @click="contactService">
          <el-icon><Service /></el-icon>
          联系客服
        </button>
      </section>

      <el-skeleton v-if="loading" :rows="8" animated />

      <section v-else-if="conversations.length" class="conversation-list">
        <button
          v-for="conversation in conversations"
          :key="conversation.conversationId"
          class="card card--hover conversation-row"
          @click="openConversation(conversation)"
        >
          <UserAvatar
            :nickname="conversation.peer?.nickname || '同学'"
            :user-id="conversation.peer?.id || 0"
            size="m"
          />
          <div class="conversation-main">
            <div class="conversation-title">
              <strong>{{ conversation.peer?.nickname || '同学' }}</strong>
              <LevelBadge :level="conversation.peer?.level || 1" />
              <span class="time">{{ formatTime(conversation.lastMessageTime) }}</span>
            </div>
            <p>{{ conversation.lastMessage }}</p>
            <small v-if="conversation.relatedItem">关联商品：{{ conversation.relatedItem.title }}</small>
          </div>
          <span v-if="conversation.unreadCount > 0" class="unread-dot">{{ conversation.unreadCount }}</span>
        </button>
      </section>

      <div v-else class="empty-panel">
        <p class="muted">还没有聊天记录</p>
        <router-link to="/" class="btn btn--primary">去大厅看看</router-link>
      </div>
    </div>
  </DefaultLayout>
</template>

<script setup>
import { onMounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { Service } from '@element-plus/icons-vue'
import DefaultLayout from '@/components/layout/DefaultLayout.vue'
import LevelBadge from '@/components/common/LevelBadge.vue'
import UserAvatar from '@/components/common/UserAvatar.vue'
import { getConversations, startCustomerService } from '@/api/chat'

const router = useRouter()
const conversations = ref([])
const loading = ref(false)
const serviceLoading = ref(false)

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
  display: flex;
  flex-direction: column;
  gap: var(--spacing-lg);
}

.chat-head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--spacing-md);
}

.conversation-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.conversation-row {
  width: 100%;
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: var(--spacing-md);
  padding: 14px 16px;
  text-align: left;
  color: var(--ink);
}

.conversation-main {
  min-width: 0;
}

.conversation-title {
  display: flex;
  align-items: center;
  gap: 8px;
}

.conversation-title .time {
  margin-left: auto;
  color: var(--ink-soft);
  font-size: 13px;
}

.conversation-main p,
.conversation-main small {
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.conversation-main p {
  margin-top: 4px;
  color: var(--ink-soft);
}

.conversation-main small {
  margin-top: 2px;
  color: var(--green-deep);
}

.unread-dot {
  min-width: 24px;
  height: 24px;
  padding: 0 7px;
  border-radius: 12px;
  display: grid;
  place-items: center;
  border: var(--bw) solid var(--ink);
  background: var(--red);
  color: var(--white);
  font-size: 12px;
  font-weight: 900;
}

.empty-panel {
  min-height: 300px;
  display: grid;
  place-items: center;
  justify-content: center;
  gap: var(--spacing-md);
  background: var(--white);
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-m);
  box-shadow: var(--shadow-m);
}

@media (max-width: 640px) {
  .chat-head {
    align-items: stretch;
    flex-direction: column;
  }

  .conversation-row {
    grid-template-columns: auto 1fr;
  }

  .unread-dot {
    grid-column: 2;
    justify-self: start;
  }
}
</style>
