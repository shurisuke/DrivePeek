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
import { setupPoiClickForView } from "map/poi_click"
import { getMapInstance, setSpotPinMarker } from "map/state"
import { showInfoWindow } from "map/infowindow"
import { waitForGoogleMaps, isSpotShowPage } from "map/utils"

console.log("[spots/init_map_show] module loaded")

const SPOT_PIN_COLOR = "#3B82F6"

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
    if (!spotData.placeId) {
      console.warn("[spots/init_map_show] placeId not found")
      return
    }

    const service = getPlacesService()
    if (!service) return

    service.getDetails(
      {
        placeId: spotData.placeId,
        fields: [
          "place_id",
          "name",
          "formatted_address",
          "vicinity",
          "geometry",
          "photos",
        ],
      },
      (place, status) => {
        if (status !== google.maps.places.PlacesServiceStatus.OK || !place) {
          console.warn("[spots/init_map_show] Place詳細取得失敗:", status)
          return
        }

        showInfoWindow({
          anchor: marker,
          place,
          showButton: false,
        })
      }
    )
  })

  setSpotPinMarker(marker)

  // スポット位置にフォーカス
  map.setCenter(position)
  map.setZoom(15)
}

document.addEventListener("turbo:load", async () => {
  console.log("[spots/init_map_show] turbo:load fired")

  const mapElement = document.getElementById("map")
  if (!mapElement) {
    console.log("[spots/init_map_show] #map not found. skip.")
    return
  }

  console.log("[spots/init_map_show] mapElement.dataset.mapMode:", mapElement.dataset.mapMode)

  if (!isSpotShowPage()) {
    console.log("[spots/init_map_show] not spot_show page. skip.")
    return
  }

  console.log("[spots/init_map_show] is spot_show page. initializing...")

  const isGoogleMapsReady = await waitForGoogleMaps()
  if (!isGoogleMapsReady) {
    console.error("[spots/init_map_show] Google Maps API が利用できません")
    return
  }

  console.log("[spots/init_map_show] Google Maps API ready")

  const spotData = getSpotDataFromPage()
  console.log("[spots/init_map_show] spotData:", spotData)

  const center = spotData
    ? { lat: Number(spotData.lat), lng: Number(spotData.lng) }
    : { lat: 35.681236, lng: 139.767125 }

  // 地図生成
  console.log("[spots/init_map_show] renderMap with center:", center)
  renderMap(center)

  // POIクリック（閲覧モード）
  setupPoiClickForView()

  // スポットマーカーを描画
  if (spotData) {
    console.log("[spots/init_map_show] rendering spot marker...")
    renderSpotMarker(spotData)
  }

  console.log("[spots/init_map_show] initialization complete")
})
