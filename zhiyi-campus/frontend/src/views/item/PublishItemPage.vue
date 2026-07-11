<template>
  <DefaultLayout>
    <div class="publish-page">
      <section class="publish-head">
        <div>
          <h1 class="page-title">发布闲置 <span class="stamp">POST</span></h1>
          <p class="muted">填写真实信息，图片上传后会自动出现在商品大厅。</p>
        </div>
        <router-link to="/user/my-items" class="btn">我的发布</router-link>
      </section>

      <section class="publish-grid">
        <el-form
          ref="formRef"
          class="card publish-form"
          :model="form"
          :rules="rules"
          label-position="top"
        >
          <el-form-item label="发布类型" prop="type">
            <el-radio-group v-model="form.type">
              <el-radio-button label="SELL">我要出闲置</el-radio-button>
              <el-radio-button label="BUY">我要求购</el-radio-button>
            </el-radio-group>
          </el-form-item>

          <el-form-item label="商品标题" prop="title">
            <el-input v-model.trim="form.title" maxlength="50" show-word-limit placeholder="例如：99新 iPad Air5 考研结束出" />
          </el-form-item>

          <el-form-item label="所属大类" prop="categoryId">
            <el-select v-model="form.categoryId" placeholder="选择一个大类" filterable>
              <el-option
                v-for="category in categories"
                :key="category.id"
                :label="`${category.icon || ''} ${category.name}`"
                :value="category.id"
              />
            </el-select>
          </el-form-item>

          <div class="form-row">
            <el-form-item label="价格" prop="price">
              <el-input-number v-model="form.price" :min="0.01" :precision="2" :step="1" />
            </el-form-item>
            <el-form-item label="交易地点" prop="tradeLocation">
              <el-input v-model.trim="form.tradeLocation" maxlength="255" placeholder="图书馆门口 / 食堂三楼" />
            </el-form-item>
          </div>

          <el-form-item label="商品描述" prop="description">
            <el-input
              v-model.trim="form.description"
              type="textarea"
              :rows="6"
              maxlength="500"
              show-word-limit
              placeholder="说明成色、购入时间、配件、交易方式等"
            />
          </el-form-item>

          <el-form-item label="商品图片" prop="images">
            <div class="upload-zone">
              <el-upload
                :auto-upload="false"
                :show-file-list="false"
                accept=".jpg,.jpeg,.png,.webp,image/jpeg,image/png,image/webp"
                :on-change="handleFileChange"
              >
                <button class="btn" type="button" :disabled="uploading || form.images.length >= 9">
                  <el-icon><UploadFilled /></el-icon>
                  上传图片
                </button>
              </el-upload>
              <span class="muted">至少 1 张，最多 9 张，单张不超过 5MB</span>
            </div>

            <div v-if="form.images.length" class="image-list">
              <div v-for="(image, index) in form.images" :key="image" class="image-tile">
                <img :src="image" :alt="`商品图${index + 1}`" />
                <span v-if="index === 0" class="badge badge--warn cover-badge">封面</span>
                <button class="remove-btn" type="button" title="删除图片" @click="removeImage(index)">
                  <el-icon><Close /></el-icon>
                </button>
              </div>
            </div>
          </el-form-item>

          <div class="submit-row">
            <button class="btn btn--primary btn--lg" type="button" :disabled="submitting" @click="handleSubmit">
              <el-icon><CircleCheck /></el-icon>
              发布到大厅
            </button>
          </div>
        </el-form>

        <aside class="card tips-panel">
          <h2>发布检查</h2>
          <ul>
            <li :class="{ done: form.type }">选择出售或求购</li>
            <li :class="{ done: form.title.length >= 2 }">标题清楚，不超过 50 字</li>
            <li :class="{ done: form.categoryId }">选择固定大类</li>
            <li :class="{ done: form.images.length > 0 }">上传至少一张实物图</li>
            <li :class="{ done: form.description.length >= 10 }">描述尽量具体</li>
          </ul>
          <p class="muted">提交时会进行本地规则审核并自动生成搜索标签。明显违规内容会被拦截并写入违规上报记录。</p>
        </aside>
      </section>
    </div>
  </DefaultLayout>
</template>

<script setup>
import { onMounted, reactive, ref } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { CircleCheck, Close, UploadFilled } from '@element-plus/icons-vue'
import DefaultLayout from '@/components/layout/DefaultLayout.vue'
import { getCategories, publishItem, uploadItemImage } from '@/api/item'

const MAX_IMAGE_SIZE = 5 * 1024 * 1024
const IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp']

const router = useRouter()
const formRef = ref(null)
const categories = ref([])
const uploading = ref(false)
const submitting = ref(false)
const form = reactive({
  type: 'SELL',
  title: '',
  description: '',
  categoryId: '',
  price: 1,
  images: [],
  tradeLocation: '',
})

const rules = {
  type: [{ required: true, message: '请选择发布类型', trigger: 'change' }],
  title: [
    { required: true, message: '请输入商品标题', trigger: 'blur' },
    { min: 2, max: 50, message: '标题需为2-50字', trigger: 'blur' },
  ],
  categoryId: [{ required: true, message: '请选择所属大类', trigger: 'change' }],
  price: [{ required: true, type: 'number', min: 0.01, message: '请输入有效价格', trigger: 'change' }],
  tradeLocation: [{ required: true, message: '请输入交易地点', trigger: 'blur' }],
  description: [
    { required: true, message: '请输入商品描述', trigger: 'blur' },
    { min: 10, max: 500, message: '描述需为10-500字', trigger: 'blur' },
  ],
  images: [{ type: 'array', required: true, min: 1, message: '请至少上传1张图片', trigger: 'change' }],
}

async function fetchCategories() {
  const res = await getCategories()
  categories.value = res.data || []
}

function validateImage(file) {
  if (!IMAGE_TYPES.includes(file.type)) {
    ElMessage.error('仅支持 jpg、png、webp 图片')
    return false
  }
  if (file.size > MAX_IMAGE_SIZE) {
    ElMessage.error('单张图片不能超过 5MB')
    return false
  }
  if (form.images.length >= 9) {
    ElMessage.error('最多上传 9 张图片')
    return false
  }
  return true
}

async function handleFileChange(uploadFile) {
  const file = uploadFile.raw
  if (!file || !validateImage(file)) return
  uploading.value = true
  try {
    const res = await uploadItemImage(file)
    form.images.push(res.data.url)
    formRef.value?.validateField('images')
    ElMessage.success('图片上传成功')
  } finally {
    uploading.value = false
  }
}

function removeImage(index) {
  form.images.splice(index, 1)
  formRef.value?.validateField('images')
}

async function handleSubmit() {
  await formRef.value.validate()
  submitting.value = true
  try {
    const res = await publishItem({
      type: form.type,
      title: form.title,
      description: form.description,
      categoryId: form.categoryId,
      price: form.price,
      images: form.images,
      tradeLocation: form.tradeLocation,
    })
    ElMessage.success('发布成功，已进入商品大厅')
    router.push(`/item/${res.data.id}`)
  } finally {
    submitting.value = false
  }
}

onMounted(fetchCategories)
</script>

<style scoped>
.publish-page {
  display: flex;
  flex-direction: column;
  gap: var(--spacing-lg);
}

.publish-head {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: var(--spacing-md);
}

.publish-grid {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 300px;
  gap: var(--spacing-lg);
  align-items: start;
}

.publish-form {
  padding: var(--spacing-lg);
}

.form-row {
  display: grid;
  grid-template-columns: 220px 1fr;
  gap: var(--spacing-md);
}

.upload-zone {
  display: flex;
  align-items: center;
  gap: var(--spacing-md);
  flex-wrap: wrap;
}

.image-list {
  width: 100%;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(110px, 1fr));
  gap: var(--spacing-sm);
  margin-top: var(--spacing-md);
}

.image-tile {
  position: relative;
  aspect-ratio: 1 / 1;
  border: var(--bw) solid var(--ink);
  border-radius: var(--r-s);
  overflow: hidden;
  background: var(--paper-deep);
}

.image-tile img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.cover-badge {
  position: absolute;
  top: 6px;
  left: 6px;
}

.remove-btn {
  position: absolute;
  top: 6px;
  right: 6px;
  width: 28px;
  height: 28px;
  display: grid;
  place-items: center;
  border: var(--bw) solid var(--ink);
  border-radius: 50%;
  background: var(--white);
  color: var(--ink);
  cursor: pointer;
}

.submit-row {
  display: flex;
  justify-content: flex-end;
  margin-top: var(--spacing-lg);
}

.tips-panel {
  position: sticky;
  top: 84px;
  padding: var(--spacing-lg);
  display: flex;
  flex-direction: column;
  gap: var(--spacing-md);
  background: var(--paper-deep);
}

.tips-panel h2 {
  font-family: var(--font-display);
  font-size: 26px;
}

.tips-panel ul {
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 10px;
}

.tips-panel li {
  padding-left: 24px;
  position: relative;
  color: var(--ink-soft);
}

.tips-panel li::before {
  content: '';
  position: absolute;
  left: 0;
  top: 9px;
  width: 12px;
  height: 12px;
  border: var(--bw) solid var(--ink);
  border-radius: 50%;
  background: var(--white);
}

.tips-panel li.done {
  color: var(--ink);
  font-weight: 700;
}

.tips-panel li.done::before {
  background: var(--green);
}

@media (max-width: 920px) {
  .publish-grid {
    grid-template-columns: 1fr;
  }

  .tips-panel {
    position: static;
  }
}

@media (max-width: 680px) {
  .publish-head,
  .form-row {
    grid-template-columns: 1fr;
    flex-direction: column;
    align-items: stretch;
  }
}
</style>
