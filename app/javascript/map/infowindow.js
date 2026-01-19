// ================================================================
// InfoWindow（単一責務）
// 用途: InfoWindowの生成・表示・イベント処理を一元管理
// HTMLはRails Partialから取得（fetch）
// ================================================================

import { getMapInstance } from "map/state"
import { normalizeDisplayAddress } from "map/geocoder"

// シングルトン
let infoWindow = null
let mapClickListener = null

// ズーム状態を保持（Stimulusコントローラからのイベントで更新）
let currentZoomIndex = 2  // md

// Stimulusからのズーム変更イベントをリッスン
document.addEventListener("infowindow:zoomChange", (e) => {
  if (e.detail?.zoomIndex !== undefined) {
    currentZoomIndex = e.detail.zoomIndex
  }
})

// ================================================================
// ユーティリティ
// ================================================================

const findPlanSpotByPlaceId = (placeId) => {
  if (!placeId) return null
  const spotBlock = document.querySelector(`.spot-block[data-place-id="${placeId}"]`)
  if (!spotBlock) return null
  return { planSpotId: spotBlock.dataset.planSpotId }
}

const getInfoWindow = () => {
  if (!infoWindow) {
    infoWindow = new google.maps.InfoWindow()
  }
  return infoWindow
}

const setupMapClickToClose = () => {
  const map = getMapInstance()
  if (!map || mapClickListener) return

  mapClickListener = map.addListener("click", (event) => {
    if (event.placeId) return
    closeInfoWindow()
  })
}

export const closeInfoWindow = () => {
  if (infoWindow) {
    infoWindow.close()
  }
}

// ================================================================
// Rails API からHTMLを取得
// ================================================================

const fetchInfoWindowHtml = async (params) => {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

  const response = await fetch("/api/map/infowindow", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken,
      "Accept": "text/html"
    },
    body: JSON.stringify({
      ...params,
      zoom_index: currentZoomIndex
    })
  })

  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`)
  }

  return response.text()
}

// ================================================================
// Place データ抽出
// ================================================================

export const extractLatLng = (place) => {
  const loc = place?.geometry?.location
  if (!loc) return null
  const lat = typeof loc.lat === "function" ? loc.lat() : Number(loc.lat)
  const lng = typeof loc.lng === "function" ? loc.lng() : Number(loc.lng)
  if (!Number.isFinite(lat) || !Number.isFinite(lng)) return null
  return { lat, lng }
}

const extractPhotoUrls = (photos, maxCount = 5) => {
  if (!photos || !Array.isArray(photos)) return []
  return photos.slice(0, maxCount).map(photo => {
    if (!photo?.getUrl) return null
    return photo.getUrl({ maxWidth: 520, maxHeight: 260 })
  }).filter(Boolean)
}

// ================================================================
// Stimulus イベントリスナー設定
// ================================================================

const setupStimulusEventListeners = (iw, { place, onAddSpot, onDeleteSpot, onEditAction }) => {
  const infoWindowEl = document.querySelector(".dp-infowindow")
  if (!infoWindowEl) return

  // 閉じるイベント
  infoWindowEl.addEventListener("infowindow:close", () => {
    iw.close()
  })

  // ギャラリー開くイベント
  infoWindowEl.addEventListener("infowindow:openGallery", (e) => {
    const photos = place?.photos || []
    document.dispatchEvent(new CustomEvent("photo-gallery:open", {
      detail: {
        placeId: e.detail?.placeId || place?.place_id,
        photos,
        name: place?.name || "名称不明"
      }
    }))
  })

  // スポット追加イベント
  if (onAddSpot) {
    infoWindowEl.addEventListener("infowindow:addSpot", () => {
      onAddSpot()
    })
  }

  // スポット削除イベント
  if (onDeleteSpot) {
    infoWindowEl.addEventListener("infowindow:deleteSpot", (e) => {
      onDeleteSpot(e.detail?.planSpotId)
    })
  }

  // 編集アクションイベント
  if (onEditAction) {
    infoWindowEl.addEventListener("infowindow:editAction", (e) => {
      onEditAction(e.detail?.action)
    })
  }
}

// ================================================================
// ローディング表示
// ================================================================

export const showLoadingInfoWindow = (position) => {
  const map = getMapInstance()
  if (!map) return

  setupMapClickToClose()

  const iw = getInfoWindow()
  iw.setContent(`
    <div class="dp-infowindow">
      <div class="dp-infowindow__header">
        <button type="button" class="dp-infowindow__close" onclick="this.closest('.gm-style-iw-a')?.querySelector('button.gm-ui-hover-effect')?.click()">
          <i class="bi bi-x-lg"></i>
        </button>
      </div>
      <div class="dp-infowindow__body" style="padding: 24px;">
        <div class="dp-infowindow__loading">
          <div class="dp-infowindow__spinner"></div>
        </div>
      </div>
    </div>
  `)
  iw.setPosition(position)
  iw.open(map)
}

// ================================================================
// 検索結果/POI用 InfoWindow
// ================================================================

export const showSearchResultInfoWindow = async ({
  anchor,
  place,
  buttonId,
  showButton = true,
  buttonLabel: providedButtonLabel = null,
  planSpotId: providedPlanSpotId = null
}) => {
  const map = getMapInstance()
  if (!map) return

  const latLng = extractLatLng(place)
  if (!latLng) return

  const rawAddress = place.formatted_address || place.vicinity || ""
  const address = normalizeDisplayAddress(rawAddress) || rawAddress
  const photoUrls = extractPhotoUrls(place.photos)
  const name = place.name

  // ボタンラベル・planSpotIdが渡されていればそれを使用、なければDOMチェック
  let buttonLabel = providedButtonLabel
  let planSpotId = providedPlanSpotId

  if (showButton && buttonLabel === null) {
    const existingSpot = findPlanSpotByPlaceId(place.place_id)
    const isInPlan = !!existingSpot
    buttonLabel = isInPlan ? "プランから削除" : "プランに追加"
    planSpotId = existingSpot?.planSpotId || null
  }

  setupMapClickToClose()

  const iw = getInfoWindow()

  try {
    const html = await fetchInfoWindowHtml({
      name,
      address,
      photo_urls: photoUrls,
      types: place.types || [],
      place_id: place.place_id,
      show_button: showButton,
      button_label: buttonLabel,
      plan_spot_id: planSpotId
    })

    iw.setContent(html)

    if (anchor instanceof google.maps.Marker) {
      iw.open({ map, anchor })
    } else {
      iw.setPosition(anchor)
      iw.open(map)
    }

    // domready後にStimulusイベントをセットアップ
    google.maps.event.addListenerOnce(iw, "domready", () => {
      setupStimulusEventListeners(iw, {
        place,
        onAddSpot: () => {
          document.dispatchEvent(new CustomEvent("spot:add", {
            detail: {
              buttonId,
              place_id: place.place_id,
              name: name || null,
              address: address || null,
              lat: latLng.lat,
              lng: latLng.lng,
              types: Array.isArray(place.types) ? place.types : []
            }
          }))
        },
        onDeleteSpot: (spotId) => {
          document.dispatchEvent(new CustomEvent("spot:delete", {
            detail: { buttonId, planSpotId: spotId }
          }))
        }
      })
    })
  } catch (error) {
    console.error("InfoWindow fetch error:", error)
  }
}

// ================================================================
// プランピン用 InfoWindow
// ================================================================

export const showPlanPinInfoWindow = async ({ marker, name, address, photoUrl, photos, placeId, editButtons }) => {
  const map = getMapInstance()
  if (!map) return

  setupMapClickToClose()

  const iw = getInfoWindow()

  // photos配列からURL配列を生成
  const photoUrls = photos?.length > 0
    ? extractPhotoUrls(photos)
    : (photoUrl ? [photoUrl] : [])

  // editButtonsをRailsに渡す形式に変換
  const editButtonsForRails = (editButtons || []).map(btn => ({
    id: btn.id,
    label: btn.label,
    variant: btn.variant,
    action: btn.id // アクション識別用
  }))

  try {
    const html = await fetchInfoWindowHtml({
      name,
      address: address || null,
      photo_urls: photoUrls,
      types: [],
      place_id: photos?.length > 0 ? placeId : null,
      show_button: false,
      edit_buttons: editButtonsForRails
    })

    iw.setContent(html)
    iw.open({ map, anchor: marker })

    // domready後にStimulusイベントをセットアップ
    google.maps.event.addListenerOnce(iw, "domready", () => {
      // editButtonsのonClickコールバックをマッピング
      const editActionMap = {}
      ;(editButtons || []).forEach(btn => {
        if (btn.onClick) {
          editActionMap[btn.id] = btn.onClick
        }
      })

      setupStimulusEventListeners(iw, {
        place: { photos, name, place_id: placeId },
        onEditAction: (actionId) => {
          const callback = editActionMap[actionId]
          if (callback) {
            iw.close()
            callback()
          }
        }
      })
    })
  } catch (error) {
    console.error("InfoWindow fetch error:", error)
  }
}
