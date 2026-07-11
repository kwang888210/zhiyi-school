import request from '@/utils/request'

/** 商品相关接口（B/C 负责后端；A 的「我的发布/我的收藏」页面按附录B契约调用） */

export function getItemList(params) {
  return request.get('/item/list', { params })
}

export function getItemDetail(id) {
  return request.get(`/item/${id}`)
}

export function getMyItems(params) {
  return request.get('/item/my-items', { params })
}

export function getMyFavorites(params) {
  return request.get('/item/my-favorites', { params })
}

export function toggleFavorite(id) {
  return request.post(`/item/${id}/favorite`)
}

export function offShelfItem(id) {
  return request.put(`/item/${id}/off-shelf`)
}

export function relistItem(id) {
  return request.put(`/item/${id}/relist`)
}

export function deleteItem(id) {
  return request.delete(`/item/${id}`)
}
