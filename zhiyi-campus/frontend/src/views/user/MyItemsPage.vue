<template>
  <DefaultLayout>
    <div class="my-items-page">
      <h1 class="page-title">我的发布 <span class="stamp">MY POSTS</span></h1>

      <!-- 状态筛选 -->
      <div class="status-tabs">
        <button
          v-for="t in STATUS_TABS" :key="t.value"
          class="btn btn--sm" :class="{ 'btn--dark': statusFilter === t.value }"
          @click="statusFilter = t.value"
        >{{ t.label }}</button>
      </div>

      <template v-if="filteredItems.length">
        <div class="item-list">
          <article v-for="item in filteredItems" :key="item.id" class="card item-row">
            <div class="item-row__thumb" :class="phClass(item.id)">
              <img v-if="mainImage(item)" :src="mainImage(item)" :alt="item.title" />
            </div>
            <div class="item-row__body">
              <div class="item-row__title">
                <span class="badge" :class="item.type === 'BUY' ? 'badge--buy' : 'badge--sell'">
                  {{ item.type === 'BUY' ? '求购' : '出售' }}
                </span>
                <router-link :to="`/item/${item.id}`">{{ item.title }}</router-link>
              </div>
              <div class="item-row__meta muted">
                <span>浏览 {{ item.viewCount ?? 0 }}</span>
                <span>发布于 {{ formatDate(item.createdAt) }}</span>
              </div>
            </div>
            <div class="item-row__price"><PriceTag :value="item.price" /></div>
            <div class="item-row__status">
              <span class="badge" :class="statusBadge(item.status)">{{ statusText(item.status) }}</span>
            </div>
            <div class="item-row__actions">
              <button v-if="item.status === 'ON_SALE'" class="btn btn--sm" :disabled="acting" @click="handleOffShelf(item)">下架</button>
              <button v-if="item.status === 'OFF_SHELF'" class="btn btn--sm btn--green" :disabled="acting" @click="handleRelist(item)">重新上架</button>
              <button v-if="item.status === 'ON_SALE' || item.status === 'OFF_SHELF'" class="btn btn--sm btn--danger" :disabled="acting" @click="handleDelete(item)">删除</button>
            </div>
          </article>
        </div>
        <el-pagination
          v-if="total > pageSize"
          v-model:current-page="page"
          :page-size="pageSize"
          :total="total"
          layout="prev, pager, next"
          @current-change="fetchItems"
        />
      </template>

      <div v-else class="card empty-card">
        <p v-if="loadError" class="muted">{{ loadError }}</p>
        <template v-else>
          <p class="muted">这里还空空如也</p>
          <router-link to="/publish" class="btn btn--primary">去发布第一件闲置 →</router-link>
        </template>
      </div>
    </div>
  </DefaultLayout>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import DefaultLayout from '@/components/layout/DefaultLayout.vue'
import PriceTag from '@/components/common/PriceTag.vue'
import { getMyItems, offShelfItem, relistItem, deleteItem } from '@/api/item'

/**
 * 我的发布（模块一页面归属 A；商品操作接口由 B 提供，按附录 B 契约调用）
 */
const STATUS_TABS = [
  { label: '全部', value: '' },
  { label: '在售中', value: 'ON_SALE' },
  { label: '交易中', value: 'PENDING' },
  { label: '已售出', value: 'SOLD' },
  { label: '已下架', value: 'OFF_SHELF' },
]

const STATUS_TEXT = { ON_SALE: '在售中', PENDING: '交易中', SOLD: '已售出', OFF_SHELF: '已下架' }
const STATUS_BADGE = { ON_SALE: 'badge--ok', PENDING: 'badge--warn', SOLD: 'badge--muted', OFF_SHELF: 'badge--muted' }
const PH = ['ph-a', 'ph-b', 'ph-c', 'ph-d', 'ph-e', 'ph-f']

const items = ref([])
const page = ref(1)
const pageSize = 10
const total = ref(0)
const statusFilter = ref('')
const acting = ref(false)
const loadError = ref('')

const filteredItems = computed(() =>
  statusFilter.value ? items.value.filter((i) => i.status === statusFilter.value) : items.value
)

function statusText(s) { return STATUS_TEXT[s] || s }
function statusBadge(s) { return STATUS_BADGE[s] || 'badge--muted' }
function phClass(id) { return PH[Number(id) % PH.length] }
function formatDate(s) { return s ? String(s).replace('T', ' ').slice(0, 16) : '' }

function mainImage(item) {
  try {
    const arr = typeof item.images === 'string' ? JSON.parse(item.images) : item.images
    return Array.isArray(arr) && arr.length ? arr[0] : ''
  } catch { return '' }
}

async function fetchItems() {
  try {
    const res = await getMyItems({ page: page.value, size: pageSize })
    // 兼容分页对象或纯数组两种返回
    items.value = res.data?.records || res.data || []
    total.value = Number(res.data?.total ?? items.value.length)
    loadError.value = ''
  } catch (e) {
    // B 模块接口未就绪时优雅降级
    loadError.value = '「我的发布」列表接口（模块 B）尚未就绪，联调后即可展示'
  }
}

async function handleOffShelf(item) {
  acting.value = true
  try {
    await offShelfItem(item.id)
    ElMessage.success('已下架')
    fetchItems()
  } catch (e) { /* 提示由 request.js 处理 */ } finally { acting.value = false }
}

async function handleRelist(item) {
  acting.value = true
  try {
    await relistItem(item.id)
    ElMessage.success('已重新上架')
    fetchItems()
  } catch (e) { /* 提示由 request.js 处理 */ } finally { acting.value = false }
}

async function handleDelete(item) {
  try {
    await ElMessageBox.confirm(`确认删除「${item.title}」吗？删除后不可恢复`, '删除商品', {
      confirmButtonText: '删除', cancelButtonText: '取消', type: 'warning',
    })
  } catch { return }
  acting.value = true
  try {
    await deleteItem(item.id)
    ElMessage.success('已删除')
    fetchItems()
  } catch (e) { /* 提示由 request.js 处理 */ } finally { acting.value = false }
}

onMounted(fetchItems)
</script>

<style scoped>
.my-items-page { display: flex; flex-direction: column; gap: var(--spacing-lg); }

.status-tabs { display: flex; gap: 10px; flex-wrap: wrap; }

.item-list { display: flex; flex-direction: column; gap: 14px; }

.item-row {
  display: grid;
  grid-template-columns: 84px 1fr auto auto auto;
  gap: 16px;
  align-items: center;
  padding: 14px 18px;
}
@media (max-width: 768px) {
  .item-row { grid-template-columns: 64px 1fr; }
  .item-row__price, .item-row__status, .item-row__actions { grid-column: 2; justify-self: start; }
}

.item-row__thumb {
  width: 84px;
  height: 84px;
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-s);
  overflow: hidden;
}
.item-row__thumb img { width: 100%; height: 100%; object-fit: cover; }

.item-row__title {
  display: flex;
  align-items: center;
  gap: 8px;
  font-weight: 700;
  font-size: 15px;
}
.item-row__title a:hover { color: var(--primary); }

.item-row__meta { display: flex; gap: 14px; font-size: 13px; margin-top: 6px; }

.item-row__actions { display: flex; gap: 8px; }

.empty-card {
  padding: 48px;
  text-align: center;
  display: flex;
  flex-direction: column;
  gap: 16px;
  align-items: center;
}
</style>
