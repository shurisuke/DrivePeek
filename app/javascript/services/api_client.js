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

// ================================================================
// Turbo Stream API リクエスト（スクロール位置保存/復元付き）
// ================================================================

/**
 * navibar のスクロール要素を取得
 */
const getNavibarScrollEl = () => document.querySelector(".navibar__content-scroll")

/**
 * スクロール位置を保存
 */
const captureScrollState = () => {
  const el = getNavibarScrollEl()
  return el ? el.scrollTop : 0
}

/**
 * スクロール位置を復元
 */
const restoreScrollState = (scrollTop) => {
  const el = getNavibarScrollEl()
  if (el) el.scrollTop = scrollTop
}

/**
 * Turbo Stream レスポンスを適用
 */
const applyTurboStream = (html) => {
  if (window.Turbo) {
    window.Turbo.renderStreamMessage(html)
  }
}

/**
 * Turbo Stream API リクエスト共通処理
 * - スクロール位置を保存
 * - API リクエスト実行
 * - Turbo Stream を適用
 * - スクロール位置を復元
 * - navibar イベントを発火（Sortable等の再初期化用）
 */
const turboStreamRequest = async (url, options = {}) => {
  const scrollTop = captureScrollState()

  // 更新前イベント（Sortable破棄等）
  document.dispatchEvent(new CustomEvent("navibar:will-update"))

  const config = {
    credentials: "same-origin",
    ...options,
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": getCsrfToken(),
      Accept: "text/vnd.turbo-stream.html",
      ...options.headers,
    },
  }

  const res = await fetch(url, config)

  if (!res.ok) {
    // エラー時はJSONでエラーメッセージを返す想定
    const err = await res.json().catch(() => ({}))
    const message = err.message || err.errors?.join(", ") || `Request failed: ${res.status}`
    throw new Error(message)
  }

  // 204 No Content の場合はスキップ
  if (res.status !== 204) {
    const html = await res.text()
    applyTurboStream(html)
  }

  // スクロール位置を復元 & 更新後イベント（Sortable再初期化等）
  // ✅ Turbo.renderStreamMessage は同期的に DOM を更新するため、1フレーム後で十分
  requestAnimationFrame(() => {
    // ✅ ユーザーがスクロールしていたら復元をスキップ（UX向上）
    const currentScrollTop = captureScrollState()
    if (currentScrollTop === scrollTop) {
      restoreScrollState(scrollTop)
    }
    document.dispatchEvent(new CustomEvent("navibar:updated"))
  })

  return null
}

/**
 * Turbo Stream POST リクエスト
 */
export const postTurboStream = (url, body, options = {}) => {
  return turboStreamRequest(url, {
    ...options,
    method: "POST",
    body: JSON.stringify(body),
  })
}

/**
 * Turbo Stream PATCH リクエスト
 */
export const patchTurboStream = (url, body, options = {}) => {
  return turboStreamRequest(url, {
    ...options,
    method: "PATCH",
    body: JSON.stringify(body),
  })
}

/**
 * Turbo Stream DELETE リクエスト
 */
export const deleteTurboStream = (url, options = {}) => {
  return turboStreamRequest(url, {
    ...options,
    method: "DELETE",
  })
}

// ================================================================
// スポット追加/削除 API（高レベル関数）
// ================================================================

/**
 * スポットをプランに追加
 * - API呼び出し + Turbo Stream適用
 * - navibar:updated（turboStreamRequest内で発火）
 * - plan:spot-added（検索マーカークリア用）
 * - navibar:activate-tab（プランタブをアクティブに）
 */
export const addSpotToPlan = async (planId, spotId) => {
  await postTurboStream("/api/plan_spots", { plan_id: planId, spot_id: spotId })

  // DOM更新完了後にイベント発火（turboStreamRequestの requestAnimationFrame の後）
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      document.dispatchEvent(new CustomEvent("plan:spot-added", { detail: { planId, spotId } }))
      document.dispatchEvent(new CustomEvent("navibar:activate-tab", { detail: { tab: "plan" } }))
    })
  })
}

/**
 * スポットをプランから削除
 * - API呼び出し + Turbo Stream適用
 * - navibar:updated（turboStreamRequest内で発火）
 * - plan:spot-deleted（マーカー再描画用）
 */
export const removeSpotFromPlan = async (planSpotId, planId) => {
  await deleteTurboStream(`/plans/${planId}/plan_spots/${planSpotId}`)

  // DOM更新完了後にイベント発火
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      document.dispatchEvent(new CustomEvent("plan:spot-deleted", { detail: { planId, planSpotId } }))
    })
  })
}
