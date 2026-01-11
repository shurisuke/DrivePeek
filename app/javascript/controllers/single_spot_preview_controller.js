import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  setSpotPinMarker,
  clearSpotPinMarker,
  getCommunityPreviewMarkers,
} from "map/state"
import { showInfoWindow, closeInfoWindow } from "map/infowindow"
import { COLORS } from "map/constants"

// ================================================================
// SingleSpotPreviewController
// 用途: プランカード・スポットカードのクリック時に
//       該当スポットを地図上にピン表示する
// ================================================================

const SPOT_PIN_COLOR = COLORS.COMMUNITY

// PlacesService のキャッシュ
let placesService = null

const getPlacesService = () => {
  if (!placesService) {
    const map = getMapInstance()
    if (!map) return null
    placesService = new google.maps.places.PlacesService(map)
  }
  return placesService
}

const createSpotPinSvg = () => {
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
      <circle cx="18" cy="18" r="17" fill="${SPOT_PIN_COLOR}"/>
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
      map.panTo(position)
      this.#showInfoWindowWithPhoto(existingMarker)
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
      this.#showInfoWindowWithPhoto(marker)
    })

    setSpotPinMarker(marker)
    map.panTo(position)
    this.#showInfoWindowWithPhoto(marker)
  }

  // Places APIから詳細を取得してInfoWindowを表示
  #showInfoWindowWithPhoto(marker) {
    if (!this.placeIdValue) {
      console.warn("[single_spot_preview] placeId not found")
      return
    }

    const service = getPlacesService()
    if (!service) return

    service.getDetails(
      {
        placeId: this.placeIdValue,
        fields: [
          "place_id",
          "name",
          "formatted_address",
          "vicinity",
          "geometry",
          "photos",
          "types",
        ],
      },
      (place, status) => {
        if (status !== google.maps.places.PlacesServiceStatus.OK || !place) {
          console.warn("[single_spot_preview] Place詳細取得失敗:", status)
          return
        }

        const buttonId = `dp-add-spot-preview-${place.place_id}`

        showInfoWindow({
          anchor: marker,
          place,
          buttonId,
          showButton: true,
        })
      }
    )
  }
}
