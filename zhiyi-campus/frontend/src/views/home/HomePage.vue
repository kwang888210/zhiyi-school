<template>
  <DefaultLayout>
    <div class="home-page">
      <section class="hall-head">
        <div>
          <h1 class="page-title">商品大厅 <span class="stamp">MARKET</span></h1>
          <p class="muted">按分类、价格和关键词快速找到校园里的靠谱闲置。</p>
        </div>
        <router-link to="/publish" class="btn btn--primary">发布闲置</router-link>
      </section>

      <section class="filter-panel">
        <div class="search-line">
          <el-input
            v-model="filters.keyword"
            clearable
            size="large"
            placeholder="搜索商品标题、描述或 AI 标签"
            @keyup.enter="handleSearch"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
          <button class="btn btn--primary" :disabled="loading" @click="handleSearch">
            <el-icon><Search /></el-icon>
            搜索
          </button>
          <button class="btn" :disabled="loading" @click="resetFilters">
            <el-icon><RefreshRight /></el-icon>
            重置
          </button>
        </div>

        <div class="category-row" aria-label="商品分类">
          <button
            class="category-pill"
            :class="{ active: !filters.categoryId }"
            @click="selectCategory('')"
          >全部</button>
          <button
            v-for="category in categories"
            :key="category.id"
            class="category-pill"
            :class="{ active: filters.categoryId === category.id }"
            @click="selectCategory(category.id)"
          >
            <span>{{ category.icon }}</span>{{ category.name }}
          </button>
        </div>

        <div class="advanced-row">
          <el-select v-model="filters.type" placeholder="类型" clearable>
            <el-option label="出售" value="SELL" />
            <el-option label="求购" value="BUY" />
          </el-select>
          <el-input-number v-model="filters.minPrice" :min="0" :precision="2" placeholder="最低价" />
          <span class="muted">至</span>
          <el-input-number v-model="filters.maxPrice" :min="0" :precision="2" placeholder="最高价" />
          <el-select v-model="filters.sort" placeholder="排序">
            <el-option label="智能乱序" value="random" />
            <el-option label="最新发布" value="latest" />
            <el-option label="价格从低到高" value="priceAsc" />
            <el-option label="价格从高到低" value="priceDesc" />
            <el-option label="浏览最多" value="views" />
          </el-select>
        </div>
      </section>

      <div class="content-grid">
        <main class="market-main">
          <div class="result-bar">
            <span class="muted">共 {{ total }} 件在售</span>
            <button class="btn btn--sm" :disabled="loading" @click="fetchItems">
              <el-icon><RefreshRight /></el-icon>
              换一批
            </button>
          </div>

          <el-skeleton v-if="loading && !items.length" :rows="8" animated />

          <div v-else-if="items.length" class="item-grid">
            <article
              v-for="item in items"
              :key="item.id"
              class="card card--hover item-card"
              @click="goDetail(item.id)"
            >
              <div class="item-card__image" :class="phClass(item.id)">
                <img v-if="item.coverImage" :src="item.coverImage" :alt="item.title" />
                <span class="badge item-card__type" :class="item.type === 'BUY' ? 'badge--buy' : 'badge--sell'">
                  {{ item.type === 'BUY' ? '求购' : '出售' }}
                </span>
              </div>
              <div class="item-card__body">
                <h2>{{ item.title }}</h2>
                <div class="item-card__meta">
                  <PriceTag :value="item.price" font-size="22px" />
                  <span class="muted">{{ item.categoryName || '未分类' }}</span>
                </div>
                <div class="seller-line">
                  <span class="seller-name">{{ item.publisherNickname || '同学' }}</span>
                  <LevelBadge :level="item.publisherLevel || 1" />
                </div>
                <div class="item-card__stats">
                  <span><el-icon><Star /></el-icon>{{ item.favoriteCount || 0 }}</span>
                  <span><el-icon><View /></el-icon>{{ item.viewCount || 0 }}</span>
                  <button
                    class="fav-button"
                    :class="{ active: item.favoriteByCurrentUser }"
                    :disabled="favoriteBusyId === item.id"
                    @click.stop="handleFavorite(item)"
                    :title="item.favoriteByCurrentUser ? '取消收藏' : '收藏商品'"
                  >
                    <el-icon><StarFilled v-if="item.favoriteByCurrentUser" /><Star v-else /></el-icon>
                  </button>
                </div>
              </div>
            </article>
          </div>

          <div v-else class="empty-panel">
            <p class="muted">未找到相关商品</p>
            <button class="btn btn--primary" @click="resetFilters">清空筛选</button>
          </div>

          <el-pagination
            v-if="total > pageSize"
            v-model:current-page="page"
            :page-size="pageSize"
            :total="total"
            layout="prev, pager, next"
            @current-change="fetchItems"
          />
        </main>

        <aside class="ranking-panel" aria-label="近期爆款榜单">
          <div class="ranking-title">
            <h2>近期爆款</h2>
            <span class="badge badge--warn">TOP 10</span>
          </div>
          <div v-if="ranking.length" class="ranking-list">
            <button
              v-for="(item, index) in ranking"
              :key="item.id"
              class="ranking-row"
              @click="goDetail(item.id)"
            >
              <span class="rank-no" :class="`rank-${index + 1}`">{{ index + 1 }}</span>
              <span class="ranking-thumb" :class="phClass(item.id)">
                <img v-if="item.coverImage" :src="item.coverImage" :alt="item.title" />
              </span>
              <span class="ranking-info">
                <strong>{{ item.title }}</strong>
                <small>{{ item.favoriteCount || 0 }} 人收藏</small>
              </span>
            </button>
          </div>
          <p v-else class="muted ranking-empty">暂无榜单数据</p>
        </aside>
      </div>
    </div>
  </DefaultLayout>
</template>

<script setup>
import { onMounted, reactive, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { RefreshRight, Search, Star, StarFilled, View } from '@element-plus/icons-vue'
import DefaultLayout from '@/components/layout/DefaultLayout.vue'
import LevelBadge from '@/components/common/LevelBadge.vue'
import PriceTag from '@/components/common/PriceTag.vue'
import { getCategories, getItemList, getItemRanking, toggleFavorite } from '@/api/item'
import { isLoggedIn } from '@/utils/auth'

const PH = ['ph-a', 'ph-b', 'ph-c', 'ph-d', 'ph-e', 'ph-f']

const router = useRouter()
const route = useRoute()
const categories = ref([])
const items = ref([])
const ranking = ref([])
const page = ref(1)
const pageSize = 12
const total = ref(0)
const loading = ref(false)
const favoriteBusyId = ref(null)

const filters = reactive({
  keyword: '',
  categoryId: '',
  minPrice: undefined,
  maxPrice: undefined,
  type: '',
  sort: 'random',
})

function phClass(id) {
  return PH[Number(id) % PH.length]
}

function buildParams() {
  const params = { page: page.value, size: pageSize, sort: filters.sort }
  if (filters.keyword?.trim()) params.keyword = filters.keyword.trim()
  if (filters.categoryId) params.categoryId = filters.categoryId
  if (filters.minPrice !== undefined && filters.minPrice !== null) params.minPrice = filters.minPrice
  if (filters.maxPrice !== undefined && filters.maxPrice !== null) params.maxPrice = filters.maxPrice
  if (filters.type) params.type = filters.type
  return params
}

async function fetchCategories() {
  const res = await getCategories()
  categories.value = res.data || []
}

async function fetchRanking() {
  const res = await getItemRanking({ limit: 10 })
  ranking.value = res.data || []
}

async function fetchItems() {
  loading.value = true
  try {
    const res = await getItemList(buildParams())
    items.value = res.data?.records || []
    total.value = Number(res.data?.total || 0)
  } finally {
    loading.value = false
  }
}

function handleSearch() {
  page.value = 1
  fetchItems()
}

function resetFilters() {
  filters.keyword = ''
  filters.categoryId = ''
  filters.minPrice = undefined
  filters.maxPrice = undefined
  filters.type = ''
  filters.sort = 'random'
  page.value = 1
  fetchItems()
}

function selectCategory(id) {
  filters.categoryId = id
  handleSearch()
}

function goDetail(id) {
  router.push(`/item/${id}`)
}

async function handleFavorite(item) {
  if (!isLoggedIn()) {
    router.push({ path: '/login', query: { redirect: '/' } })
    return
  }
  favoriteBusyId.value = item.id
  try {
    const res = await toggleFavorite(item.id)
    item.favoriteByCurrentUser = res.data.favorite
    item.favoriteCount = res.data.favoriteCount
    ElMessage.success(res.data.favorite ? '已收藏' : '已取消收藏')
    fetchRanking()
  } finally {
    favoriteBusyId.value = null
  }
}

watch(() => filters.sort, handleSearch)
watch(() => filters.type, handleSearch)

onMounted(async () => {
  if (route.query.keyword) {
    filters.keyword = String(route.query.keyword)
  }
  await Promise.all([fetchCategories(), fetchItems(), fetchRanking()])
})
</script>

<style scoped>
.home-page {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-lg);
}

.hall-head {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  gap: var(--spacing-md);
}

.filter-panel {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
  padding: var(--spacing-md);
  background: var(--white);
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-m);
  box-shadow: var(--shadow-m);
}

.search-line,
.advanced-row,
.category-row,
.result-bar {
  display: flex;
  align-items: center;
  gap: var(--spacing-sm);
}

.search-line .el-input {
  flex: 1;
}

.category-row {
  flex-wrap: wrap;
}

.category-pill {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  border: var(--bw) solid var(--ink);
  background: var(--paper-deep);
  color: var(--ink);
  border-radius: 999px;
  padding: 7px 14px;
  cursor: pointer;
  font-weight: 700;
  transition: transform .15s, box-shadow .15s, background-color .15s;
}

.category-pill:hover,
.category-pill.active {
  background: var(--yellow);
  box-shadow: var(--shadow-s);
  transform: translate(-1px, -1px);
}

.advanced-row {
  flex-wrap: wrap;
}

.content-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 280px;
  gap: var(--spacing-lg);
  align-items: start;
}

.market-main {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
}

.result-bar {
  justify-content: space-between;
}

.item-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(210px, 1fr));
  gap: var(--spacing-md);
}

.item-card {
  overflow: hidden;
}

.item-card__image {
  position: relative;
  aspect-ratio: 1 / 1;
  border-bottom: var(--bw) solid var(--ink);
}

.item-card__image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.item-card__type {
  position: absolute;
  top: 10px;
  left: 10px;
}

.item-card__body {
  padding: 13px 14px 14px;
  display: flex;
  flex-direction: column;
  gap: 9px;
}

.item-card h2 {
  font-size: 15px;
  line-height: 1.45;
  min-height: 43px;
  overflow: hidden;
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
}

.item-card__meta,
.seller-line,
.item-card__stats {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--spacing-sm);
}

.seller-name {
  font-weight: 700;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.item-card__stats span {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  color: var(--ink-soft);
  font-size: 13px;
}

.fav-button {
  width: 34px;
  height: 34px;
  display: grid;
  place-items: center;
  border: var(--bw) solid var(--ink);
  border-radius: 50%;
  background: var(--white);
  cursor: pointer;
}

.fav-button.active {
  background: var(--yellow);
}

.ranking-panel {
  position: sticky;
  top: 84px;
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
  padding: var(--spacing-md);
  background: var(--paper-deep);
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-m);
  box-shadow: var(--shadow-m);
}

.ranking-title {
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.ranking-title h2 {
  font-family: var(--font-display);
  font-size: 25px;
}

.ranking-list {
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.ranking-row {
  display: grid;
  grid-template-columns: 30px 46px 1fr;
  align-items: center;
  gap: 10px;
  text-align: left;
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-s);
  background: var(--white);
  padding: 8px;
  cursor: pointer;
}

.rank-no {
  width: 26px;
  height: 26px;
  display: grid;
  place-items: center;
  border: var(--bw) solid var(--ink);
  border-radius: 50%;
  background: var(--paper-deep);
  font-weight: 900;
}

.rank-1 { background: var(--yellow); }
.rank-2 { background: var(--paper); }
.rank-3 { background: var(--primary); color: var(--white); }

.ranking-thumb {
  width: 46px;
  height: 46px;
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-s);
  overflow: hidden;
}

.ranking-thumb img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.ranking-info {
  min-width: 0;
  display: flex;
  flex-direction: column;
}

.ranking-info strong {
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  font-size: 13px;
}

.ranking-info small,
.ranking-empty {
  color: var(--ink-soft);
}

.empty-panel {
  min-height: 260px;
  display: grid;
  place-items: center;
  gap: var(--spacing-md);
  justify-content: center;
  background: var(--white);
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-m);
  box-shadow: var(--shadow-m);
}

@media (max-width: 980px) {
  .content-grid {
    grid-template-columns: 1fr;
  }

  .ranking-panel {
    position: static;
  }
}

@media (max-width: 680px) {
  .hall-head,
  .search-line,
  .advanced-row {
    align-items: stretch;
    flex-direction: column;
  }
}
</style>
