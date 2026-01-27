// app/javascript/spots/init_map_show.js
//
// ================================================================
// Map Initializer - スポット詳細画面用
// 用途: スポット詳細画面で map を初期化（閲覧専用）
//       - 地図生成
//       - POIクリック（閲覧モード、追加ボタンなし）
//       - スポットのマーカー表示
//       - スポット位置にフォーカス
// ================================================================

import { renderMap } from "map/render_map"
import { setupPoiClick } from "map/poi_click"
import { getMapInstance, setSpotPinMarker } from "map/state"
import { showInfoWindowWithFrame } from "map/infowindow"
import { panToVisualCenter } from "map/visual_center"
import { waitForGoogleMaps, isSpotShowPage } from "map/utils"
import { COLORS } from "map/constants"

const SPOT_PIN_COLOR = COLORS.COMMUNITY

const createSpotPinSvg = () => {
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
      <circle cx="18" cy="18" r="17" fill="${SPOT_PIN_COLOR}"/>
      <circle cx="18" cy="18" r="6" fill="white"/>
    </svg>
  `.trim()
  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`
}

const getSpotDataFromPage = () => {
  if (typeof window.spotData !== "undefined") {
    return window.spotData
  }
  return null
}

const renderSpotMarker = (spotData) => {
  const map = getMapInstance()
  if (!map || !spotData) return

  const position = { lat: Number(spotData.lat), lng: Number(spotData.lng) }

  const marker = new google.maps.Marker({
    map,
    position,
    title: spotData.name || "スポット",
    icon: {
      url: createSpotPinSvg(),
      scaledSize: new google.maps.Size(36, 36),
      anchor: new google.maps.Point(18, 18),
    },
  })

  marker.addListener("click", () => {
    showInfoWindowWithFrame({
      anchor: marker,
      spotId: spotData.id,
      placeId: spotData.placeId,
      showButton: false,
    })
  })

  setSpotPinMarker(marker)

  // スポット位置にフォーカス（ボトムシートを考慮）
  map.setZoom(15)
  panToVisualCenter(position)
}

document.addEventListener("turbo:load", async () => {
  const mapElement = document.getElementById("map")
  if (!mapElement) return
  if (!isSpotShowPage()) return

  const isGoogleMapsReady = await waitForGoogleMaps()
  if (!isGoogleMapsReady) {
    console.error("[spots/init_map_show] Google Maps API が利用できません")
    return
  }

  const spotData = getSpotDataFromPage()

  const center = spotData
    ? { lat: Number(spotData.lat), lng: Number(spotData.lng) }
    : { lat: 35.681236, lng: 139.767125 }

  renderMap(center)
  setupPoiClick(false)

  if (spotData) {
    renderSpotMarker(spotData)
  }
})
