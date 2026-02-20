// ================================================================
// InfoWindow（単一責務）
// 用途: InfoWindowの生成・表示・イベント処理を一元管理
// 新設計: 全てのケースで統一されたRails APIを使用
// ================================================================

import { getMapInstance } from "map/state"
import { panToVisualCenter } from "map/visual_center"

// シングルトン
let infoWindow = null

// ズーム状態を保持（Stimulusコントローラからのイベントで更新）
let currentZoomIndex = 1  // md（4段階: sm=0, md=1, lg=2, xl=3）

// Stimulusからのズーム変更イベントをリッスン
document.addEventListener("infowindow--ui:zoomChange", (e) => {
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
  // モバイルの場合はモバイルInfoWindowも閉じる
  if (isMobile()) {
    closeMobileInfoWindow()
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
  const currentMapMode = getMapMode()
  const buttonSlot = clone.querySelector('[data-slot="button"]')

  if (currentMapMode === "show") {
    // プラン詳細画面: ボタンなし（地図下部の「このプランで作る」ボタンを使用）
    if (buttonSlot) {
      buttonSlot.innerHTML = ""
    }
  } else if (currentMapMode === "spot_show") {
    // スポット詳細画面: 「ここからプランを作る」
    if (buttonSlot && spotId) {
      if (isUserSignedIn()) {
        buttonSlot.innerHTML = `<a href="/plans?add_spot=${spotId}"
          class="dp-infowindow__btn dp-infowindow__btn--create"
          data-controller="ui--create-plan-trigger"
          data-ui--create-plan-trigger-url-value="/plans?add_spot=${spotId}"
          data-action="click->ui--create-plan-trigger#create">
          ここからプランを作る
        </a>`
      } else {
        buttonSlot.innerHTML = `<a href="/users/sign_in"
          class="dp-infowindow__btn dp-infowindow__btn--create"
          data-turbo-frame="_top">
          ここからプランを作る
        </a>`
      }
    }
  } else if (showButton && planId) {
    // 編集画面: プランに追加/削除
    if (buttonSlot) {
      if (planSpotId) {
        buttonSlot.innerHTML = `<button type="button"
          class="dp-infowindow__btn dp-infowindow__btn--delete"
          data-controller="infowindow--spot-action"
          data-infowindow--spot-action-method-value="DELETE"
          data-infowindow--spot-action-plan-spot-id-value="${planSpotId}"
          data-infowindow--spot-action-plan-id-value="${planId}"
          data-action="click->infowindow--spot-action#submit">
          プランから削除
        </button>`
      } else if (spotId) {
        buttonSlot.innerHTML = `<button type="button"
          class="dp-infowindow__btn"
          data-controller="infowindow--spot-action"
          data-infowindow--spot-action-method-value="POST"
          data-infowindow--spot-action-spot-id-value="${spotId}"
          data-infowindow--spot-action-plan-id-value="${planId}"
          data-action="click->infowindow--spot-action#submit">
          プランに追加
        </button>`
      } else {
        // placeIdのみの場合（新規スポット）: 無効化ボタンを表示（Turbo Frame読み込み後に有効化）
        buttonSlot.innerHTML = `<button type="button"
          class="dp-infowindow__btn"
          disabled>
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

// 地図モード取得（"show" = プラン詳細画面, "spot_show" = スポット詳細画面）
const getMapMode = () => document.getElementById("map")?.dataset?.mapMode || null

// ユーザーログイン状態を取得
const isUserSignedIn = () => document.getElementById("map")?.dataset?.userSignedIn === "true"

// プランIDを取得（プラン詳細画面用）
const getPlanIdFromMap = () => document.getElementById("map")?.dataset?.planId || null

// モバイル判定（768px未満）
const isMobile = () => window.innerWidth < 768

// モバイル用InfoWindow表示
const showMobileInfoWindow = async ({
  spotId, placeId, name, address, genres, lat, lng,
  showButton, planId, planSpotId, editMode, defaultTab
}) => {
  // クエリパラメータを構築
  const params = new URLSearchParams({
    show_button: showButton,
    mobile: "true"  // モバイル用パーシャルを要求
  })
  if (spotId) params.append("spot_id", spotId)
  if (placeId) params.append("place_id", placeId)
  if (name) params.append("name", name)
  if (address) params.append("address", address)
  if (lat) params.append("lat", lat)
  if (lng) params.append("lng", lng)
  if (planId) params.append("plan_id", planId)
  if (editMode) params.append("edit_mode", editMode)
  if (defaultTab) params.append("default_tab", defaultTab)
  const mobileMapMode = getMapMode()
  if (mobileMapMode) params.append("map_mode", mobileMapMode)

  try {
    // APIからHTMLを取得
    const response = await fetch(`/infowindow?${params.toString()}`, {
      headers: { "Accept": "text/html" }
    })
    if (!response.ok) throw new Error("Failed to fetch infowindow")
    const html = await response.text()

    // モバイルInfoWindowを表示
    document.dispatchEvent(new CustomEvent("mobileInfowindow:show", {
      detail: { html }
    }))
  } catch (error) {
    console.error("[showMobileInfoWindow] Error:", error)
  }
}

// モバイルInfoWindowを閉じる
export const closeMobileInfoWindow = () => {
  document.dispatchEvent(new CustomEvent("mobileInfowindow:close"))
}

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
  editMode = null,  // "start_point" | "goal_point" | null
  defaultTab = null // "comment" | null
}) => {
  const map = getMapInstance()
  if (!map) return

  // モバイルの場合はボトムシートで表示
  if (isMobile()) {
    showMobileInfoWindow({
      spotId, placeId, name, address, genres, lat, lng,
      showButton, planId, planSpotId, editMode, defaultTab
    })
    return
  }

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
  if (defaultTab) params.append("default_tab", defaultTab)
  const desktopMapMode = getMapMode()
  if (desktopMapMode) params.append("map_mode", desktopMapMode)

  // editMode の場合はスケルトン不要（データは揃っている）
  if (editMode) {
    iw.setContent(`
      <turbo-frame id="infowindow-content" src="/infowindow?${params.toString()}">
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
    // ナビバー・ボトムシートを考慮した中央表示
    panToVisualCenter(anchorPos)
    return
  }

  // コメントタブ直接表示の場合はスケルトン不要（コンテンツ読み込みまで非表示）
  if (defaultTab === "comment") {
    iw.setContent(`
      <turbo-frame id="infowindow-content" src="/infowindow?${params.toString()}"></turbo-frame>
    `)
  } else {
    // スポット用: スケルトン + Turbo Frame で即時表示
    const skeletonContent = buildSkeletonContent({
      src: `/infowindow?${params.toString()}`,
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
  }

  // Marker か LatLng かで開き方を分岐
  const anchorPos = anchor instanceof google.maps.Marker ? anchor.getPosition() : anchor
  if (anchor instanceof google.maps.Marker) {
    iw.open({ map, anchor })
  } else {
    iw.setPosition(anchor)
    iw.open(map)
  }

  // ナビバー・ボトムシートを考慮した中央表示
  panToVisualCenter(anchorPos)

  // スポット詳細画面: 地図下部のボタンを更新するためのイベント発火
  if (desktopMapMode === "spot_show" && spotId) {
    document.dispatchEvent(new CustomEvent("spotShow:spotChanged", {
      detail: { spotId }
    }))
  }

  // Turbo Frame ロード後にStimulusイベントリスナーを設定
  google.maps.event.addListenerOnce(iw, "domready", () => {
    const turboFrame = document.getElementById("infowindow-content")
    if (!turboFrame) return

    turboFrame.addEventListener("turbo:frame-load", () => {
      const infoWindowEl = document.querySelector(".dp-infowindow")
      if (!infoWindowEl) return

      // ギャラリー開くイベント
      infoWindowEl.addEventListener("infowindow--ui:openGallery", (e) => {
        document.dispatchEvent(new CustomEvent("photo-gallery:open", {
          detail: {
            photoUrls: e.detail?.photoUrls || [],
            name: infoWindowEl.querySelector(".dp-infowindow__name")?.textContent?.trim() || "名称不明"
          }
        }))
      })
    }, { once: true })
  })
}

