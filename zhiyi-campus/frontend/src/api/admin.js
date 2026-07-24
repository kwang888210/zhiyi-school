import request from '@/utils/request'

/** 超管控制台接口（D 负责） */

/** 数据大盘 */
export function getDashboard() {
  return request.get('/admin/dashboard')
}

/** 违规审核列表 */
export function getViolations(params) {
  return request.get('/admin/violations', { params })
}

/** 确认违规并封禁 */
export function confirmViolation(id, data) {
  return request.put(`/admin/violations/${id}/confirm`, data)
}

/** 驳回违规（放行商品） */
export function dismissViolation(id) {
  return request.put(`/admin/violations/${id}/dismiss`)
}

/** 用户搜索（封禁弹窗选人） */
export function searchUsers(params) {
  return request.get('/admin/users', { params })
}

/** 封禁用户 */
export function banUser(data) {
  return request.post('/admin/ban-user', data)
}

/** 解封用户 */
export function unbanUser(data) {
  return request.post('/admin/unban-user', data)
}

/** 管理员商品检索（4.7 强制下架前选择商品用） */
export function searchAdminItems(params) {
  return request.get('/admin/items', { params })
}

/** 强制下架商品 */
export function forceOffShelf(itemId) {
  return request.put(`/admin/item/${itemId}/force-off-shelf`)
}

/** 强制重置密码 */
export function resetUserPassword(data) {
  return request.post('/admin/reset-password', data)
}

/** 客服会话列表 */
export function getAdminSessions() {
  return request.get('/admin/chat/sessions')
}

/** 分类管理 */
export function getAdminCategories() {
  return request.get('/admin/categories')
}

export function createCategory(data) {
  return request.post('/admin/categories', data)
}

export function updateCategory(id, data) {
  return request.put(`/admin/categories/${id}`, data)
}

export function deleteCategory(id) {
  return request.delete(`/admin/categories/${id}`)
}
