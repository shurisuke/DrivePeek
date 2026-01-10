import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  setSpotPinMarker,
  clearSpotPinMarker,
} from "map/state"
import { showInfoWindowForPin, closeInfoWindow } from "map/infowindow"

// ================================================================
// SingleSpotPreviewController
// 用途: プランカード・スポットカードのクリック時に
//       該当スポットを地図上にピン表示する
// ================================================================

const SPOT_PIN_COLOR = "#3B82F6"

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
    clearSpotPinMarker()

    const position = { lat: this.latValue, lng: this.lngValue }

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
      showInfoWindowForPin({
        marker,
        name: this.nameValue,
        address: this.addressValue,
      })
    })

    setSpotPinMarker(marker)
    map.panTo(position)
    showInfoWindowForPin({
      marker,
      name: this.nameValue,
      address: this.addressValue,
    })
  }
}
