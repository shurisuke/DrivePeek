// ================================================================
// InfoWindow（単一責務）
// 用途: InfoWindowの生成・表示・イベント処理を一元管理
// ================================================================

import { getMapInstance } from "map/state"
import { normalizeDisplayAddress } from "map/geocoder"

// 1個だけ使い回す（シングルトン）
let infoWindow = null
let mapClickListener = null

/**
 * place_idからプラン内のスポットを検索
 * @param {string} placeId - Google Place ID
 * @returns {{ planSpotId: string } | null} - 見つかった場合はplanSpotIdを返す
 */
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

/**
 * 地図クリック時にInfoWindowを閉じるリスナーを設定
 */
const setupMapClickToClose = () => {
  const map = getMapInstance()
  if (!map || mapClickListener) return

  mapClickListener = map.addListener("click", () => {
    closeInfoWindow()
  })
}


/**
 * InfoWindow を閉じる
 */
export const closeInfoWindow = () => {
  if (infoWindow) {
    infoWindow.close()
  }
}

/**
 * InfoWindow用HTMLを生成
 * @param {Object} options
 * @param {string} options.photoUrl - 写真URL（なければプレースホルダー）
 * @param {string} options.name - 名称
 * @param {string} options.address - 住所
 * @param {string} options.buttonId - ボタンのDOM ID
 * @param {boolean} options.showButton - 「プランに追加」ボタンを表示するか
 * @param {string} [options.buttonLabel] - ボタンのラベル（デフォルト: "プランに追加"）
 * @param {string} [options.planSpotId] - 削除モード時のplanSpotId
 * @param {Array} [options.editButtons] - 編集ボタンの配列 [{id, label}]
 */
const buildInfoWindowHtml = ({ photoUrl, name, address, buttonId, showButton, buttonLabel, planSpotId, editButtons }) => {
  const safeName = name || "名称不明"
  const safeAddress = address || "住所不明"

  // 写真がある場合のみ写真ブロックを表示
  const photoArea = photoUrl
    ? `<div class="dp-infowindow__photo">
        <img class="dp-infowindow__img" src="${photoUrl}" alt="${safeName}">
      </div>`
    : ""

  const label = buttonLabel || "プランに追加"
  const isDeleteMode = !!planSpotId
  const deleteClass = isDeleteMode ? " dp-infowindow__btn--delete" : ""
  const dataAttr = isDeleteMode ? ` data-plan-spot-id="${planSpotId}"` : ""

  const buttonArea = showButton
    ? `<button type="button" class="dp-infowindow__btn${deleteClass}" id="${buttonId}"${dataAttr}>${label}</button>`
    : ""

  // 複数の編集ボタンに対応（variant: "orange" でオレンジボタン）
  const editButtonsArea = (editButtons || [])
    .map(btn => {
      const variantClass = btn.variant ? ` dp-infowindow__edit-btn--${btn.variant}` : ""
      return `<button type="button" class="dp-infowindow__edit-btn${variantClass}" id="${btn.id}">${btn.label}</button>`
    })
    .join("")

  return `
    <div class="dp-infowindow">
      ${photoArea}
      <div class="dp-infowindow__body">
        <div class="dp-infowindow__name">${safeName}</div>
        <div class="dp-infowindow__address">${safeAddress}</div>
        ${buttonArea}
        ${editButtonsArea}
      </div>
    </div>
  `
}

export const extractLatLng = (place) => {
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

/**
 * InfoWindow を表示する（PlaceResult 用）
 * @param {Object} options
 * @param {google.maps.Marker|google.maps.LatLng} options.anchor - InfoWindowを表示する基準
 * @param {Object} options.place - PlaceResult オブジェクト
 * @param {string} options.buttonId - ボタンのDOM ID
 * @param {boolean} [options.showButton=true] - 「プランに追加」ボタンを表示するか
 */
export const showSearchResultInfoWindow = ({ anchor, place, buttonId, showButton = true }) => {
  const map = getMapInstance()
  if (!map) return

  const latLng = extractLatLng(place)
  if (!latLng) return

  const rawAddress = place.formatted_address || place.vicinity || ""
  const address = normalizeDisplayAddress(rawAddress) || rawAddress
  const photoUrl = extractPhotoUrl(place)
  const name = place.name

  // ✅ place_idがプランに存在するかチェック
  const existingSpot = findPlanSpotByPlaceId(place.place_id)
  const isInPlan = !!existingSpot
  const buttonLabel = isInPlan ? "プランから削除" : "プランに追加"
  const planSpotId = existingSpot?.planSpotId || null

  // 地図クリック時にInfoWindowを閉じるリスナーを設定
  setupMapClickToClose()

  const iw = getInfoWindow()
  iw.setContent(
    buildInfoWindowHtml({
      photoUrl,
      name,
      address,
      buttonId,
      showButton,
      buttonLabel,
      planSpotId,
    })
  )

  // anchor が Marker の場合と LatLng の場合で分岐
  if (anchor instanceof google.maps.Marker) {
    iw.open({ map, anchor })
  } else {
    iw.setPosition(anchor)
    iw.open(map)
  }

  // ボタン非表示の場合はイベント設定不要
  if (!showButton) return

  // domready 後にボタンへ click を付ける
  google.maps.event.addListenerOnce(iw, "domready", () => {
    const btn = document.getElementById(buttonId)
    if (!btn) return

    btn.addEventListener("click", () => {
      const planSpotId = btn.dataset.planSpotId

      if (planSpotId) {
        // 削除モード
        document.dispatchEvent(new CustomEvent("spot:delete", {
          detail: { buttonId, planSpotId }
        }))
      } else {
        // 追加モード
        document.dispatchEvent(new CustomEvent("spot:add", {
          detail: {
            buttonId,
            place_id: place.place_id,
            name: name || null,
            address: address || null,
            lat: latLng.lat,
            lng: latLng.lng,
            types: Array.isArray(place.types) ? place.types : [],
          },
        }))
      }
    })
  })
}

/**
 * InfoWindow を表示する（シンプルなピン用）
 * プランスポット/出発/帰宅などPlaceResultを持たないピン向け
 * @param {Object} options
 * @param {google.maps.Marker} options.marker - 対象マーカー
 * @param {string} options.name - 名称
 * @param {string} [options.address] - 住所
 * @param {string} [options.photoUrl] - 写真URL
 * @param {Array} [options.editButtons] - 編集ボタンの配列 [{id, label, onClick}]
 */
export const showPlanPinInfoWindow = ({ marker, name, address, photoUrl, editButtons }) => {
  const map = getMapInstance()
  if (!map) return

  // 地図クリック時にInfoWindowを閉じるリスナーを設定
  setupMapClickToClose()

  const iw = getInfoWindow()

  iw.setContent(
    buildInfoWindowHtml({
      photoUrl: photoUrl || null,
      name,
      address: address || null,
      buttonId: "",
      showButton: false,
      editButtons: editButtons || [],
    })
  )

  iw.open({ map, anchor: marker })

  // 編集ボタンがある場合はクリックイベントを設定
  if (editButtons && editButtons.length > 0) {
    google.maps.event.addListenerOnce(iw, "domready", () => {
      editButtons.forEach(btn => {
        const editBtn = document.getElementById(btn.id)
        if (!editBtn || !btn.onClick) return

        editBtn.addEventListener("click", () => {
          iw.close()
          btn.onClick()
        })
      })
    })
  }
}
