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
 * モバイル上部の障害物の高さを取得（検索ボックス + フローティングボタン）
 */
const getMobileTopHeight = () => {
  if (!isMobile()) return 0
  const searchBox = document.querySelector(".map-search-box")
  const floatingButtons = document.querySelector(".map-floating-buttons")
  return (searchBox?.offsetHeight || 0) + (floatingButtons?.offsetHeight || 0)
}

/**
 * デスクトップ用の縦オフセットを計算
 * 上部障害物と下部障害物の中間にInfoWindowを配置
 */
const getDesktopOffsetY = () => {
  // 上部: 検索バー + フローティングボタン
  const searchBox = document.querySelector(".map-search-box")
  const floatingButtons = document.querySelector(".map-floating-buttons")
  const topHeight = (searchBox?.offsetHeight || 50) + (floatingButtons?.offsetHeight || 40)

  // 下部: アクションバー（共有・保存ボタン）
  const actionBar = document.querySelector(".plan-actions")
  const bottomHeight = actionBar?.offsetHeight || 0

  // マーカーからInfoWindow中心までの距離（InfoWindow半分 + ピクセルオフセット）
  const infoWindowHalfHeight = 150
  const pixelOffsetToMarker = 50
  const markerToInfoWindowCenter = infoWindowHalfHeight + pixelOffsetToMarker

  // 障害物の中間 - InfoWindow中心を基準に上へシフト（InfoWindowが中央に来る）
  return (bottomHeight - topHeight) / 2 - markerToInfoWindowCenter
}

/**
 * 指定座標を見た目の中央に表示
 * モバイル: ボトムシートを考慮
 * デスクトップ: 検索バー + フローティングボタン + InfoWindowを考慮
 * @param {google.maps.LatLng|{lat, lng}} position - 表示したい座標
 */
export const panToVisualCenter = (position) => {
  const map = getMapInstance()
  if (!map) return

  const latLng = position instanceof google.maps.LatLng
    ? position
    : new google.maps.LatLng(position.lat, position.lng)

  // まず通常のpanTo
  map.panTo(latLng)

  if (isMobile()) {
    // モバイル: 上部障害物とボトムシートを考慮して、見える範囲の中央にピンを配置
    const topHeight = getMobileTopHeight()
    const bottomSheetHeight = getBottomSheetHeight()
    // 上部と下部の差分を2で割って、見える領域の中央へ調整
    // panBy(0, 正の値)で地図が下に移動 → ピンが上に見える
    const offsetY = (bottomSheetHeight - topHeight) / 2

    if (offsetY !== 0) {
      map.panBy(0, offsetY)
    }
  } else {
    // デスクトップ: 検索バー + フローティングボタン + InfoWindow高さを考慮
    // panBy(0, 負)で地図が上にシフト → InfoWindowが見える位置に
    const offsetY = getDesktopOffsetY()
    map.panBy(0, offsetY)
  }
}

/**
 * fitBounds用のパディングを取得
 * モバイル: ボトムシート考慮
 * デスクトップ: ナビバー幅、検索ボックス、アクションバー、ピン削除ボタン考慮
 * @returns {google.maps.Padding}
 */
export const getMapPadding = () => {
  if (isMobile()) {
    const topHeight = getMobileTopHeight()
    const bottomSheetHeight = getBottomSheetHeight()
    return {
      top: topHeight > 0 ? topHeight + 16 : 60,
      right: 16,
      bottom: bottomSheetHeight > 0 ? bottomSheetHeight + 16 : 16,
      left: 16
    }
  }

  // デスクトップ: 各UI要素を考慮
  // ※ 地図要素自体がナビバーの右側に配置されているため、
  //    leftPaddingにナビバー幅は含めない（二重計算防止）

  // 上部: 検索ボックス + ピン削除ボタン + 余裕
  const searchBox = document.querySelector(".map-search-box")
  const topPadding = (searchBox?.offsetHeight || 50) + 40

  // 下部: アクションバー（共有・保存ボタン）
  const actionBar = document.querySelector(".plan-actions")
  const bottomPadding = (actionBar?.offsetHeight || 50) + 20

  // 左右: 余白のみ
  const leftPadding = 50
  const rightPadding = 50

  return {
    top: topPadding,
    right: rightPadding,
    bottom: bottomPadding,
    left: leftPadding
  }
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
