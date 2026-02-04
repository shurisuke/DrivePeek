// ================================================================
// SearchBox（単一責務）
// 用途: 検索ボックスをmapに紐づけ、検索ヒットマーカーを管理する
// ================================================================

import {
  getMapInstance,
  clearSearchHitMarkers,
  setSearchHitMarkers,
} from "map/state"
import { showInfoWindowWithFrame } from "map/infowindow"
import { fitBoundsWithPadding } from "map/visual_center"

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
        zIndex: 1000 - index,  // ポリラインより上に表示
      })

      // ★ クリックで共通InfoWindow表示（Turbo Frame方式）
      marker.addListener("click", () => {
        const loc = place.geometry?.location
        if (!loc) return

        const lat = typeof loc.lat === "function" ? loc.lat() : Number(loc.lat)
        const lng = typeof loc.lng === "function" ? loc.lng() : Number(loc.lng)

        // 郵便番号を除去（〒XXX-XXXX または 日本、〒XXX-XXXX）
        const rawAddress = place.formatted_address || null
        const address = rawAddress?.replace(/^日本、\s*/, "").replace(/〒\d{3}-\d{4}\s*/, "").trim() || null

        showInfoWindowWithFrame({
          anchor: marker,
          placeId: place.place_id,
          name: place.name,
          address,
          lat,
          lng,
          showButton: true,
          planId: document.getElementById("map")?.dataset.planId,
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
    fitBoundsWithPadding(bounds)

    // ✅ 検索結果クリアボタンを表示
    const clearBtn = document.getElementById("search-hit-clear")
    if (clearBtn && newMarkers.length > 0) {
      clearBtn.hidden = false
    }
  })
}
