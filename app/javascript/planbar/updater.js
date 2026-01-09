// app/javascript/planbar/updater.js
// ================================================================
// Planbar Updater（単一責務）
// 用途: planbar を Turbo Stream で差し替えて、UI 状態を復元する
// ================================================================

import { getPlanDataFromPage } from "plans/plan_data"
import { fetchTurboStream } from "services/api_client"

import {
  captureOpenCollapseIds,
  restoreOpenCollapseIds,
  captureSpotBlockUIStates,
  restoreSpotBlockUIStates,
  captureGoalPointVisibilityState,
  restoreGoalPointVisibilityState,
  updateDepartureTimeClass,
  withNoCollapseAnimation,
} from "planbar/ui_state"

import {
  getPlanbarScrollEl,
  lockPlanbarUI,
  unlockPlanbarUI,
  beginPlanbarUpdate,
  endPlanbarUpdate,
  capturePlanbarScrollState,
  restorePlanbarScrollState,
  scrollToBottom,
} from "planbar/scroll_state"

let bound = false

// -------------------------------
// Plan ID 取得
// -------------------------------
const getPlanId = () => {
  const planIdFromMap = document.getElementById("map")?.dataset?.planId
  if (planIdFromMap) return planIdFromMap

  const planData = getPlanDataFromPage()
  return planData?.plan_id || planData?.id || null
}

// -------------------------------
// メインのリフレッシュ処理
// -------------------------------
const refreshPlanbar = async (planId) => {
  // 状態を退避
  const openCollapseIds = captureOpenCollapseIds()
  const spotBlockStates = captureSpotBlockUIStates()
  const scrollState = capturePlanbarScrollState()
  const goalPointState = captureGoalPointVisibilityState()

  document.dispatchEvent(new CustomEvent("planbar:will-update"))

  lockPlanbarUI()

  let html = null
  try {
    html = await fetchTurboStream(`/plans/${planId}/planbar`)
  } catch (err) {
    console.warn("[planbar/updater] refreshPlanbar failed", { planId, error: err.message })
    unlockPlanbarUI()
    return
  }

  if (!window.Turbo) {
    console.error("[planbar/updater] Turbo is not available on window")
    unlockPlanbarUI()
    return
  }

  beginPlanbarUpdate()

  try {
    await withNoCollapseAnimation(async () => {
      window.Turbo.renderStreamMessage(html)

      // 即時復元（controller が後から触って揺れるのを防ぐ）
      restoreGoalPointVisibilityState(goalPointState)
      updateDepartureTimeClass()

      await new Promise((r) => requestAnimationFrame(() => r()))

      await restoreOpenCollapseIds(openCollapseIds)
      await restoreSpotBlockUIStates(spotBlockStates)

      restorePlanbarScrollState(scrollState)

      // 2フレーム補正
      await new Promise((r) => requestAnimationFrame(() => r()))
      await new Promise((r) => requestAnimationFrame(() => r()))
      restorePlanbarScrollState(scrollState)
    })

    document.dispatchEvent(new CustomEvent("planbar:updated"))
    document.dispatchEvent(new CustomEvent("map:route-updated"))
  } finally {
    endPlanbarUpdate()
    unlockPlanbarUI()
  }
}

// -------------------------------
// イベントバインド
// -------------------------------
export const bindPlanbarRefresh = () => {
  if (bound) return
  bound = true

  document.addEventListener("plan:spot-added", async () => {
    const planId = getPlanId()
    if (!planId) return
    await refreshPlanbar(planId)
    scrollToBottom()

    // スポット追加後はプランタブをアクティブにする
    document.dispatchEvent(new CustomEvent("navibar:activate-tab", { detail: { tab: "plan" } }))
  })

  document.addEventListener("plan:spots-reordered", async () => {
    const planId = getPlanId()
    if (!planId) return
    await refreshPlanbar(planId)
  })

  document.addEventListener("plan:spot-deleted", async (e) => {
    const planId = e?.detail?.planId || getPlanId()
    if (!planId) return
    await refreshPlanbar(planId)
  })

  document.addEventListener("plan:plan-spot-toll-used-updated", async () => {
    const planId = getPlanId()
    if (!planId) return
    await refreshPlanbar(planId)
  })

  document.addEventListener("plan:departure-time-updated", async () => {
    const planId = getPlanId()
    if (!planId) return
    await refreshPlanbar(planId)
  })

  document.addEventListener("plan:plan-spot-stay-duration-updated", async () => {
    const planId = getPlanId()
    if (!planId) return
    await refreshPlanbar(planId)
  })

  document.addEventListener("plan:start-point-updated", async () => {
    const planId = getPlanId()
    if (!planId) return
    await refreshPlanbar(planId)
  })

  document.addEventListener("plan:start-point-toll-used-updated", async () => {
    const planId = getPlanId()
    if (!planId) return
    await refreshPlanbar(planId)
  })

  document.addEventListener("plan:goal-point-updated", async () => {
    const planId = getPlanId()
    if (!planId) return
    await refreshPlanbar(planId)
  })
}
