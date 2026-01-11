import { Controller } from "@hotwired/stimulus"
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
import { COLORS, COMMUNITY_ROUTE_STYLE } from "map/constants"

// ================================================================
// CommunityPlanPreviewController
// 用途: みんなのプランタブから「ルートを見る」クリック時に
//       該当プランの経路線・スポットピンを地図上にプレビュー表示
// ================================================================

const COMMUNITY_PIN_COLOR = COLORS.COMMUNITY

const createCommunityPinSvg = (number) => {
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
      <circle cx="18" cy="18" r="17" fill="${COMMUNITY_PIN_COLOR}"/>
      <text x="18" y="24" text-anchor="middle" font-size="16" font-weight="700" fill="white">${number}</text>
    </svg>
  `.trim()
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`
}

const showCloseButton = () => {
  const btn = document.getElementById("community-preview-close")
  if (btn) btn.hidden = false
}

const hideCloseButton = () => {
  const btn = document.getElementById("community-preview-close")
  if (btn) btn.hidden = true
}

export default class extends Controller {
  static values = {
    planId: Number,
  }

  async show(event) {
    event.preventDefault()

    if (!this.planIdValue) {
      console.warn("[community-plan-preview] planId not set")
      return
    }

    closeInfoWindow()
    clearCommunityPreview()

    try {
      const data = await get(`/api/plans/${this.planIdValue}/preview`)

      if (!data.spots || data.spots.length === 0) {
        console.warn("[community-plan-preview] No spots in plan")
        return
      }

      this.#renderMarkers(data.spots)

      if (data.polylines?.length > 0) {
        this.#renderPolylines(data.polylines)
      }

      this.#fitMapToBothPlans(data.spots)
      showCloseButton()

    } catch (error) {
      console.error("[community-plan-preview] Failed to show preview:", error)
    }
  }

  hide() {
    clearCommunityPreview()
    hideCloseButton()
  }

  // --- Private methods ---

  #renderMarkers(spots) {
    const map = getMapInstance()
    if (!map) return

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
  }

  #renderPolylines(polylines) {
    const map = getMapInstance()
    if (!map) return

    if (!google?.maps?.geometry?.encoding?.decodePath) {
      console.warn("[community-plan-preview] geometry library not loaded")
      return
    }

    const renderedPolylines = polylines.map((encoded) => {
      try {
        const path = google.maps.geometry.encoding.decodePath(encoded)
        return new google.maps.Polyline({
          path,
          map,
          ...COMMUNITY_ROUTE_STYLE,
        })
      } catch (e) {
        console.warn("[community-plan-preview] Failed to decode polyline:", e)
        return null
      }
    }).filter(Boolean)

    setCommunityPreviewPolylines(renderedPolylines)
  }

  #fitMapToBothPlans(communitySpots) {
    const map = getMapInstance()
    if (!map) return

    const bounds = new google.maps.LatLngBounds()
    let pointCount = 0

    // コミュニティプランのスポット
    communitySpots.forEach((spot) => {
      if (spot?.lat && spot?.lng) {
        bounds.extend({ lat: Number(spot.lat), lng: Number(spot.lng) })
        pointCount++
      }
    })

    // 自分のプランのスポット
    getPlanSpotMarkers().forEach((marker) => {
      const pos = marker.getPosition()
      if (pos) {
        bounds.extend(pos)
        pointCount++
      }
    })

    // 出発地点
    const startMarker = getStartPointMarker()
    if (startMarker?.getPosition()) {
      bounds.extend(startMarker.getPosition())
      pointCount++
    }

    // 帰宅地点
    const endMarker = getEndPointMarker()
    if (endMarker?.getPosition()) {
      bounds.extend(endMarker.getPosition())
      pointCount++
    }

    if (pointCount === 0) return

    const padding = { top: 120, bottom: 100, left: 50, right: 50 }
    map.fitBounds(bounds, padding)

    if (pointCount <= 2) {
      google.maps.event.addListenerOnce(map, "bounds_changed", () => {
        if (map.getZoom() > 14) map.setZoom(14)
      })
    }
  }
}
