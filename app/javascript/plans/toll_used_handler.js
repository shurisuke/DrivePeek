// app/javascript/plans/toll_used_handler.js
//
// ================================================================
// Toll Used Handler（単一責務）
// 用途: 「有料道路スイッチ」を変更したらRailsへ保存
//   - plan_spots: [data-toll-used-switch="1"]
//   - start_point: [data-start-point-toll-used-switch="1"]
// ================================================================

import { patch } from "services/api_client"

// ------------------------------
// DOM 更新ヘルパー
// ------------------------------

/**
 * 時間を「X時間Y分」形式にフォーマット（スポットブロック用）
 */
const formatTime = (minutes) => {
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  if (hours > 0 && mins > 0) {
    return `${hours}<span class="time-unit">時間</span>${mins}<span class="time-unit">分</span>`
  } else if (hours > 0) {
    return `${hours}<span class="time-unit">時間</span>`
  } else {
    return `${mins}<span class="time-unit">分</span>`
  }
}

/**
 * 時間を「X時間Y分」形式にフォーマット（フッター用）
 */
const formatFooterTime = (minutes) => {
  const hours = Math.floor(minutes / 60)
  const mins = minutes % 60
  if (hours > 0) {
    return `${hours}<span class="plan-summary__unit">時間</span>${mins}<span class="plan-summary__unit">分</span>`
  } else {
    return `${mins}<span class="plan-summary__unit">分</span>`
  }
}

/**
 * 距離を「X.Xkm」形式にフォーマット
 */
const formatDistance = (km) => {
  if (km == null) return "—"
  return `${km}<span class="km-unit">km</span>`
}

/**
 * 出発地点の時間・距離表示を更新
 */
const updateStartPointDisplay = (startPointData) => {
  // 次の場所までの時間・距離
  const nextMoveEl = document.querySelector('[data-plan-time-role="start-next-move"]')
  if (nextMoveEl) {
    const kmEl = nextMoveEl.querySelector('.km')
    const timeEl = nextMoveEl.querySelector('.time')
    if (kmEl) kmEl.innerHTML = formatDistance(startPointData.move_distance)
    if (timeEl) timeEl.innerHTML = formatTime(startPointData.move_time)
  }
}

/**
 * スポットの時間・距離表示を更新
 */
const updateSpotDisplay = (spotData) => {
  const spotBlock = document.querySelector(`[data-plan-spot-id="${spotData.id}"]`)
  if (!spotBlock) return

  // 到着時刻
  const arrivalEl = spotBlock.querySelector('.block-time-panel .time-display:first-child .time-display__value')
  if (arrivalEl) {
    arrivalEl.textContent = spotData.arrival_time || "--:--"
  }

  // 出発時刻
  const departureEl = spotBlock.querySelector('[data-plan-time-role="spot-departure"] .time-display__value')
  if (departureEl) {
    departureEl.textContent = spotData.departure_time || "--:--"
  }

  // 次の場所までの時間・距離
  const nextMoveEl = spotBlock.querySelector('[data-plan-time-role="spot-next-move"]')
  if (nextMoveEl) {
    const kmEl = nextMoveEl.querySelector('.km')
    const timeEl = nextMoveEl.querySelector('.time')
    if (kmEl) kmEl.innerHTML = formatDistance(spotData.move_distance)
    if (timeEl) timeEl.innerHTML = formatTime(spotData.move_time)
  }
}

/**
 * フッターの合計を更新
 */
const updateFooter = (footerData) => {
  if (!footerData) return

  // スポットのみ（帰宅地点OFF時）
  const spotsOnlyDistanceEl = document.querySelector('[data-plan-total="spots-only-distance"]')
  if (spotsOnlyDistanceEl) {
    spotsOnlyDistanceEl.textContent = footerData.spots_only_distance ?? "—"
  }

  const spotsOnlyTimeEl = document.querySelector('[data-plan-total="spots-only-time"]')
  if (spotsOnlyTimeEl) {
    spotsOnlyTimeEl.innerHTML = formatFooterTime(footerData.spots_only_time)
  }

  // 帰宅地点含む（帰宅地点ON時）
  const withGoalDistanceEl = document.querySelector('[data-plan-total="with-goal-distance"]')
  if (withGoalDistanceEl) {
    withGoalDistanceEl.textContent = footerData.with_goal_distance ?? "—"
  }

  const withGoalTimeEl = document.querySelector('[data-plan-total="with-goal-time"]')
  if (withGoalTimeEl) {
    withGoalTimeEl.innerHTML = formatFooterTime(footerData.with_goal_time)
  }
}

// ------------------------------
// イベント委譲ハンドラ
// ------------------------------
const handleChange = async (e) => {
  const el = e.target
  if (!(el instanceof HTMLInputElement)) return

  // --- start_point のトグル（JSON + DOM 更新）---
  if (el.matches('[data-start-point-toll-used-switch="1"]')) {
    const planId = el.dataset.planId
    if (!planId) return

    const tollUsed = el.checked

    try {
      const data = await patch(`/api/plans/${planId}/start_point`, {
        start_point: { toll_used: tollUsed },
      })

      // DOM 更新（スイッチは触らない = アニメーション維持）
      if (data.start_point) updateStartPointDisplay(data.start_point)
      if (data.spots) data.spots.forEach(updateSpotDisplay)
      if (data.footer) updateFooter(data.footer)

      document.dispatchEvent(new CustomEvent("map:route-updated"))
    } catch (err) {
      alert(err.message)
      el.checked = !tollUsed // 元に戻す
    }
    return
  }

  // --- plan_spots のトグル（JSON + DOM 更新）---
  if (el.matches('[data-toll-used-switch="1"]')) {
    const planId = el.dataset.planId
    const planSpotId = el.dataset.planSpotId
    if (!planId || !planSpotId) return

    const tollUsed = el.checked

    try {
      const data = await patch(`/api/plans/${planId}/plan_spots/${planSpotId}/toll_used`, {
        toll_used: tollUsed,
      })

      // DOM 更新（スイッチは触らない = アニメーション維持）
      if (data.spots) data.spots.forEach(updateSpotDisplay)
      if (data.footer) updateFooter(data.footer)

      document.dispatchEvent(new CustomEvent("map:route-updated"))
    } catch (err) {
      alert(err.message)
      el.checked = !tollUsed // 元に戻す
    }
  }
}

// ------------------------------
// バインド（二重登録防止）
// ------------------------------
let bound = false

export const bindTollUsedHandler = () => {
  if (bound) return
  bound = true
  document.addEventListener("change", handleChange)
}
