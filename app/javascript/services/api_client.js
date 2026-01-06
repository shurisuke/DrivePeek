// app/javascript/services/api_client.js
// ================================================================
// API Client（単一責務）
// 用途: Rails API への HTTP リクエストを共通化
//   - CSRF トークンの取得
//   - JSON リクエスト/レスポンスの処理
//   - エラーハンドリング
// ================================================================

/**
 * CSRF トークンを取得
 */
export const getCsrfToken = () => {
  const meta = document.querySelector('meta[name="csrf-token"]')
  return meta?.getAttribute("content") || ""
}

/**
 * 共通のリクエストヘッダーを生成
 */
const buildHeaders = (options = {}) => {
  const headers = {
    "Content-Type": "application/json",
    "X-CSRF-Token": getCsrfToken(),
    Accept: "application/json",
    ...options.headers,
  }
  return headers
}

/**
 * API リクエストを実行
 * @param {string} url - リクエスト先 URL
 * @param {object} options - fetch オプション
 * @returns {Promise<object>} - JSON レスポンス
 * @throws {Error} - リクエスト失敗時
 */
export const apiRequest = async (url, options = {}) => {
  const config = {
    credentials: "same-origin",
    ...options,
    headers: buildHeaders(options),
  }

  const res = await fetch(url, config)

  if (!res.ok) {
    const err = await res.json().catch(() => ({}))
    const message = err.message || err.errors?.join(", ") || `Request failed: ${res.status}`
    throw new Error(message)
  }

  // 204 No Content の場合は null を返す
  if (res.status === 204) {
    return null
  }

  return res.json()
}

/**
 * GET リクエスト
 */
export const get = (url, options = {}) => {
  return apiRequest(url, { ...options, method: "GET" })
}

/**
 * POST リクエスト
 */
export const post = (url, body, options = {}) => {
  return apiRequest(url, {
    ...options,
    method: "POST",
    body: JSON.stringify(body),
  })
}

/**
 * PATCH リクエスト
 */
export const patch = (url, body, options = {}) => {
  return apiRequest(url, {
    ...options,
    method: "PATCH",
    body: JSON.stringify(body),
  })
}

/**
 * DELETE リクエスト
 */
export const destroy = (url, options = {}) => {
  return apiRequest(url, { ...options, method: "DELETE" })
}

/**
 * Turbo Stream を取得するリクエスト
 */
export const fetchTurboStream = async (url) => {
  const res = await fetch(url, {
    headers: { Accept: "text/vnd.turbo-stream.html" },
    credentials: "same-origin",
  })

  if (!res.ok) {
    throw new Error(`Turbo Stream request failed: ${res.status}`)
  }

  return res.text()
}
