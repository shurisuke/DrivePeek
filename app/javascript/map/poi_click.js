// ================================================================
// POIクリック処理
// 用途: 地図上のPOI（店舗・施設等）クリック時にInfoWindowを表示
// 設計: Turbo Frame方式（Google Places APIをスキップし即時表示）
// ================================================================

import { getMapInstance } from "map/state"
import { showInfoWindowWithFrame } from "map/infowindow"

/**
 * plan_idを取得
 */
const getPlanId = () => {
  const mapEl = document.getElementById("map")
  return mapEl?.dataset.planId || null
}

/**
 * POIクリックの共通処理（Turbo Frame方式）
 * Google Places APIを呼ばず、即座にInfoWindowを表示
 */
const handlePoiClick = (event, { showButton = true } = {}) => {
  if (!event.placeId) return
  event.stop()

  const map = getMapInstance()
  if (!map) return

  // 位置情報を取得
  const lat = event.latLng.lat()
  const lng = event.latLng.lng()

  // Turbo Frame方式で即座にInfoWindowを表示
  // スケルトン表示 → Rails APIがSpot作成 + HTML返却
  showInfoWindowWithFrame({
    anchor: event.latLng,
    placeId: event.placeId,
    name: null, // Railsが取得
    lat,
    lng,
    showButton,
    planId: getPlanId()
  })
}

/**
 * POIクリックイベントをセットアップ
 * @param {boolean} showButton - 追加ボタンを表示するか（編集モード: true、閲覧モード: false）
 */
export const setupPoiClick = (showButton = true) => {
  const map = getMapInstance()
  if (!map) {
    console.error("[poi_click] map instance not found")
    return
  }

  map.addListener("click", (event) => {
    handlePoiClick(event, { showButton })
  })
}
