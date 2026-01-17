// ================================================================
// SearchBox（単一責務）
// 用途: 検索ボックスをmapに紐づけ、検索ヒットマーカーを管理する
// ================================================================

import {
  getMapInstance,
  clearSearchHitMarkers,
  setSearchHitMarkers,
} from "map/state"
import { showSearchResultInfoWindow, extractLatLng } from "map/infowindow"

export const setupSearchBox = () => {
  const map = getMapInstance()
  const input = document.getElementById("places-search-box")
  if (!input || !map) return

  const searchBox = new google.maps.places.SearchBox(input)

  map.addListener("bounds_changed", () => {
    searchBox.setBounds(map.getBounds())
  })

  searchBox.addListener("places_changed", () => {
    const places = searchBox.getPlaces()
    if (!places || places.length === 0) return

    // ✅ 検索ヒット用マーカーだけ差し直す（プラン系マーカーは触らない）
    clearSearchHitMarkers()

    const bounds = new google.maps.LatLngBounds()
    const newMarkers = []

    places.slice(0, 10).forEach((place, index) => {
      if (!place.geometry?.location) return

      const marker = new google.maps.Marker({
        map,
        position: place.geometry.location,
        title: place.name,
      })

      // ★ クリックで共通InfoWindow表示
      marker.addListener("click", () => {
        const latLng = extractLatLng(place)
        if (!latLng) return

        const buttonId = `dp-add-spot-${place.place_id || index}`
        showSearchResultInfoWindow({
          anchor: marker,
          place,
          buttonId,
          showButton: true,
        })
      })

      newMarkers.push(marker)

      if (place.geometry.viewport) {
        bounds.union(place.geometry.viewport)
      } else {
        bounds.extend(place.geometry.location)
      }
    })

    setSearchHitMarkers(newMarkers)
    map.fitBounds(bounds)

    // ✅ 検索結果クリアボタンを表示
    const clearBtn = document.getElementById("search-hit-clear")
    if (clearBtn && newMarkers.length > 0) {
      clearBtn.hidden = false
    }
  })
}
