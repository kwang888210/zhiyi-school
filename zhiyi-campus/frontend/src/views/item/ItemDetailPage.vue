<template>
  <DefaultLayout>
    <div class="detail-page">
      <button class="btn btn--sm" @click="router.back()">返回</button>

      <el-skeleton v-if="loading" :rows="10" animated />

      <template v-else-if="item">
        <section class="detail-grid">
          <div class="gallery">
            <div class="gallery-main" :class="phClass(item.id)">
              <img v-if="activeImage" :src="activeImage" :alt="item.title" />
              <span class="badge gallery-state" :class="item.type === 'BUY' ? 'badge--buy' : 'badge--sell'">
                {{ item.type === 'BUY' ? '求购' : '出售' }}
              </span>
            </div>
            <div v-if="item.images?.length > 1" class="thumbs">
              <button
                v-for="image in item.images"
                :key="image"
                class="thumb"
                :class="{ active: image === activeImage }"
                @click="activeImage = image"
              >
                <img :src="image" :alt="item.title" />
              </button>
            </div>
          </div>

          <div class="info-panel">
            <div class="title-line">
              <h1>{{ item.title }}</h1>
              <span class="badge" :class="statusBadge(item.status)">{{ statusText(item.status) }}</span>
            </div>
            <PriceTag :value="item.price" font-size="34px" />

            <div class="meta-grid">
              <span>分类：{{ item.categoryName || '未分类' }}</span>
              <span>浏览：{{ item.viewCount || 0 }}</span>
              <span>收藏：{{ favoriteCount }}</span>
              <span>发布：{{ formatDate(item.createdAt) }}</span>
            </div>

            <div v-if="item.aiTags?.length" class="tag-row">
              <button
                v-for="tag in item.aiTags"
                :key="tag"
                class="tag"
                @click="goTag(tag)"
              >{{ tag }}</button>
            </div>

            <div class="seller-panel">
              <UserAvatar :nickname="item.publisherNickname || '同学'" :user-id="item.publisherId || 0" size="m" />
              <div>
                <strong>{{ item.publisherNickname || '同学' }}</strong>
                <LevelBadge :level="item.publisherLevel || 1" show-title />
              </div>
            </div>

            <div class="description">
              <h2>商品描述</h2>
              <p>{{ item.description }}</p>
            </div>

            <div v-if="item.tradeLocation" class="location-line">
              交易地点：{{ item.tradeLocation }}
            </div>

            <div class="action-row">
              <template v-if="isOwner">
                <router-link to="/user/my-items" class="btn">管理我的发布</router-link>
              </template>
              <template v-else>
                <button class="btn" :disabled="item.status !== 'ON_SALE' || favoriteLoading" @click="handleFavorite">
                  <el-icon><StarFilled v-if="favorite" /><Star v-else /></el-icon>
                  {{ favorite ? '已收藏' : '收藏' }}
                </button>
                <button class="btn btn--green" :disabled="item.status !== 'ON_SALE' || chatLoading" @click="contactSeller">
                  <el-icon><ChatDotRound /></el-icon>
                  联系卖家
                </button>
                <button class="btn btn--primary" disabled>立即购买</button>
              </template>
            </div>
          </div>
        </section>
      </template>

      <div v-else class="empty-panel">
        <p class="muted">商品不存在或已被删除</p>
        <router-link to="/" class="btn btn--primary">回到大厅</router-link>
      </div>
    </div>
  </DefaultLayout>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { ChatDotRound, Star, StarFilled } from '@element-plus/icons-vue'
import DefaultLayout from '@/components/layout/DefaultLayout.vue'
import LevelBadge from '@/components/common/LevelBadge.vue'
import PriceTag from '@/components/common/PriceTag.vue'
import UserAvatar from '@/components/common/UserAvatar.vue'
import { getItemDetail, toggleFavorite } from '@/api/item'
import { startItemConversation } from '@/api/chat'
import { getUserId, isLoggedIn } from '@/utils/auth'

const STATUS_TEXT = { ON_SALE: '在售中', PENDING: '交易中', SOLD: '已售出', OFF_SHELF: '已下架' }
const STATUS_BADGE = { ON_SALE: 'badge--ok', PENDING: 'badge--warn', SOLD: 'badge--muted', OFF_SHELF: 'badge--muted' }
const PH = ['ph-a', 'ph-b', 'ph-c', 'ph-d', 'ph-e', 'ph-f']

const route = useRoute()
const router = useRouter()
const item = ref(null)
const loading = ref(false)
const favoriteLoading = ref(false)
const chatLoading = ref(false)
const favorite = ref(false)
const favoriteCount = ref(0)
const activeImage = ref('')

const isOwner = computed(() => String(item.value?.publisherId || '') === String(getUserId() || ''))

function phClass(id) {
  return PH[Number(id) % PH.length]
}

function statusText(status) {
  return STATUS_TEXT[status] || status
}

function statusBadge(status) {
  return STATUS_BADGE[status] || 'badge--muted'
}

function formatDate(value) {
  return value ? String(value).replace('T', ' ').slice(0, 16) : ''
}

async function fetchDetail() {
  loading.value = true
  try {
    const res = await getItemDetail(route.params.id)
    item.value = res.data
    activeImage.value = item.value.coverImage || item.value.images?.[0] || ''
    favorite.value = !!item.value.favoriteByCurrentUser
    favoriteCount.value = Number(item.value.favoriteCount || 0)
  } catch {
    item.value = null
  } finally {
    loading.value = false
  }
}

function requireLogin() {
  if (isLoggedIn()) return true
  router.push({ path: '/login', query: { redirect: route.fullPath } })
  return false
}

async function handleFavorite() {
  if (!requireLogin()) return
  favoriteLoading.value = true
  try {
    const res = await toggleFavorite(item.value.id)
    favorite.value = res.data.favorite
    favoriteCount.value = res.data.favoriteCount
    ElMessage.success(favorite.value ? '已收藏' : '已取消收藏')
  } finally {
    favoriteLoading.value = false
  }
}

async function contactSeller() {
  if (!requireLogin()) return
  chatLoading.value = true
  try {
    const res = await startItemConversation(item.value.id)
    router.push({
      name: 'ChatDetail',
      params: { conversationId: res.data.conversationId },
      query: {
        peerId: res.data.peer?.id,
        relatedItemId: res.data.relatedItem?.id,
      },
    })
  } finally {
    chatLoading.value = false
  }
}

function goTag(tag) {
  router.push({ path: '/', query: { keyword: tag } })
}

onMounted(fetchDetail)
</script>

<style scoped>
.detail-page {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
}

.detail-grid {
  display: grid;
  grid-template-columns: minmax(320px, 520px) 1fr;
  gap: var(--spacing-lg);
  align-items: start;
}

.gallery,
.info-panel {
  background: var(--white);
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-m);
  box-shadow: var(--shadow-m);
}

.gallery {
  overflow: hidden;
}

.gallery-main {
  position: relative;
  aspect-ratio: 1 / 1;
}

.gallery-main img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.gallery-state {
  position: absolute;
  top: 14px;
  left: 14px;
}

.thumbs {
  display: flex;
  gap: 8px;
  padding: 12px;
  border-top: var(--bw) solid var(--ink);
  overflow-x: auto;
}

.thumb {
  width: 66px;
  height: 66px;
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-s);
  overflow: hidden;
  background: var(--paper-deep);
  cursor: pointer;
  opacity: .72;
}

.thumb.active {
  opacity: 1;
  box-shadow: var(--shadow-s);
}

.thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.info-panel {
  padding: var(--spacing-lg);
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
}

.title-line {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--spacing-md);
}

.title-line h1 {
  font-size: 28px;
  line-height: 1.25;
}

.meta-grid {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 8px 16px;
  color: var(--ink-soft);
}

.tag-row {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.seller-panel {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: var(--paper-deep);
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-s);
}

.seller-panel strong {
  display: block;
  margin-bottom: 5px;
}

.description {
  display: flex;
  flex-direction: column;
  gap: 8px;
}

.description h2 {
  font-size: 18px;
}

.description p {
  white-space: pre-wrap;
  color: var(--ink-soft);
}

.location-line {
  padding: 10px 12px;
  border: var(--bw) dashed var(--ink);
  border-radius: var(--r-s);
  background: var(--paper);
  font-weight: 700;
}

.action-row {
  display: flex;
  flex-wrap: wrap;
  gap: var(--spacing-sm);
}

.empty-panel {
  min-height: 280px;
  display: grid;
  place-items: center;
  justify-content: center;
  gap: var(--spacing-md);
  background: var(--white);
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-m);
  box-shadow: var(--shadow-m);
}

@media (max-width: 860px) {
  .detail-grid {
    grid-template-columns: 1fr;
  }
}
</style>
