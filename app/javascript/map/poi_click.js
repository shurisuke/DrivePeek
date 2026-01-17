// ================================================================
// POIクリック処理
// 用途: 地図上のPOI（店舗・施設等）クリック時にInfoWindowを表示
// ================================================================

import { getMapInstance } from "map/state"
import { showSearchResultInfoWindow } from "map/infowindow"

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

/**
 * POIクリックイベントをセットアップ（編集モード用）
 * 追加ボタンを表示する
 */
export const setupPoiClickForEdit = () => {
  const map = getMapInstance()
  if (!map) {
    console.error("[poi_click] map instance not found")
    return
  }

  map.addListener("click", (event) => {
    if (!event.placeId) return
    event.stop()

    const service = getPlacesService()
    if (!service) return

    service.getDetails(
      {
        placeId: event.placeId,
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
          console.warn("POI詳細取得失敗:", status)
          return
        }

        const buttonId = `dp-add-spot-poi-${place.place_id}`

        showSearchResultInfoWindow({
          anchor: event.latLng,
          place,
          buttonId,
          showButton: true,
        })
      }
    )
  })
}

/**
 * POIクリックイベントをセットアップ（閲覧モード用）
 * 追加ボタンを表示しない
 */
export const setupPoiClickForView = () => {
  const map = getMapInstance()
  if (!map) {
    console.error("[poi_click] map instance not found")
    return
  }

  map.addListener("click", (event) => {
    if (!event.placeId) return
    event.stop()

    const service = getPlacesService()
    if (!service) return

    service.getDetails(
      {
        placeId: event.placeId,
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
          console.warn("POI詳細取得失敗:", status)
          return
        }

        showSearchResultInfoWindow({
          anchor: event.latLng,
          place,
          showButton: false,
        })
      }
    )
  })
}
