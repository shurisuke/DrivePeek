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
 * vh単位で設定されている場合はstyle.heightから計算
 */
const getBottomSheetHeight = () => {
  if (!isMobile()) return 0
  const navibar = document.querySelector(".navibar")
  if (!navibar) return 0

  // style.heightがvh単位の場合、実際のピクセル値に変換
  const styleHeight = navibar.style.height
  if (styleHeight && styleHeight.endsWith("vh")) {
    const vhValue = parseFloat(styleHeight)
    return (vhValue / 100) * window.innerHeight
  }

  // offsetHeightを使用（フォールバック）
  // 最小でも画面の10%は確保（ボトムシートのmin値）
  const height = navibar.offsetHeight
  const minHeight = window.innerHeight * 0.1
  return Math.max(height, minHeight)
}

/**
 * モバイルInfoWindowの現在の高さを取得
 */
const getMobileInfoWindowHeight = () => {
  if (!isMobile()) return 0
  const sheet = document.querySelector(".mobile-infowindow__sheet")
  if (!sheet) return 0
  return sheet.offsetHeight
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
 * モバイル時の障害物の高さを取得（上部・下部）
 */
const getMobileObstacles = () => {
  if (!isMobile()) return { top: 0, bottom: 0 }

  const top = getMobileTopHeight()
  const bottomSheet = getBottomSheetHeight()
  const infoWindow = getMobileInfoWindowHeight()

  return { top, bottom: Math.max(bottomSheet, infoWindow) }
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
  const actionBar = document.querySelector(".map-bottom-actions") || document.querySelector(".plan-actions")
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

  // オフセットを計算
  let offsetY = 0
  if (isMobile()) {
    const { top, bottom } = getMobileObstacles()
    offsetY = (bottom - top) / 2
  } else {
    offsetY = getDesktopOffsetY()
  }

  // オフセットがない or projection未取得の場合は単純にpanTo
  const projection = map.getProjection()
  if (offsetY === 0 || !projection) {
    map.panTo(latLng)
    return
  }

  // ピクセルオフセットをワールド座標に変換し、1回のpanToで完結
  const scale = Math.pow(2, map.getZoom())
  const worldPoint = projection.fromLatLngToPoint(latLng)
  worldPoint.y += offsetY / scale
  map.panTo(projection.fromPointToLatLng(worldPoint))
}

/**
 * fitBounds用のパディングを取得
 * モバイル: ボトムシート考慮
 * デスクトップ: ナビバー幅、検索ボックス、アクションバー、ピン削除ボタン考慮
 * @returns {google.maps.Padding}
 */
export const getMapPadding = () => {
  if (isMobile()) {
    const { top, bottom } = getMobileObstacles()
    return {
      top: top > 0 ? top : 100,
      right: 0,
      bottom: bottom > 0 ? bottom : 0,
      left: 0
    }
  }

  // デスクトップ: 各UI要素を考慮
  // ※ 地図要素自体がナビバーの右側に配置されているため、
  //    leftPaddingにナビバー幅は含めない（二重計算防止）

  // 上部: 検索ボックス + ピン削除ボタン + 余裕
  const searchBox = document.querySelector(".map-search-box")
  const topPadding = (searchBox?.offsetHeight || 50) + 40

  // 下部: アクションバー（共有・保存ボタン）
  const actionBar = document.querySelector(".map-bottom-actions") || document.querySelector(".plan-actions")
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

/**
 * プランの全ポイント（出発・スポット・帰宅）が表示されるように地図をフィットする
 * @param {Object} planData - プランデータ（start_point, spots, end_point を含む）
 */
export const fitMapToSpots = (planData) => {
  const map = getMapInstance()
  if (!map) return

  const bounds = new google.maps.LatLngBounds()
  let pointCount = 0

  // 出発地点
  const startPoint = planData?.start_point
  if (startPoint?.lat && startPoint?.lng) {
    bounds.extend({ lat: Number(startPoint.lat), lng: Number(startPoint.lng) })
    pointCount++
  }

  // スポット
  const spots = planData?.spots || []
  spots.forEach((spot) => {
    if (spot?.lat && spot?.lng) {
      bounds.extend({ lat: Number(spot.lat), lng: Number(spot.lng) })
      pointCount++
    }
  })

  // 帰宅地点はデフォルト非表示のためboundsに含めない

  if (pointCount === 0) return

  fitBoundsWithPadding(bounds)

  // ポイントが1つの場合、fitBoundsだとズームしすぎるので調整
  if (pointCount === 1) {
    google.maps.event.addListenerOnce(map, "bounds_changed", () => {
      if (map.getZoom() > 15) {
        map.setZoom(15)
      }
    })
  }
}
