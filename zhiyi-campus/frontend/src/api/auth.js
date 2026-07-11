import request from '@/utils/request'

/** 模块一：认证与用户（负责人 A） */

// —— 认证 ——
export function register(data) {
  return request.post('/auth/register', data)
}

export function login(data) {
  return request.post('/auth/login', data)
}

export function getSecurityQuestion(studentId) {
  return request.get('/auth/security-question', { params: { studentId } })
}

export function getSecurityQuestions() {
  return request.get('/auth/security-questions')
}

export function resetPassword(data) {
  return request.post('/auth/reset-password', data)
}

// —— 用户信息 & 成长体系 ——
export function getProfile() {
  return request.get('/user/profile')
}

export function updateProfile(data) {
  return request.put('/user/profile', data)
}

export function getExpLog(params) {
  return request.get('/user/exp-log', { params })
}

export function getUserCard(userId) {
  return request.get(`/user/${userId}/card`)
}

// —— 账号安全 ——
export function changePassword(data) {
  return request.put('/user/change-password', data)
}

export function cancelAccount(data) {
  return request.post('/user/cancel-account', data)
}
