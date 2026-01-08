// app/javascript/plans/init_map_show.js
//
// ================================================================
// Map Initializer - 詳細画面用
// 用途: プラン詳細画面で map を初期化（閲覧専用）
//       - 地図生成
//       - POIクリック（閲覧モード、追加ボタンなし）
//       - マーカー描画
//       - プランのスポット全体にフィット
//       ※ 検索ボックス、各種編集ハンドラーは無効
// ================================================================

import { renderMap } from "map/render_map"
import { setupPoiClickForView } from "map/poi_click"
import { getMapInstance } from "map/state"
import { getPlanDataFromPage } from "plans/plan_data"

console.log("[init_map_show] module loaded")

/**
 * プランのスポット全体が表示されるように地図をフィットする
 */
const fitMapToSpots = (planData) => {
  const map = getMapInstance()
  if (!map) return

  const spots = planData?.spots || []
  if (spots.length === 0) return

  const bounds = new google.maps.LatLngBounds()

  spots.forEach((spot) => {
    if (spot?.lat && spot?.lng) {
      bounds.extend({ lat: Number(spot.lat), lng: Number(spot.lng) })
    }
  })

  map.fitBounds(bounds, { padding: 50 })

  // スポットが1つの場合、fitBoundsだとズームしすぎるので調整
  if (spots.length === 1) {
    google.maps.event.addListenerOnce(map, "bounds_changed", () => {
      if (map.getZoom() > 15) {
        map.setZoom(15)
      }
    })
  }
}

/**
 * スポット間の経路線を描画する
 * ※ 出発地点→最初のスポット、最後のスポット→帰宅地点の経路は
 *    プライバシー保護のため描画しない
 */
const renderRoutePolylines = () => {
  const map = getMapInstance()
  if (!map) return

  // geometry library がロードされているか確認
  if (!google?.maps?.geometry?.encoding?.decodePath) {
    console.warn("[init_map_show] geometry library not loaded")
    return
  }

  // DOM から polyline 情報を収集（position順）
  const spotBlocks = document.querySelectorAll(".spot-block[data-polyline][data-position]")
  const sortedBlocks = Array.from(spotBlocks).sort((a, b) => {
    return Number(a.dataset.position) - Number(b.dataset.position)
  })

  // 各スポットのpolylineは「このスポット→次のスポット(or帰宅地点)」の経路
  // 最後のスポットのpolylineは帰宅地点への経路なのでプライバシー保護のため除外
  const polylinesToRender = sortedBlocks
    .slice(0, -1) // 最後のスポット（→帰宅地点）を除外
    .map((block) => block.dataset.polyline)
    .filter(Boolean)

  console.log("[init_map_show] renderRoutePolylines", { count: polylinesToRender.length })

  if (polylinesToRender.length === 0) return

  polylinesToRender.forEach((encoded) => {
    try {
      const path = google.maps.geometry.encoding.decodePath(encoded)
      new google.maps.Polyline({
        path,
        map,
        strokeColor: "#D4846A",
        strokeOpacity: 0.85,
        strokeWeight: 4,
      })
    } catch (e) {
      console.warn("[init_map_show] Failed to decode polyline:", e)
    }
  })
}

/**
 * Google Maps APIが利用可能になるまで待機する
 */
const waitForGoogleMaps = (maxWait = 5000, interval = 100) => {
  return new Promise((resolve) => {
    if (typeof google !== "undefined" && google.maps) {
      resolve(true)
      return
    }

    const startTime = Date.now()
    const checkInterval = setInterval(() => {
      if (typeof google !== "undefined" && google.maps) {
        clearInterval(checkInterval)
        resolve(true)
      } else if (Date.now() - startTime > maxWait) {
        clearInterval(checkInterval)
        console.error("[init_map_show] Google Maps API の読み込みがタイムアウトしました")
        resolve(false)
      }
    }, interval)
  })
}

/**
 * 詳細画面かどうかを判定
 */
const isShowPage = () => {
  const mapElement = document.getElementById("map")
  return mapElement && mapElement.dataset.mapMode === "show"
}

document.addEventListener("turbo:load", async () => {
  console.log("[init_map_show] turbo:load fired")

  const mapElement = document.getElementById("map")
  if (!mapElement) {
    console.log("[init_map_show] #map not found. skip.")
    return
  }

  // 詳細画面でない場合はスキップ
  if (!isShowPage()) {
    console.log("[init_map_show] not show page. skip.")
    return
  }

  // Google Maps APIの準備を待つ
  const isGoogleMapsReady = await waitForGoogleMaps()
  if (!isGoogleMapsReady) {
    console.error("[init_map_show] Google Maps API が利用できません")
    return
  }

  const fallbackCenter = { lat: 35.681236, lng: 139.767125 } // 東京駅
  console.log("[init_map_show] initializing map...")

  // 地図生成
  renderMap(fallbackCenter)

  // POIクリック（閲覧モード、追加ボタンなし）
  setupPoiClickForView()

  // プランデータがあればマーカーを描画
  const planData = getPlanDataFromPage()
  if (!planData) {
    console.log("[init_map_show] planData not found. renderPlanMarkers skipped.")
    return
  }

  console.log("[init_map_show] planData found. renderPlanMarkers()")
  const { renderPlanMarkers } = await import("plans/render_plan_markers")
  renderPlanMarkers(planData)

  // スポット間の経路線を描画
  renderRoutePolylines()

  // プランのスポット全体が表示されるように地図をフィット
  fitMapToSpots(planData)
})
