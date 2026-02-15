// app/javascript/services/navibar_api.js
// ================================================================
// Navibar API（単一責務）
// 用途: Navibar を更新する Turbo Stream リクエスト + UI状態管理
//   - スクロール位置の保存/復元
//   - アコーディオン状態の保存/復元
//   - Turbo Stream の適用
//   - navibar イベントの発火
// ================================================================

import { getCsrfToken } from "services/api_client"

// ================================================================
// UI状態管理（スクロール・アコーディオン）
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
 * 開いているアコーディオン（collapse）の ID を取得
 */
const captureCollapseState = () => {
  const openCollapses = document.querySelectorAll(".collapse.show")
  return Array.from(openCollapses).map((el) => el.id).filter(Boolean)
}

/**
 * アコーディオンの状態を復元
 */
const restoreCollapseState = (openIds) => {
  openIds.forEach((id) => {
    const el = document.getElementById(id)
    if (el && !el.classList.contains("show")) {
      el.classList.add("show")
      // トグルボタンの aria-expanded も更新
      const toggle = document.querySelector(`[data-bs-target="#${id}"]`)
      if (toggle) toggle.setAttribute("aria-expanded", "true")
    }
  })
}

// ================================================================
// Turbo Stream リクエスト
// ================================================================

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
  const openCollapseIds = captureCollapseState()

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

  // スクロール位置・アコーディオン状態を復元 & 更新後イベント
  // ✅ Turbo.renderStreamMessage は同期的に DOM を更新するため、1フレーム後で十分
  requestAnimationFrame(() => {
    // ✅ ユーザーがスクロールしていたら復元をスキップ（UX向上）
    const currentScrollTop = captureScrollState()
    if (currentScrollTop === scrollTop) {
      restoreScrollState(scrollTop)
    }
    // ✅ アコーディオンの状態を復元
    restoreCollapseState(openCollapseIds)
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
  await postTurboStream(`/plans/${planId}/plan_spots`, { spot_id: spotId })

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
 */
export const removeSpotFromPlan = async (planSpotId, planId) => {
  await deleteTurboStream(`/plans/${planId}/plan_spots/${planSpotId}`)
}
