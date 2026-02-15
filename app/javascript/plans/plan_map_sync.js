// app/javascript/plans/plan_map_sync.js
//
// ================================================================
// Plan Map Sync（単一責務）
// 用途: プラン画面で発生するイベントを購読し、地図表示を同期する。
//       - マーカー描画: navibar差し替え後に DOM から最新座標を拾って再描画
//       - 経路描画: DB保存済み polyline を DOM から収集し、API非依存で再描画
//       - 帰宅地点トグル: goal の表示状態に合わせて「最後区間」を描く/描かないを切替
//
// 重要:
//   - 経路は Directions / Routes API を一切呼ばず、geometry.decodePath で描画する
//   - polyline の参照は map/state.js に保持し、再描画前に必ず clear する
//   - 再描画トリガは turbo:load / navibar:updated / map:route-updated / goal関連イベント
// ================================================================

import { getPlanDataFromPage } from "plans/plan_data"
import { getMapInstance, setRoutePolylines, clearRoutePolylines, clearSearchHitMarkers } from "map/state"
import { isEditPage } from "map/utils"
import { ROUTE_POLYLINE_STYLE } from "map/constants"

let bound = false
let cachedPlanData = null

// ✅ DOM から最新のスポット情報を収集する
const getSpotsFromDom = () => {
  const spotBlocks = document.querySelectorAll(".spot-block[data-lat][data-lng]")
  return Array.from(spotBlocks).map((el) => ({
    lat: Number(el.dataset.lat),
    lng: Number(el.dataset.lng),
  }))
}

// ✅ DOM から polyline 情報を収集する（区間順）
const getPolylinesFromDom = () => {
  const polylines = []

  // 1. start_point → 最初の plan_spot の区間
  const startPointBlock = document.querySelector(".start-point-block[data-polyline]")
  if (startPointBlock?.dataset.polyline) {
    polylines.push(startPointBlock.dataset.polyline)
  }

  // 2. plan_spot → 次の plan_spot or goal_point の区間（position順）
  const spotBlocks = document.querySelectorAll(".spot-block[data-polyline][data-position]")
  const sortedBlocks = Array.from(spotBlocks).sort((a, b) => {
    return Number(a.dataset.position) - Number(b.dataset.position)
  })

  sortedBlocks.forEach((block) => {
    if (block.dataset.polyline) {
      polylines.push(block.dataset.polyline)
    }
  })

  return polylines.filter(Boolean)
}

// ✅ 帰宅地点の表示状態を取得する
const isGoalPointVisible = () => {
  const mapEl = document.getElementById("map")
  return mapEl?.dataset?.goalPointVisible === "true"
}

// ✅ スポット数をDOMから取得
const getSpotCountFromDom = () => {
  return document.querySelectorAll(".spot-block[data-plan-spot-id]").length
}

// ✅ polyline をデコードして地図上に描画する
const renderRoutePolylines = () => {
  const map = getMapInstance()
  if (!map) return

  // geometry library がロードされているか確認
  if (!google?.maps?.geometry?.encoding?.decodePath) {
    console.warn("[plan_map_sync] geometry library not loaded")
    return
  }

  // ✅ スポットがない場合は経路をクリアして終了
  const spotCount = getSpotCountFromDom()
  if (spotCount === 0) {
    clearRoutePolylines()
    return
  }

  let encodedPolylines = getPolylinesFromDom()

  // ✅ 帰宅地点が非表示の場合、最後の区間（最後スポット→帰宅地点）を除外
  // ただし、2区間以上ある場合のみ（1区間だけの場合は start→spot なので除外しない）
  const goalVisible = isGoalPointVisible()
  if (!goalVisible && encodedPolylines.length > 1) {
    encodedPolylines = encodedPolylines.slice(0, -1)
  }

  if (encodedPolylines.length === 0) {
    clearRoutePolylines()
    return
  }

  const polylineInstances = encodedPolylines.map((encoded) => {
    try {
      const path = google.maps.geometry.encoding.decodePath(encoded)
      return new google.maps.Polyline({
        path,
        map,
        ...ROUTE_POLYLINE_STYLE,
      })
    } catch (e) {
      console.warn("[plan_map_sync] Failed to decode polyline:", e)
      return null
    }
  }).filter(Boolean)

  setRoutePolylines(polylineInstances)
}

// ✅ planData の spots を DOM から更新した新しいオブジェクトを返す
const mergeSpotsFromDom = (planData) => {
  const spots = getSpotsFromDom()
  return { ...planData, spots }
}

// ✅ DOM から出発地点の位置を取得
const getStartPointPositionFromDom = () => {
  const el = document.querySelector(".start-point-block")
  if (!el) return null

  const lat = parseFloat(el.dataset.lat)
  const lng = parseFloat(el.dataset.lng)
  if (isNaN(lat) || isNaN(lng)) return null
  return { lat, lng }
}

// ✅ DOM から帰宅地点の位置を取得
const getGoalPointPositionFromDom = () => {
  const el = document.querySelector(".goal-point-block")
  if (!el) return null

  const lat = parseFloat(el.dataset.lat)
  const lng = parseFloat(el.dataset.lng)
  if (isNaN(lat) || isNaN(lng)) return null
  return { lat, lng }
}

// ✅ planData の start_point/goal_point を DOM から更新した新しいオブジェクトを返す
const mergePointsFromDom = (planData) => {
  const startPos = getStartPointPositionFromDom()
  const goalPos = getGoalPointPositionFromDom()

  const result = { ...planData }

  if (startPos) {
    result.start_point = { ...planData?.start_point, ...startPos }
  }
  if (goalPos) {
    result.goal_point = { ...planData?.goal_point, ...goalPos }
    result.end_point = { ...planData?.end_point, ...goalPos }
  }

  return result
}

const setGoalVisible = (visible) => {
  const mapEl = document.getElementById("map")
  if (!mapEl) return
  mapEl.dataset.goalPointVisible = visible ? "true" : "false"
}

const mergeGoalPoint = (planData, goal) => {
  if (!planData || !goal) return planData

  const normalized = {
    address: goal.address,
    lat: Number(goal.lat),
    lng: Number(goal.lng),
  }

  // planDataの揺れを吸収（end_point / goal_point 両方）
  return {
    ...planData,
    goal_point: { ...(planData.goal_point || {}), ...normalized },
    end_point: { ...(planData.end_point || {}), ...normalized },
  }
}

const renderAllMarkersSafe = async (planData) => {
  try {
    const { renderPlanMarkers } = await import("plans/render_plan_markers")
    renderPlanMarkers(planData)
  } catch (e) {
    console.warn("[plan_map_sync] renderPlanMarkers failed", e)
  }
}

const refreshGoalMarkerSafe = async (planData) => {
  try {
    const { refreshGoalMarker } = await import("plans/render_plan_markers")
    refreshGoalMarker(planData)
  } catch (e) {
    console.warn("[plan_map_sync] refreshGoalMarker failed", e)
  }
}

export const bindPlanMapSync = () => {
  if (bound) return
  bound = true

  cachedPlanData = getPlanDataFromPage()

  // ✅ Turbo遷移後もキャッシュを最新化（bound=trueで再バインドされないため）
  document.addEventListener("turbo:load", () => {
    // ✅ show画面ではスキップ（init_map_show.js が独自に処理する）
    if (!isEditPage()) return

    const fresh = getPlanDataFromPage()
    if (fresh) {
      cachedPlanData = fresh
    }

    // ✅ 初回描画：polyline を描画する（少し遅延させてマップ初期化を待つ）
    setTimeout(() => {
      renderRoutePolylines()
    }, 100)
  })

  // navibar 差し替え後：planDataを取り直して「全部のピン」を差し直す
  // ※ スポット削除・入れ替え時もこのイベントが発火する
  document.addEventListener("navibar:updated", async () => {
    // ✅ 帰宅地点の表示状態を body クラス（復元済み）から #map.dataset に同期
    // Stimulus controller の再接続で上書きされた可能性があるため、ここで正しい状態に戻す
    const goalVisibleFromBody = document.body.classList.contains("goal-point-visible")
    setGoalVisible(goalVisibleFromBody)

    // ✅ turbo_stream で DOM が更新されているので、常に最新データを取得
    const freshPlanData = getPlanDataFromPage()
    if (!freshPlanData && !cachedPlanData) return

    // ✅ DOM から取得した最新データを優先（turbo_stream で更新済み）
    // start_point/goal_point も DOM から取得して確実に最新化
    const basePlanData = freshPlanData || cachedPlanData
    let planData = mergeSpotsFromDom(basePlanData)
    planData = mergePointsFromDom(planData)
    cachedPlanData = planData

    // ✅ window.planData も更新して一貫性を保つ
    if (window.planData) {
      window.planData = planData
    }

    await renderAllMarkersSafe(planData)

    // ✅ 経路ポリラインも再描画（スポット削除時にクリアされるように）
    renderRoutePolylines()
  })

  // トグルON/OFF：帰宅ピンだけ更新 + polyline 再描画
  document.addEventListener("plan:goal-point-visibility-changed", async (e) => {
    // ✅ 先に #map の goalPointVisible を更新（renderRoutePolylines が参照するため）
    const goalVisible = e?.detail?.goalVisible ?? false
    setGoalVisible(goalVisible)

    const freshPlanData = getPlanDataFromPage()
    if (!freshPlanData && !cachedPlanData) return

    // ✅ DOM から取得した最新データを優先
    const planData = freshPlanData || cachedPlanData
    cachedPlanData = planData
    await refreshGoalMarkerSafe(planData)

    // ✅ 帰宅地点の表示状態に応じて polyline を再描画
    renderRoutePolylines()
  })

  // 帰宅地点の更新：必ず visible=true にして、帰宅ピンを更新
  document.addEventListener("plan:goal-point-updated", async (e) => {
    // ✅ 検索ヒットマーカーをクリア（プラン変更時は検索結果を消す）
    clearSearchHitMarkers()

    // ✅ visible は文字列 "true" を直接セット（boolean禁止）
    const mapEl = document.getElementById("map")
    if (mapEl) {
      mapEl.dataset.goalPointVisible = "true"
    }

    // ✅ 最新の planData を取得しつつ、null なら cachedPlanData でフォールバック
    const freshPlanData = getPlanDataFromPage()
    const basePlanData = freshPlanData || cachedPlanData
    cachedPlanData = mergeGoalPoint(basePlanData, e?.detail)

    if (!cachedPlanData) return

    await refreshGoalMarkerSafe(cachedPlanData)
  })

  // スポット追加時：検索ヒットマーカーをクリア
  document.addEventListener("plan:spot-added", () => {
    // ✅ 検索ヒットマーカーをクリア（スポット追加後は検索結果を消す）
    clearSearchHitMarkers()
  })

  // 出発地点変更時：検索ヒットマーカーをクリア
  // ※ マーカーは start_point_editor_controller で既に正しい位置に作成済みなので、
  //   ここでは cachedPlanData の更新のみ行い、マーカー再描画はスキップする
  document.addEventListener("plan:start-point-updated", async (e) => {
    // ✅ 検索ヒットマーカーをクリア（プラン変更時は検索結果を消す）
    clearSearchHitMarkers()

    // ✅ 出発地点の情報を cachedPlanData に保存（後続の navibar:updated で使用）
    const basePlanData = getPlanDataFromPage() || cachedPlanData
    if (!basePlanData) return

    const startPoint = e?.detail
    if (startPoint) {
      cachedPlanData = {
        ...basePlanData,
        start_point: {
          lat: Number(startPoint.lat),
          lng: Number(startPoint.lng),
          address: startPoint.address,
        },
      }
    }

    // ✅ マーカーは start_point_editor_controller で既に作成済みなので、ここでは再描画しない
    // spots の情報だけ更新しておく
    cachedPlanData = mergeSpotsFromDom(cachedPlanData)
  })

  // ✅ 経路更新後：polyline を再描画する
  document.addEventListener("map:route-updated", () => {
    renderRoutePolylines()
  })
}