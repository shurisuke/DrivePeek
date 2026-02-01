import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  setSpotPinMarker,
  clearSpotPinMarker,
  getCommunityPreviewMarkers,
} from "map/state"
import { showInfoWindowWithFrame, closeInfoWindow } from "map/infowindow"
import { COLORS } from "map/constants"
import { panToVisualCenter } from "map/visual_center"

// ================================================================
// SingleSpotPreviewController
// 用途: プランカード・スポットカードのクリック時に
//       該当スポットを地図上にピン表示する
// ================================================================

const SPOT_PIN_COLOR = COLORS.COMMUNITY

const createSpotPinSvg = () => {
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
      <defs>
        <linearGradient id="communityGrad" x1="0%" y1="0%" x2="100%" y2="100%">
          <stop offset="0%" style="stop-color:#4A90D9"/>
          <stop offset="100%" style="stop-color:#2C5FA0"/>
        </linearGradient>
      </defs>
      <circle cx="18" cy="18" r="17" fill="url(#communityGrad)"/>
      <circle cx="18" cy="18" r="6" fill="white"/>
    </svg>
  `.trim()
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`
}

export default class extends Controller {
  static values = {
    lat: Number,
    lng: Number,
    name: String,
    address: String,
    placeId: String,
    genres: Array,
  }

  show(event) {
    event.preventDefault()
    event.stopPropagation()

    const map = getMapInstance()
    if (!map) {
      console.warn("[single_spot_preview] Map instance not available")
      return
    }

    closeInfoWindow()

    const position = { lat: this.latValue, lng: this.lngValue }

    // プランプレビュー表示中は既存のマーカーを使用
    const communityMarkers = getCommunityPreviewMarkers()
    const existingMarker = communityMarkers.find((m) => {
      const pos = m.getPosition()
      if (!pos) return false
      return Math.abs(pos.lat() - position.lat) < 0.0001 &&
             Math.abs(pos.lng() - position.lng) < 0.0001
    })

    if (existingMarker) {
      // 既存マーカーがあればそれを使用（新しいマーカーは作らない）
      panToVisualCenter(position)
      this.#showInfoWindow(existingMarker)
      return
    }

    // 既存マーカーがなければ新規作成
    clearSpotPinMarker()

    const marker = new google.maps.Marker({
      map,
      position,
      title: this.nameValue || "スポット",
      icon: {
        url: createSpotPinSvg(),
        scaledSize: new google.maps.Size(36, 36),
        anchor: new google.maps.Point(18, 18),
      },
    })

    marker.addListener("click", () => {
      this.#showInfoWindow(marker)
    })

    setSpotPinMarker(marker)
    panToVisualCenter(position)
    this.#showInfoWindow(marker)
  }

  #showInfoWindow(marker) {
    showInfoWindowWithFrame({
      anchor: marker,
      placeId: this.placeIdValue,
      name: this.nameValue,
      address: this.addressValue,
      genres: this.genresValue || [],
      showButton: true,
      planId: document.getElementById("map")?.dataset.planId,
    })
  }
}
