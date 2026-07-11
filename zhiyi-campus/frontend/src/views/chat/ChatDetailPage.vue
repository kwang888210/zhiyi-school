<template>
  <DefaultLayout>
    <div class="chat-detail-page">
      <button class="btn btn--sm" @click="router.push('/chat')">返回消息列表</button>

      <section class="chat-shell rise">
        <div class="chat-pane">
          <header class="chat-pane__head">
            <UserAvatar :nickname="thread?.peer?.nickname || '同学'" :user-id="thread?.peer?.id || 0" size="m" />
            <div>
              <div class="nm">
                {{ thread?.peer?.nickname || '会话' }}
                <LevelBadge :level="thread?.peer?.level || 1" show-title />
              </div>
              <div class="st"><i></i>轮询同步中</div>
            </div>
          </header>

          <router-link
            v-if="thread?.relatedItem"
            class="related-item"
            :to="`/item/${thread.relatedItem.id}`"
          >
            <span class="related-item__thumb" :class="phClass(thread.relatedItem.id)">
              <img v-if="thread.relatedItem.coverImage" :src="thread.relatedItem.coverImage" :alt="thread.relatedItem.title" />
            </span>
            <span class="related-item__info">
              <strong>{{ thread.relatedItem.title }}</strong>
              <PriceTag :value="thread.relatedItem.price" font-size="18px" />
            </span>
            <span class="btn btn--sm btn--primary">查看商品</span>
          </router-link>

          <main ref="messagePanel" class="msg-flow">
            <el-skeleton v-if="loading && !messages.length" :rows="8" animated />
            <template v-else-if="messages.length">
              <span class="msg-day">当前会话</span>
              <div
                v-for="message in messages"
                :key="message.id"
                class="msg"
                :class="message.mine ? 'msg--out' : 'msg--in'"
              >
                <UserAvatar
                  :nickname="message.mine ? '我' : (thread?.peer?.nickname || '同学')"
                  :user-id="message.mine ? 0 : (thread?.peer?.id || 0)"
                  size="s"
                />
                <div>
                  <div class="msg__bubble">{{ message.content }}</div>
                  <div class="msg__time">{{ formatTime(message.createdAt) }}</div>
                </div>
              </div>
            </template>
            <div v-else class="empty-chat">
              <p class="muted">还没有消息，打个招呼吧。</p>
            </div>
          </main>

          <footer class="chat-input">
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
            <button class="btn btn--green" :disabled="sending || !draft.trim()" @click="handleSend">
              发送
            </button>
          </footer>
          <div class="poll-note"><i></i>每 2.5 秒自动刷新新消息</div>
        </div>
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
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-l);
  background: var(--white);
  box-shadow: var(--shadow-l);
  overflow: hidden;
  min-height: 680px;
}

.chat-pane {
  min-height: 680px;
  display: flex;
  flex-direction: column;
  background: var(--paper-deep);
  min-width: 0;
}

.chat-pane__head {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 22px;
  background: var(--white);
  border-bottom: var(--bw) solid var(--ink);
}

.nm {
  font-weight: 900;
  font-size: 16px;
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.st {
  font-size: 12px;
  color: var(--green-deep);
  display: flex;
  align-items: center;
  gap: 5px;
}

.st i,
.poll-note i {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--green);
  display: inline-block;
  border: 1px solid var(--ink);
}

.related-item {
  display: flex;
  align-items: center;
  gap: 12px;
  margin: 14px 22px 0;
  background: var(--white);
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-m);
  padding: 10px 14px;
  box-shadow: var(--shadow-s);
}

.related-item__thumb {
  width: 46px;
  height: 46px;
  border: 1.5px solid var(--ink);
  border-radius: var(--r-s);
  overflow: hidden;
  flex-shrink: 0;
}

.related-item__thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.related-item__info {
  flex: 1;
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.related-item__info strong {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.msg-flow {
  flex: 1;
  overflow-y: auto;
  padding: 20px 22px;
  display: flex;
  flex-direction: column;
  gap: 16px;
}

.msg-day {
  align-self: center;
  font-size: 11.5px;
  font-weight: 700;
  color: var(--ink-soft);
  background: var(--white);
  border: 1.5px solid var(--ink);
  padding: 2px 14px;
  border-radius: 999px;
}

.msg {
  display: flex;
  gap: 10px;
  max-width: 78%;
}

.msg__bubble {
  padding: 10px 15px;
  font-size: 14.5px;
  line-height: 1.6;
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-m);
  background: var(--white);
  box-shadow: 2px 2px 0 var(--ink);
  white-space: pre-wrap;
  word-break: break-word;
}

.msg__time {
  font-size: 11px;
  color: var(--ink-soft);
  margin-top: 4px;
}

.msg--in {
  align-self: flex-start;
}

.msg--in .msg__bubble {
  border-bottom-left-radius: 4px;
}

.msg--out {
  align-self: flex-end;
  flex-direction: row-reverse;
}

.msg--out .msg__bubble {
  background: var(--green);
  color: var(--white);
  border-bottom-right-radius: 4px;
}

.msg--out .msg__time {
  text-align: right;
}

.empty-chat {
  height: 100%;
  display: grid;
  place-items: center;
}

.chat-input {
  display: flex;
  gap: 12px;
  padding: 16px 22px;
  background: var(--white);
  border-top: var(--bw) solid var(--ink);
  align-items: flex-end;
}

.chat-input :deep(.el-textarea__inner) {
  resize: none;
  min-height: 46px !important;
  max-height: 120px;
  padding: 11px 16px;
  font-size: 14.5px;
  font-family: inherit;
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-m);
  background: var(--paper);
  box-shadow: none;
}

.chat-input :deep(.el-textarea__inner:focus) {
  box-shadow: var(--shadow-s);
}

.poll-note {
  text-align: center;
  font-size: 11.5px;
  color: var(--ink-soft);
  background: var(--white);
  padding: 6px 0 8px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
}

@media (max-width: 640px) {
  .chat-shell,
  .chat-pane {
    min-height: 620px;
  }

  .chat-input {
    flex-direction: column;
    align-items: stretch;
  }

  .msg {
    max-width: 92%;
  }
}
</style>
