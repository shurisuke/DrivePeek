// ================================================================
// SearchBox（単一責務）
// 用途: 検索ボックスをmapに紐づけ、検索ヒットマーカーを管理する
// ================================================================

import {
  getMapInstance,
  clearSearchHitMarkers,
  setSearchHitMarkers,
} from "map/state"
import { normalizeDisplayAddress } from "map/geocoder"

const buildInfoWindowHtml = ({ photoUrl, name, address, buttonId }) => {
  const safeName = name || "名称不明"
  const safeAddress = address || "住所不明"

  const photoArea = photoUrl
    ? `<img class="dp-infowindow__img" src="${photoUrl}" alt="${safeName}">`
    : `<div class="dp-infowindow__noimg">photo reference から画像URLを生成して表示</div>`

  return `
    <div class="dp-infowindow">
      <div class="dp-infowindow__photo">
        ${photoArea}
      </div>

      <div class="dp-infowindow__body">
        <div class="dp-infowindow__name">${safeName}</div>
        <div class="dp-infowindow__address">${safeAddress}</div>

        <button type="button" class="dp-infowindow__btn" id="${buttonId}">
          プランに追加
        </button>
      </div>
    </div>
  `
}

const extractLatLng = (place) => {
  const loc = place?.geometry?.location
  if (!loc) return null
  // LatLng は関数のことが多い
  const lat = typeof loc.lat === "function" ? loc.lat() : Number(loc.lat)
  const lng = typeof loc.lng === "function" ? loc.lng() : Number(loc.lng)
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null
  return { lat, lng }
}

const extractPhotoUrl = (place) => {
  // PlaceResult.photos[0].getUrl() が使えることが多い
  const photo = place?.photos?.[0]
  if (!photo?.getUrl) return null
  return photo.getUrl({ maxWidth: 520, maxHeight: 260 })
}

const extractPhotoReference = (place) => {
  // ここは環境により取れないことがあります（取れなければ null でOK）
  const photo = place?.photos?.[0]
  return photo?.photo_reference || null
}

export const setupSearchBox = () => {
  const map = getMapInstance()
  const input = document.getElementById("places-search-box")
  if (!input || !map) return

  const searchBox = new google.maps.places.SearchBox(input)

  // 1個だけ使い回す（毎回newすると閉じ忘れやイベントが増えがち）
  const infoWindow = new google.maps.InfoWindow()

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

      // ★ クリックでInfoWindow表示
      marker.addListener("click", () => {
        const latLng = extractLatLng(place)
        if (!latLng) return

        const rawAddress = place.formatted_address || place.vicinity || ""
        const address = normalizeDisplayAddress(rawAddress) || rawAddress

        const photoUrl = extractPhotoUrl(place)
        const buttonId = `dp-add-spot-${place.place_id || index}`

        infoWindow.setContent(
          buildInfoWindowHtml({
            photoUrl,
            name: place.name,
            address,
            buttonId,
          })
        )
        infoWindow.open({ map, anchor: marker })

        // domready 後にボタンへ click を付ける
        google.maps.event.addListenerOnce(infoWindow, "domready", () => {
          const btn = document.getElementById(buttonId)
          if (!btn) return

          btn.addEventListener("click", () => {
            // “プランに追加”の実体処理は別モジュールへ（役割分離）
            document.dispatchEvent(
              new CustomEvent("spot:add", {
                detail: {
                  place_id: place.place_id,
                  name: place.name || null,
                  address: address || null,
                  lat: latLng.lat,
                  lng: latLng.lng,
                  photo_reference: extractPhotoReference(place),
                  // Googleのジャンル（types）をタグとして使う想定
                  types: Array.isArray(place.types) ? place.types : [],
                },
              })
            )
          })
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
  })
}
