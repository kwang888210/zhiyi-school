import request from '@/utils/request'

/** 订单相关接口（D 负责） */

export function createOrder(itemId) {
  return request.post('/order/create', { itemId })
}

export function confirmReceipt(orderId) {
  return request.put(`/order/${orderId}/confirm`)
}

export function cancelOrder(orderId) {
  return request.put(`/order/${orderId}/cancel`)
}

export function getBoughtOrders(params) {
  return request.get('/order/my-bought', { params })
}

export function getSoldOrders(params) {
  return request.get('/order/my-sold', { params })
}
