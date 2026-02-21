import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  setCommunityPreviewMarkers,
  setCommunityPreviewPolylines,
  clearCommunityPreview,
  clearSuggestionAll,
  getPlanSpotMarkers,
} from "map/state"
import { showInfoWindowWithFrame, closeInfoWindow } from "map/infowindow"
import { fitBoundsWithPadding } from "map/visual_center"
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
      <defs>
        <linearGradient id="communityGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:#4A90D9"/>
          <stop offset="100%" style="stop-color:#2C5FA0"/>
        </linearGradient>
      </defs>
      <circle cx="18" cy="18" r="17" fill="url(#communityGrad)"/>
      <text x="18" y="25" text-anchor="middle" font-size="19" font-weight="600" font-family="system-ui, -apple-system, sans-serif" fill="white">${number}</text>
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
    spots: Array,
    polylines: Array,
  }

  show(event) {
    event.preventDefault()

    const spots = this.spotsValue
    if (!spots || spots.length === 0) {
      console.warn("[community-plan-preview] No spots in plan")
      return
    }

    closeInfoWindow()
    clearCommunityPreview()

    this.#renderMarkers(spots)

    const polylines = this.polylinesValue
    if (polylines?.length > 0) {
      this.#renderPolylines(polylines)
    }

    this.#fitMapToBothPlans(spots)
    showCloseButton()
  }

  hide() {
    clearCommunityPreview()
    clearSuggestionAll()  // 円エリアもクリア
    hideCloseButton()

    // search_filters_controller に円クリアを通知
    document.dispatchEvent(new CustomEvent("community:circleCleared"))
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
        zIndex: 1000 - spotNumber,  // ポリラインより上に表示
        icon: {
          url: createCommunityPinSvg(spotNumber),
          scaledSize: new google.maps.Size(32, 32),
          anchor: new google.maps.Point(16, 16),
        },
      })

      marker.addListener("click", () => {
        showInfoWindowWithFrame({
          anchor: marker,
          spotId: spot.id,
          placeId: spot.place_id,
          name: spot.name,
          address: spot.address,
          genres: spot.genres || [],
          showButton: true,
          planId: document.getElementById("map")?.dataset.planId,
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

    // 自分のプランのスポット（出発・帰宅地点は個人情報保護のため除外）
    getPlanSpotMarkers().forEach((marker) => {
      const pos = marker.getPosition()
      if (pos) {
        bounds.extend(pos)
        pointCount++
      }
    })

    if (pointCount === 0) return

    fitBoundsWithPadding(bounds)

    if (pointCount <= 2) {
      google.maps.event.addListenerOnce(map, "bounds_changed", () => {
        if (map.getZoom() > 14) map.setZoom(14)
      })
    }
  }
}
