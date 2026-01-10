// app/javascript/map/community_preview.js
// ================================================================
// コミュニティプランプレビュー
// 用途: みんなのプランタブから「地図で見る」クリック時に
//       該当プランの経路線・スポットピンを表示する
// ================================================================

import {
  getMapInstance,
  setCommunityPreviewMarkers,
  setCommunityPreviewPolylines,
  clearCommunityPreview,
  getPlanSpotMarkers,
  getStartPointMarker,
  getEndPointMarker,
} from "map/state"
import { showInfoWindowForPin, closeInfoWindow } from "map/infowindow"
import { get } from "services/api_client"

// コミュニティプラン用の色（自分のプランと区別）
const COMMUNITY_PIN_COLOR = "#3B82F6" // 青
const COMMUNITY_ROUTE_COLOR = "#3B82F6"

/**
 * 番号付きSVGピンを生成（コミュニティプラン用：青色）
 */
const createCommunityPinSvg = (number) => {
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
      <circle cx="18" cy="18" r="17" fill="${COMMUNITY_PIN_COLOR}"/>
      <text x="18" y="24" text-anchor="middle" font-size="16" font-weight="700" fill="white">${number}</text>
    </svg>
  `.trim()

  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`
}

/**
 * コミュニティプランのマーカーを描画
 */
const renderCommunityMarkers = (spots) => {
  const map = getMapInstance()
  if (!map) return []

  const markers = spots.map((spot, index) => {
    const spotNumber = index + 1

    const marker = new google.maps.Marker({
      map,
      position: { lat: Number(spot.lat), lng: Number(spot.lng) },
      title: spot.name || `スポット ${spotNumber}`,
      icon: {
        url: createCommunityPinSvg(spotNumber),
        scaledSize: new google.maps.Size(36, 36),
        anchor: new google.maps.Point(18, 18),
      },
    })

    // クリックでInfoWindow表示
    marker.addListener("click", () => {
      showInfoWindowForPin({
        marker,
        name: spot.name || `スポット ${spotNumber}`,
        address: spot.address,
      })
    })

    return marker
  })

  setCommunityPreviewMarkers(markers)
  return markers
}

/**
 * コミュニティプランのポリラインを描画
 */
const renderCommunityPolylines = (polylines) => {
  const map = getMapInstance()
  if (!map) return []

  // geometry library がロードされているか確認
  if (!google?.maps?.geometry?.encoding?.decodePath) {
    console.warn("[community_preview] geometry library not loaded")
    return []
  }

  const renderedPolylines = polylines.map((encoded) => {
    try {
      const path = google.maps.geometry.encoding.decodePath(encoded)
      return new google.maps.Polyline({
        path,
        map,
        strokeColor: COMMUNITY_ROUTE_COLOR,
        strokeOpacity: 0.85,
        strokeWeight: 4,
      })
    } catch (e) {
      console.warn("[community_preview] Failed to decode polyline:", e)
      return null
    }
  }).filter(Boolean)

  setCommunityPreviewPolylines(renderedPolylines)
  return renderedPolylines
}

/**
 * 地図を自分のプランとコミュニティプランの両方が見えるようにフィット
 */
const fitMapToBothPlans = (communitySpots) => {
  const map = getMapInstance()
  if (!map) return

  const bounds = new google.maps.LatLngBounds()
  let pointCount = 0

  // コミュニティプランのスポットを追加
  communitySpots.forEach((spot) => {
    if (spot?.lat && spot?.lng) {
      bounds.extend({ lat: Number(spot.lat), lng: Number(spot.lng) })
      pointCount++
    }
  })

  // 自分のプランのスポットマーカーを追加
  const mySpotMarkers = getPlanSpotMarkers()
  mySpotMarkers.forEach((marker) => {
    const pos = marker.getPosition()
    if (pos) {
      bounds.extend(pos)
      pointCount++
    }
  })

  // 自分のプランの出発地点を追加
  const startMarker = getStartPointMarker()
  if (startMarker) {
    const pos = startMarker.getPosition()
    if (pos) {
      bounds.extend(pos)
      pointCount++
    }
  }

  // 自分のプランの帰宅地点を追加
  const endMarker = getEndPointMarker()
  if (endMarker) {
    const pos = endMarker.getPosition()
    if (pos) {
      bounds.extend(pos)
      pointCount++
    }
  }

  if (pointCount === 0) return

  // 地図上のUI要素に被らないようパディング設定
  const padding = {
    top: 120,     // 検索フォーム + 閉じるボタン分
    bottom: 100,  // 保存ボタン分
    left: 50,
    right: 50,
  }
  map.fitBounds(bounds, padding)

  // ポイントが少ない場合、fitBoundsだとズームしすぎるので調整
  if (pointCount <= 2) {
    google.maps.event.addListenerOnce(map, "bounds_changed", () => {
      if (map.getZoom() > 14) {
        map.setZoom(14)
      }
    })
  }
}

/**
 * コミュニティプランのプレビューを表示
 */
export const showCommunityPlanPreview = async (planId) => {
  console.log("[community_preview] showCommunityPlanPreview", { planId })

  // InfoWindowを閉じる
  closeInfoWindow()

  // 既存のプレビューをクリア
  clearCommunityPreview()

  try {
    const data = await get(`/api/plans/${planId}/preview`)
    console.log("[community_preview] preview data", data)

    if (!data.spots || data.spots.length === 0) {
      console.warn("[community_preview] No spots in plan")
      return
    }

    // マーカーを描画
    renderCommunityMarkers(data.spots)

    // ポリラインを描画
    if (data.polylines && data.polylines.length > 0) {
      renderCommunityPolylines(data.polylines)
    }

    // 地図を自分のプランとコミュニティプランの両方が見えるようにフィット
    fitMapToBothPlans(data.spots)

  } catch (error) {
    console.error("[community_preview] Failed to show preview:", error)
  }
}

/**
 * コミュニティプランのプレビューをクリア
 */
export const hideCommunityPlanPreview = () => {
  console.log("[community_preview] hideCommunityPlanPreview")
  clearCommunityPreview()
}
