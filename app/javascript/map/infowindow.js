// ================================================================
// InfoWindow（単一責務）
// 用途: InfoWindowの生成・表示・イベント処理を一元管理
// 新設計: 全てのケースで統一されたRails APIを使用
// ================================================================

import { getMapInstance } from "map/state"

// シングルトン
let infoWindow = null
let mapClickListener = null

// ズーム状態を保持（Stimulusコントローラからのイベントで更新）
let currentZoomIndex = 2  // md

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

  setupMapClickToClose()

  const iw = getInfoWindow()
  const zoomScale = ["xs", "sm", "md", "lg", "xl"][currentZoomIndex] || "md"

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

  // editMode の場合はスケルトン不要（データは揃っている）
  if (editMode) {
    iw.setContent(`
      <turbo-frame id="infowindow-content" src="/api/infowindow?${params.toString()}">
        <div class="dp-infowindow dp-infowindow--${zoomScale} dp-infowindow--point dp-infowindow--loading"></div>
      </turbo-frame>
    `)

    if (anchor instanceof google.maps.Marker) {
      iw.open({ map, anchor })
    } else {
      iw.setPosition(anchor)
      iw.open(map)
    }
    return
  }

  // スポット用: スケルトン + Turbo Frame で即時表示
  iw.setContent(`
    <turbo-frame id="infowindow-content" src="/api/infowindow?${params.toString()}">
      <div class="dp-infowindow dp-infowindow--${zoomScale}">
        <input type="radio" name="iw-tab" id="iw-tab-info" class="dp-infowindow__tab-radio" checked>
        <input type="radio" name="iw-tab" id="iw-tab-comment" class="dp-infowindow__tab-radio">

        <div class="dp-infowindow__header">
          <div class="dp-infowindow__tabs">
            <label for="iw-tab-info" class="dp-infowindow__tab" style="background:#fff;color:#1c1c1e;box-shadow:0 1px 3px rgba(0,0,0,0.1);">
              <i class="bi bi-geo-alt"></i> スポット
            </label>
            <label for="iw-tab-comment" class="dp-infowindow__tab">
              <i class="bi bi-chat"></i> コメント
            </label>
          </div>
          <div class="dp-infowindow__stats">
            <span class="dp-infowindow__stat"><i class="bi bi-heart"></i> <span class="dp-infowindow__skeleton-text" style="width: 16px;"></span></span>
            <span class="dp-infowindow__stat"><i class="bi bi-chat"></i> <span class="dp-infowindow__skeleton-text" style="width: 16px;"></span></span>
          </div>
          <button type="button" class="dp-infowindow__close" onclick="this.closest('.gm-style-iw-a')?.querySelector('button.gm-ui-hover-effect')?.click()">
            <i class="bi bi-x-lg"></i>
          </button>
        </div>

        <div class="dp-infowindow__panel dp-infowindow__panel--info" style="display: block;">
          <div class="dp-infowindow__photo dp-infowindow__photo--skeleton">
            <div class="dp-infowindow__spinner"></div>
          </div>

          <div class="dp-infowindow__genres">
            ${genres?.length > 0
              ? genres.slice(0, 2).map(g => `<span class="dp-infowindow__genre">${g}</span>`).join("")
              : `<span class="dp-infowindow__genre dp-infowindow__genre--skeleton"></span>
                 <span class="dp-infowindow__genre dp-infowindow__genre--skeleton"></span>`
            }
          </div>

          <div class="dp-infowindow__body">
            <div class="dp-infowindow__name">${name || "<span class=\"dp-infowindow__skeleton-text\" style=\"width: 60%;\"></span>"}</div>
            <div class="dp-infowindow__address">${address || "<span class=\"dp-infowindow__skeleton-text\" style=\"width: 80%;\"></span>"}</div>
            ${planSpotId
              ? `<button type="button"
                         class="dp-infowindow__btn dp-infowindow__btn--delete"
                         data-controller="infowindow-spot-action"
                         data-infowindow-spot-action-url-value="/plans/${planId}/plan_spots/${planSpotId}"
                         data-infowindow-spot-action-method-value="DELETE"
                         data-action="click->infowindow-spot-action#submit">
                   プランから削除
                 </button>`
              : (spotId && planId)
              ? `<button type="button"
                         class="dp-infowindow__btn"
                         data-controller="infowindow-spot-action"
                         data-infowindow-spot-action-url-value="/api/plans/${planId}/plan_spots"
                         data-infowindow-spot-action-method-value="POST"
                         data-infowindow-spot-action-spot-id-value="${spotId}"
                         data-action="click->infowindow-spot-action#submit">
                   プランに追加
                 </button>`
              : `<div class="dp-infowindow__btn dp-infowindow__btn--skeleton"></div>`
            }
          </div>
        </div>
      </div>
    </turbo-frame>
  `)

  // Marker か LatLng かで開き方を分岐
  if (anchor instanceof google.maps.Marker) {
    iw.open({ map, anchor })
  } else {
    iw.setPosition(anchor)
    iw.open(map)
  }

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

