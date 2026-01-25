// ================================================================
// InfoWindow（単一責務）
// 用途: InfoWindowの生成・表示・イベント処理を一元管理
// 新設計: 全てのケースで統一されたRails APIを使用
// ================================================================

import { getMapInstance } from "map/state"

// シングルトン
let infoWindow = null

// ズーム状態を保持（Stimulusコントローラからのイベントで更新）
let currentZoomIndex = 1  // md（4段階: sm=0, md=1, lg=2, xl=3）

// Stimulusからのズーム変更イベントをリッスン
document.addEventListener("infowindow-ui:zoomChange", (e) => {
  if (e.detail?.zoomIndex !== undefined) {
    currentZoomIndex = e.detail.zoomIndex
  }
})

// ================================================================
// ユーティリティ
// ================================================================

const getInfoWindow = () => {
  if (!infoWindow) {
    infoWindow = new google.maps.InfoWindow({
      pixelOffset: new google.maps.Size(0, -30),
      disableAutoPan: true
    })
  }
  return infoWindow
}

export const closeInfoWindow = () => {
  if (infoWindow) {
    infoWindow.close()
  }
}

// place_idからプラン内のスポット情報を取得（DOMを単一の情報源として使用）
const findPlanSpotByPlaceId = (placeId) => {
  if (!placeId) return null
  // CSSセレクタ注入を避けるため、全要素を取得してからフィルタ
  const blocks = document.querySelectorAll('.spot-block[data-place-id]')
  const block = Array.from(blocks).find(b => b.dataset.placeId === placeId)
  if (!block) return null
  return {
    planSpotId: block.dataset.planSpotId,
    spotId: block.dataset.spotId
  }
}

// スケルトンHTMLを構築（テンプレートから生成）
const buildSkeletonContent = ({ src, zoomScale, name, address, genres, showButton, planId, planSpotId, spotId, placeId }) => {
  // place_idからプラン内のスポットを検索（DOMベース）
  if (!planSpotId && !spotId && placeId) {
    const found = findPlanSpotByPlaceId(placeId)
    if (found) {
      planSpotId = found.planSpotId
      spotId = found.spotId
    }
  }
  const template = document.getElementById("infowindow-skeleton-template")
  if (!template) {
    // テンプレートがない場合はシンプルなローディング表示
    return `<turbo-frame id="infowindow-content" src="${src}">
      <div class="dp-infowindow dp-infowindow--${zoomScale} dp-infowindow--loading">
        <div class="dp-infowindow__spinner"></div>
      </div>
    </turbo-frame>`
  }

  const clone = template.content.cloneNode(true)
  const wrapper = clone.querySelector(".dp-infowindow")
  wrapper.classList.add(`dp-infowindow--${zoomScale}`)

  // 名前・住所が渡された場合は表示
  if (name) {
    const nameEl = clone.querySelector('[data-slot="name"]')
    if (nameEl) nameEl.textContent = name
  }
  if (address) {
    const addressEl = clone.querySelector('[data-slot="address"]')
    if (addressEl) addressEl.textContent = address
  }

  // ジャンルが渡された場合は表示
  if (genres?.length > 0) {
    const genresEl = clone.querySelector('[data-slot="genres"]')
    if (genresEl) {
      genresEl.innerHTML = genres.slice(0, 2)
        .map(g => `<span class="dp-infowindow__genre">${g}</span>`)
        .join("")
    }
  }

  // ボタン
  if (showButton && planId) {
    const buttonSlot = clone.querySelector('[data-slot="button"]')
    if (buttonSlot) {
      if (planSpotId) {
        buttonSlot.innerHTML = `<button type="button"
          class="dp-infowindow__btn dp-infowindow__btn--delete"
          data-controller="infowindow-spot-action"
          data-infowindow-spot-action-url-value="/plans/${planId}/plan_spots/${planSpotId}"
          data-infowindow-spot-action-method-value="DELETE"
          data-action="click->infowindow-spot-action#submit">
          プランから削除
        </button>`
      } else if (spotId) {
        buttonSlot.innerHTML = `<button type="button"
          class="dp-infowindow__btn"
          data-controller="infowindow-spot-action"
          data-infowindow-spot-action-url-value="/api/plans/${planId}/plan_spots"
          data-infowindow-spot-action-method-value="POST"
          data-infowindow-spot-action-spot-id-value="${spotId}"
          data-action="click->infowindow-spot-action#submit">
          プランに追加
        </button>`
      }
    }
  }

  // Turbo Frameでラップ
  const turboFrame = document.createElement("turbo-frame")
  turboFrame.id = "infowindow-content"
  turboFrame.src = src
  turboFrame.appendChild(clone)

  // HTML文字列として返す
  const container = document.createElement("div")
  container.appendChild(turboFrame)
  return container.innerHTML
}

// ================================================================
// Turbo Frame 方式 InfoWindow
// POIクリック時にGoogle Places APIをスキップして即時表示
// ================================================================

export const showInfoWindowWithFrame = ({
  anchor,           // LatLng or Marker
  spotId = null,    // 既存spotの場合
  placeId = null,   // POI/検索の場合
  name = null,
  address = null,
  genres = [],      // ジャンル名の配列
  lat = null,
  lng = null,
  showButton = true,
  planId = null,
  planSpotId = null, // 削除モード時のPlanSpot ID
  editMode = null   // "start_point" | "goal_point" | null
}) => {
  const map = getMapInstance()
  if (!map) return

  const iw = getInfoWindow()
  const zoomScale = ["sm", "md", "lg", "xl"][currentZoomIndex] || "md"

  // オフセット: editMode(出発・帰宅)は0px、既存スポットは30px、POIは60px
  const offsetY = editMode ? 0 : (spotId ? -30 : -60)
  iw.setOptions({ pixelOffset: new google.maps.Size(0, offsetY) })

  // クエリパラメータを構築
  const params = new URLSearchParams({
    show_button: showButton,
    zoom_index: currentZoomIndex
  })
  if (spotId) params.append("spot_id", spotId)
  if (placeId) params.append("place_id", placeId)
  if (name) params.append("name", name)
  if (address) params.append("address", address)
  if (lat) params.append("lat", lat)
  if (lng) params.append("lng", lng)
  if (planId) params.append("plan_id", planId)
  if (editMode) params.append("edit_mode", editMode)

  // InfoWindowが画面中央に来るように、アンカー位置を少し南にずらしてパン
  const calcCenteredPosition = (anchorPos) => {
    const bounds = map.getBounds()
    if (!bounds) return anchorPos

    const ne = bounds.getNorthEast()
    const sw = bounds.getSouthWest()
    const latRange = ne.lat() - sw.lat()

    // InfoWindowの高さ分（緯度範囲の30%）北にオフセット
    // → マーカーが画面下部に、InfoWindowが中央に来る
    const offsetLat = latRange * 0.3
    return new google.maps.LatLng(anchorPos.lat() + offsetLat, anchorPos.lng())
  }

  // editMode の場合はスケルトン不要（データは揃っている）
  if (editMode) {
    iw.setContent(`
      <turbo-frame id="infowindow-content" src="/api/infowindow?${params.toString()}">
        <div class="dp-infowindow dp-infowindow--${zoomScale} dp-infowindow--point dp-infowindow--loading"></div>
      </turbo-frame>
    `)

    const anchorPos = anchor instanceof google.maps.Marker ? anchor.getPosition() : anchor
    if (anchor instanceof google.maps.Marker) {
      iw.open({ map, anchor })
    } else {
      iw.setPosition(anchor)
      iw.open(map)
    }
    map.panTo(calcCenteredPosition(anchorPos))
    return
  }

  // スポット用: スケルトン + Turbo Frame で即時表示
  const skeletonContent = buildSkeletonContent({
    src: `/api/infowindow?${params.toString()}`,
    zoomScale,
    name,
    address,
    genres,
    showButton,
    planId,
    planSpotId,
    spotId,
    placeId
  })
  iw.setContent(skeletonContent)

  // Marker か LatLng かで開き方を分岐
  const anchorPos = anchor instanceof google.maps.Marker ? anchor.getPosition() : anchor
  if (anchor instanceof google.maps.Marker) {
    iw.open({ map, anchor })
  } else {
    iw.setPosition(anchor)
    iw.open(map)
  }

  // InfoWindowが画面中央に来るようにパン
  map.panTo(calcCenteredPosition(anchorPos))

  // Turbo Frame ロード後にStimulusイベントリスナーを設定
  google.maps.event.addListenerOnce(iw, "domready", () => {
    const turboFrame = document.getElementById("infowindow-content")
    if (!turboFrame) return

    turboFrame.addEventListener("turbo:frame-load", () => {
      const infoWindowEl = document.querySelector(".dp-infowindow")
      if (!infoWindowEl) return

      // ギャラリー開くイベント
      infoWindowEl.addEventListener("infowindow-ui:openGallery", (e) => {
        document.dispatchEvent(new CustomEvent("photo-gallery:open", {
          detail: {
            photoUrls: e.detail?.photoUrls || [],
            name: name || "名称不明"
          }
        }))
      })
    }, { once: true })
  })
}

