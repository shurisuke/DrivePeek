// app/javascript/map/visual_center.js
// ================================================================
// Visual Center（単一責務）
// 用途: ナビバー・ボトムシートを考慮した地図の見た目の中央を計算
// ================================================================

import { getMapInstance } from "map/state"

/**
 * モバイル判定
 */
const isMobile = () => window.innerWidth < 768

/**
 * ボトムシートの現在の高さを取得（モバイル時）
 */
const getBottomSheetHeight = () => {
  if (!isMobile()) return 0
  const navibar = document.querySelector(".navibar")
  return navibar?.offsetHeight || 0
}

/**
 * InfoWindowの高さを取得（モバイル時）
 */
const getInfoWindowHeight = () => {
  if (!isMobile()) return 0
  // InfoWindowはまだ表示されていない場合があるので、想定高さを返す
  const infoWindow = document.querySelector(".infowindow-mobile, .gm-style-iw")
  return infoWindow?.offsetHeight || 280 // デフォルト想定高さ
}

/**
 * ナビバーの表示幅を取得（デスクトップ時）
 */
const getNavibarWidth = () => {
  if (isMobile()) return 0
  const style = getComputedStyle(document.documentElement)
  const width = parseInt(style.getPropertyValue("--navibar-width")) || 360
  const slide = parseInt(style.getPropertyValue("--navibar-slide")) || 0
  return width - slide
}

/**
 * 指定座標を見た目の中央に表示（モバイルのみ）
 * デスクトップは既存の動作が良いのでそのまま
 * @param {google.maps.LatLng|{lat, lng}} position - 表示したい座標
 * @param {Object} options
 * @param {number} options.offsetY - 追加の縦オフセット（px、負で上方向）
 */
export const panToVisualCenter = (position, options = {}) => {
  const map = getMapInstance()
  if (!map) return

  const latLng = position instanceof google.maps.LatLng
    ? position
    : new google.maps.LatLng(position.lat, position.lng)

  // まず通常のpanTo
  map.panTo(latLng)

  // モバイルのみオフセット調整
  if (!isMobile()) return

  // ボトムシートで隠れる領域を考慮して、見える範囲の中央にピンを配置
  // panBy(0, 正の値)で地図が下に移動 → ピンが上に見える
  const bottomSheetHeight = getBottomSheetHeight()
  const offsetY = bottomSheetHeight / 2

  if (offsetY > 0) {
    map.panBy(0, offsetY)
  }
}

/**
 * fitBounds用のパディングを取得（モバイルのみボトムシート考慮）
 * @returns {google.maps.Padding}
 */
export const getMapPadding = () => {
  if (isMobile()) {
    const bottomSheetHeight = getBottomSheetHeight()
    return {
      top: 60,  // 検索バー
      right: 16,
      bottom: bottomSheetHeight > 0 ? bottomSheetHeight + 16 : 16,
      left: 16
    }
  }
  // デスクトップは通常のパディング
  return { top: 50, right: 50, bottom: 50, left: 50 }
}

/**
 * パディング付きでfitBounds
 * @param {google.maps.LatLngBounds} bounds
 */
export const fitBoundsWithPadding = (bounds) => {
  const map = getMapInstance()
  if (!map) return

  map.fitBounds(bounds, getMapPadding())
}
