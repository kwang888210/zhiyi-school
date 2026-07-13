<template>
  <DefaultLayout>
    <div class="detail-page">
      <nav class="crumb" aria-label="面包屑">
        <router-link to="/">交易大厅</router-link>
        <span>/</span>
        <button v-if="item?.categoryName" class="crumb-link" @click="goTag(item.categoryName)">{{ item.categoryName }}</button>
        <span v-if="item?.categoryName">/</span>
        <span>商品详情</span>
      </nav>

      <el-skeleton v-if="loading" :rows="10" animated />

      <template v-else-if="item">
        <section class="detail">
          <div class="gallery">
            <div class="gallery__main" :class="phClass(item.id)">
              <img v-if="activeImage" :src="activeImage" :alt="item.title" />
              <span class="badge gallery-state" :class="item.type === 'BUY' ? 'badge--buy' : 'badge--sell'">
                {{ item.type === 'BUY' ? '求购' : '出售' }}
              </span>
              <button v-if="item.images?.length > 1" class="gallery__nav gallery__nav--prev" aria-label="上一张" @click="switchImage(-1)">‹</button>
              <button v-if="item.images?.length > 1" class="gallery__nav gallery__nav--next" aria-label="下一张" @click="switchImage(1)">›</button>
              <span v-if="item.images?.length" class="gallery__count">{{ activeImageIndex + 1 }} / {{ item.images.length }}</span>
            </div>
            <div v-if="item.images?.length > 1" class="gallery__thumbs">
              <button
                v-for="image in item.images"
                :key="image"
                class="th"
                :class="{ active: image === activeImage }"
                @click="activeImage = image"
              >
                <img :src="image" :alt="item.title" />
              </button>
            </div>
          </div>

          <div class="info-panel rise rise-1">
            <div class="info-head">
              <span class="badge" :class="item.type === 'BUY' ? 'badge--buy' : 'badge--sell'">
                {{ item.type === 'BUY' ? '求购' : '出售' }}
              </span>
              <h1>{{ item.title }}</h1>
              <span class="badge" :class="statusBadge(item.status)">{{ statusText(item.status) }}</span>
            </div>

            <div class="price-strip">
              <PriceTag :value="item.price" font-size="40px" />
              <span class="escrow">平台担保 · 确认收货后打款</span>
            </div>

            <div class="meta-grid">
              <div class="meta-row">
                <span class="lab">智能标签</span>
                <div v-if="item.aiTags?.length" class="ai-tags">
                  <button
                    v-for="tag in item.aiTags"
                    :key="tag"
                    class="tag"
                    @click="goTag(tag)"
                  >{{ tag }}</button>
                </div>
                <span v-else>暂无标签</span>
              </div>
              <div class="meta-row">
                <span class="lab">交易地点</span><strong>{{ item.tradeLocation || '待沟通' }}</strong>
              </div>
              <div class="meta-row">
                <span class="lab">发布时间</span><span>{{ formatDate(item.createdAt) }}</span>
              </div>
              <div class="meta-row">
                <span class="lab">浏览 / 收藏</span><span>{{ item.viewCount || 0 }} 次浏览 · {{ favoriteCount }} 人收藏</span>
              </div>
            </div>

            <div class="seller-card">
              <UserAvatar :nickname="item.publisherNickname || '同学'" :user-id="item.publisherId || 0" size="l" />
              <div class="seller-card__info">
                <div class="seller-card__name">
                  {{ item.publisherNickname || '同学' }}
                  <LevelBadge :level="item.publisherLevel || 1" show-title />
                </div>
                <div class="seller-card__sub">卖家等级已接入成长体系，交易前可先沟通验货细节</div>
                <div class="exp-bar" aria-hidden="true"><i></i></div>
              </div>
            </div>

            <div class="card card--flat desc-block">
              <h2>商品描述</h2>
              <p>{{ item.description }}</p>
            </div>

            <div class="action-bar">
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
            <p class="muted escrow-note">点击“立即购买”后货款将由平台托管，当面验货满意再确认收货</p>
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
const activeImageIndex = computed(() => {
  const images = item.value?.images || []
  const index = images.indexOf(activeImage.value)
  return index >= 0 ? index : 0
})

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

function switchImage(offset) {
  const images = item.value?.images || []
  if (!images.length) return
  const nextIndex = (activeImageIndex.value + offset + images.length) % images.length
  activeImage.value = images[nextIndex]
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
      path: '/chat',
      query: {
        conversationId: res.data.conversationId,
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
  gap: 0;
}

.crumb {
  margin: 0 0 18px;
  font-size: 13.5px;
  color: var(--ink-soft);
  display: flex;
  gap: 8px;
  align-items: center;
}

.crumb a:hover,
.crumb-link:hover {
  color: var(--primary);
  text-decoration: underline;
  text-underline-offset: 3px;
}

.crumb-link {
  border: none;
  background: transparent;
  color: inherit;
  cursor: pointer;
  padding: 0;
}

.detail {
  display: grid;
  grid-template-columns: 460px 1fr;
  gap: 32px;
  align-items: start;
}

.gallery {
  position: sticky;
  top: 84px;
}

.gallery__main {
  position: relative;
  aspect-ratio: 1 / 1;
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-l);
  box-shadow: var(--shadow-m);
  display: grid;
  place-items: center;
  overflow: hidden;
}

.gallery__main img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.gallery-state {
  position: absolute;
  top: 14px;
  left: 14px;
}

.gallery__nav {
  position: absolute;
  top: 50%;
  translate: 0 -50%;
  width: 40px;
  height: 40px;
  border: var(--bw) solid var(--ink);
  border-radius: 50%;
  background: var(--white);
  display: grid;
  place-items: center;
  cursor: pointer;
  box-shadow: 2px 2px 0 var(--ink);
  font-size: 26px;
  line-height: 1;
}

.gallery__nav:hover {
  background: var(--yellow);
}

.gallery__nav--prev { left: 14px; }
.gallery__nav--next { right: 14px; }

.gallery__count {
  position: absolute;
  bottom: 12px;
  right: 14px;
  padding: 3px 12px;
  background: var(--ink);
  color: var(--paper);
  border-radius: 999px;
  font-size: 12.5px;
  font-weight: 700;
}

.gallery__thumbs {
  display: flex;
  gap: 10px;
  margin-top: 14px;
  overflow-x: auto;
}

.th {
  width: 68px;
  height: 68px;
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-s);
  overflow: hidden;
  background: var(--paper-deep);
  cursor: pointer;
  opacity: .55;
  transition: all .15s;
}

.th:hover {
  opacity: .85;
}

.th.active {
  opacity: 1;
  box-shadow: 3px 3px 0 var(--ink);
  transform: translate(-1px, -1px);
}

.th img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.info-head {
  display: flex;
  align-items: flex-start;
  gap: 12px;
}

.info-head h1 {
  font-size: 26px;
  font-weight: 900;
  line-height: 1.4;
  flex: 1;
}

.price-strip {
  margin: 18px 0;
  padding: 16px 22px;
  display: flex;
  align-items: baseline;
  gap: 16px;
  flex-wrap: wrap;
  background: var(--white);
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-m);
  box-shadow: var(--shadow-s);
}

.escrow {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 13px;
  font-weight: 700;
  color: var(--green-deep);
  background: #D6F2DF;
  border: 1.5px solid var(--green);
  padding: 4px 12px;
  border-radius: 999px;
}

.meta-grid {
  display: flex;
  flex-direction: column;
  gap: 10px;
  font-size: 14.5px;
  margin-bottom: 20px;
}

.meta-row {
  display: flex;
  align-items: center;
  gap: 10px;
}

.meta-row .lab {
  color: var(--ink-soft);
  min-width: 68px;
}

.ai-tags {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.seller-card {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 16px 18px;
  margin: 22px 0;
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-m);
  background: var(--paper-deep);
}

.seller-card__info {
  flex: 1;
  min-width: 0;
}

.seller-card__name {
  font-weight: 900;
  font-size: 16px;
  display: flex;
  align-items: center;
  gap: 8px;
  flex-wrap: wrap;
}

.seller-card__sub {
  font-size: 12.5px;
  color: var(--ink-soft);
  margin-top: 2px;
}

.exp-bar {
  margin-top: 7px;
  height: 10px;
  border: 1.5px solid var(--ink);
  border-radius: 6px;
  background: var(--white);
  overflow: hidden;
  max-width: 220px;
}

.exp-bar i {
  display: block;
  height: 100%;
  width: 62%;
  background: repeating-linear-gradient(-45deg, var(--green) 0 8px, #4FBF82 8px 16px);
}

.desc-block {
  padding: 22px 24px;
  margin-bottom: 24px;
}

.desc-block h2 {
  font-family: var(--font-display);
  font-size: 20px;
  letter-spacing: 1px;
  margin-bottom: 10px;
}

.desc-block p {
  font-size: 15px;
  line-height: 1.9;
  color: #3D372E;
  white-space: pre-wrap;
}

.action-bar {
  display: flex;
  flex-wrap: wrap;
  gap: 14px;
}

.action-bar .btn {
  flex: 1;
  min-width: 150px;
}

.escrow-note {
  font-size: 12.5px;
  margin-top: 12px;
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
  .detail {
    grid-template-columns: 1fr;
  }

  .gallery {
    position: static;
  }
}
</style>
