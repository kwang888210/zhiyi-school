<template>
  <DefaultLayout>
    <div class="chat-detail-page">
      <button class="btn btn--sm" @click="router.push('/chat')">返回消息列表</button>

      <section class="chat-shell">
        <header class="chat-header">
          <div class="peer-line">
            <UserAvatar :nickname="thread?.peer?.nickname || '同学'" :user-id="thread?.peer?.id || 0" size="m" />
            <div>
              <strong>{{ thread?.peer?.nickname || '会话' }}</strong>
              <LevelBadge :level="thread?.peer?.level || 1" show-title />
            </div>
          </div>
          <span class="muted">轮询同步中</span>
        </header>

        <router-link
          v-if="thread?.relatedItem"
          class="related-item"
          :to="`/item/${thread.relatedItem.id}`"
        >
          <span class="related-thumb" :class="phClass(thread.relatedItem.id)">
            <img v-if="thread.relatedItem.coverImage" :src="thread.relatedItem.coverImage" :alt="thread.relatedItem.title" />
          </span>
          <span class="related-info">
            <strong>{{ thread.relatedItem.title }}</strong>
            <PriceTag :value="thread.relatedItem.price" font-size="18px" />
          </span>
        </router-link>

        <main ref="messagePanel" class="message-panel">
          <el-skeleton v-if="loading && !messages.length" :rows="8" animated />
          <template v-else-if="messages.length">
            <div
              v-for="message in messages"
              :key="message.id"
              class="message-row"
              :class="{ mine: message.mine }"
            >
              <div class="message-bubble">
                <p>{{ message.content }}</p>
                <time>{{ formatTime(message.createdAt) }}</time>
              </div>
            </div>
          </template>
          <div v-else class="empty-chat">
            <p class="muted">还没有消息，打个招呼吧。</p>
          </div>
        </main>

        <footer class="composer">
          <el-input
            v-model="draft"
            type="textarea"
            :rows="3"
            maxlength="1000"
            show-word-limit
            resize="none"
            placeholder="输入消息，Enter 发送，Shift + Enter 换行"
            @keydown.enter.exact.prevent="handleSend"
          />
          <button class="btn btn--primary" :disabled="sending || !draft.trim()" @click="handleSend">
            发送
          </button>
        </footer>
      </section>
    </div>
  </DefaultLayout>
</template>

<script setup>
import { nextTick, onMounted, onUnmounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import DefaultLayout from '@/components/layout/DefaultLayout.vue'
import LevelBadge from '@/components/common/LevelBadge.vue'
import PriceTag from '@/components/common/PriceTag.vue'
import UserAvatar from '@/components/common/UserAvatar.vue'
import { getChatMessages, sendChatMessage } from '@/api/chat'

const PH = ['ph-a', 'ph-b', 'ph-c', 'ph-d', 'ph-e', 'ph-f']

const route = useRoute()
const router = useRouter()
const thread = ref(null)
const messages = ref([])
const draft = ref('')
const loading = ref(false)
const sending = ref(false)
const messagePanel = ref(null)
let pollTimer = null

function phClass(id) {
  return PH[Number(id) % PH.length]
}

function formatTime(value) {
  if (!value) return ''
  return String(value).replace('T', ' ').slice(5, 16)
}

function buildParams() {
  const params = { conversationId: route.params.conversationId }
  if (route.query.peerId) params.peerId = Number(route.query.peerId)
  if (route.query.relatedItemId) params.relatedItemId = Number(route.query.relatedItemId)
  return params
}

async function scrollToBottom() {
  await nextTick()
  if (messagePanel.value) {
    messagePanel.value.scrollTop = messagePanel.value.scrollHeight
  }
}

async function fetchThread({ silent = false } = {}) {
  if (!silent) loading.value = true
  try {
    const res = await getChatMessages(buildParams())
    thread.value = res.data
    messages.value = res.data?.messages || []
    await scrollToBottom()
  } finally {
    loading.value = false
  }
}

async function handleSend() {
  if (!draft.value.trim() || !thread.value?.peer?.id) return
  sending.value = true
  try {
    await sendChatMessage({
      conversationId: route.params.conversationId,
      receiverId: thread.value.peer.id,
      relatedItemId: thread.value.relatedItem?.id,
      content: draft.value,
    })
    draft.value = ''
    await fetchThread({ silent: true })
  } finally {
    sending.value = false
  }
}

onMounted(async () => {
  await fetchThread()
  pollTimer = window.setInterval(() => fetchThread({ silent: true }), 2500)
})

onUnmounted(() => {
  if (pollTimer) window.clearInterval(pollTimer)
})
</script>

<style scoped>
.chat-detail-page {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
}

.chat-shell {
  min-height: 680px;
  display: grid;
  grid-template-rows: auto auto minmax(0, 1fr) auto;
  background: var(--white);
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-m);
  box-shadow: var(--shadow-m);
  overflow: hidden;
}

.chat-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  gap: var(--spacing-md);
  padding: var(--spacing-md);
  border-bottom: var(--bw) solid var(--ink);
  background: var(--paper-deep);
}

.peer-line {
  display: flex;
  align-items: center;
  gap: 12px;
}

.peer-line strong {
  display: block;
  margin-bottom: 5px;
}

.related-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px var(--spacing-md);
  border-bottom: var(--bw) solid var(--ink);
  background: var(--paper);
}

.related-thumb {
  width: 54px;
  height: 54px;
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-s);
  overflow: hidden;
  flex-shrink: 0;
}

.related-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.related-info {
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.related-info strong {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.message-panel {
  min-height: 0;
  overflow-y: auto;
  padding: var(--spacing-lg);
  background: var(--paper);
}

.message-row {
  display: flex;
  justify-content: flex-start;
  margin-bottom: 12px;
}

.message-row.mine {
  justify-content: flex-end;
}

.message-bubble {
  max-width: min(620px, 78%);
  padding: 10px 12px;
  background: var(--white);
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-s);
  box-shadow: var(--shadow-s);
}

.message-row.mine .message-bubble {
  background: var(--blue);
  color: var(--white);
}

.message-bubble p {
  white-space: pre-wrap;
  word-break: break-word;
}

.message-bubble time {
  display: block;
  margin-top: 5px;
  font-size: 12px;
  opacity: .72;
  text-align: right;
}

.empty-chat {
  height: 100%;
  display: grid;
  place-items: center;
}

.composer {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: var(--spacing-md);
  align-items: end;
  padding: var(--spacing-md);
  border-top: var(--bw) solid var(--ink);
  background: var(--white);
}

@media (max-width: 640px) {
  .chat-shell {
    min-height: 620px;
  }

  .chat-header,
  .composer {
    grid-template-columns: 1fr;
  }

  .composer {
    display: flex;
    flex-direction: column;
    align-items: stretch;
  }
}
</style>
