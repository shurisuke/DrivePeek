// ================================================================
// POIクリック処理
// 用途: 地図上のPOI（店舗・施設等）クリック時にInfoWindowを表示
// ================================================================

import { getMapInstance } from "map/state"
import { showSearchResultInfoWindow, showLoadingInfoWindow } from "map/infowindow"

// PlacesService のキャッシュ
let placesService = null

// POI詳細キャッシュ（placeId -> place）
const placeDetailsCache = new Map()

// キャッシュの有効期限（5分）
const CACHE_TTL_MS = 5 * 60 * 1000

const getPlacesService = () => {
  if (!placesService) {
    const map = getMapInstance()
    if (!map) return null
    placesService = new google.maps.places.PlacesService(map)
  }
  return placesService
}

/**
 * キャッシュからPOI詳細を取得
 * @param {string} placeId
 * @returns {Object|null} キャッシュされたplace、または期限切れ/未キャッシュならnull
 */
const getCachedPlace = (placeId) => {
  const cached = placeDetailsCache.get(placeId)
  if (!cached) return null

  const now = Date.now()
  if (now - cached.timestamp > CACHE_TTL_MS) {
    placeDetailsCache.delete(placeId)
    return null
  }
  return cached.place
}

/**
 * POI詳細をキャッシュに保存
 * @param {string} placeId
 * @param {Object} place
 */
const cachePlace = (placeId, place) => {
  placeDetailsCache.set(placeId, {
    place,
    timestamp: Date.now()
  })
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

    // キャッシュチェック
    const cachedPlace = getCachedPlace(event.placeId)
    if (cachedPlace) {
      const buttonId = `dp-add-spot-poi-${cachedPlace.place_id}`
      showSearchResultInfoWindow({
        anchor: event.latLng,
        place: cachedPlace,
        buttonId,
        showButton: true,
      })
      return
    }

    // ローディング表示
    showLoadingInfoWindow(event.latLng)

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

        // キャッシュに保存
        cachePlace(place.place_id, place)

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

    // キャッシュチェック
    const cachedPlace = getCachedPlace(event.placeId)
    if (cachedPlace) {
      showSearchResultInfoWindow({
        anchor: event.latLng,
        place: cachedPlace,
        showButton: false,
      })
      return
    }

    // ローディング表示
    showLoadingInfoWindow(event.latLng)

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

        // キャッシュに保存
        cachePlace(place.place_id, place)

        showSearchResultInfoWindow({
          anchor: event.latLng,
          place,
          showButton: false,
        })
      }
    )
  })
}
