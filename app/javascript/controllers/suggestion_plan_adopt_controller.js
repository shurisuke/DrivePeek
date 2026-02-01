import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  clearSuggestionMarkers,
  addSuggestionMarker,
} from "map/state"
import { showInfoWindowWithFrame, closeInfoWindow } from "map/infowindow"
import { createSuggestionPinSvg } from "map/constants"

// ================================================================
// SuggestionPlanAdoptController
// 用途: 提案プランテーマカードの自動ピン表示・採用
// フロー:
//   1. connect時に自動でピン表示
//   2. 採用APIでplan_spotsを一括作成
// ================================================================

export default class extends Controller {
  static values = {
    planId: Number,
    autoShow: { type: Boolean, default: false },  // 自動でピン表示
  }
  static targets = ["spots", "adoptBtn"]

  _resolvedSpots = null

  // 接続時に自動でピン表示
  connect() {
    if (this.autoShowValue) {
      this.#autoLoadSpots()
    }
  }

  // 自動でピン表示
  #autoLoadSpots() {
    this._resolvedSpots = this.#resolveSpots()
    this.#showMarkersOnMap()
  }

  // プランを採用
  async adoptPlan(event) {
    event.preventDefault()

    const btn = this.adoptBtnTarget
    btn.disabled = true
    btn.innerHTML = '<i class="bi bi-hourglass-split"></i> 採用中...'

    try {
      const spots = this._resolvedSpots || this.#resolveSpots()
      if (spots.length === 0) {
        throw new Error("スポットが見つかりませんでした")
      }

      await this.#callAdoptApi(spots)

      btn.innerHTML = '<i class="bi bi-check-lg"></i> 採用済み'
      btn.classList.add("suggestion-plan-card__adopt-btn--adopted")

      // スポットカードの「プランに追加」ボタンを「追加済み」に更新
      this.#markSpotCardsAsAdded()
    } catch (error) {
      console.error("[suggestion_plan_adopt] Error:", error)
      alert(error.message || "プランの採用に失敗しました")
      btn.disabled = false
      btn.innerHTML = '<i class="bi bi-check-circle"></i> このプランを採用'
    }
  }

  // スポット情報を取得（DBから検証済みデータを読み取り）
  #resolveSpots() {
    const spotElements = this.spotsTarget.querySelectorAll(".suggestion-spot-card")
    return Array.from(spotElements).map((el, index) => ({
      index,
      spot_id: parseInt(el.dataset.suggestionSpotActionSpotIdValue, 10),
      lat: parseFloat(el.dataset.suggestionSpotActionLatValue),
      lng: parseFloat(el.dataset.suggestionSpotActionLngValue),
      place_id: el.dataset.suggestionSpotActionPlaceIdValue,
    }))
  }

  // adopt API を呼び出し
  async #callAdoptApi(spots) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
    const response = await fetch(
      `/api/plan_spots/adopt`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          Accept: "text/vnd.turbo-stream.html",
        },
        body: JSON.stringify({
          plan_id: this.planIdValue,
          spots: spots.map((s) => ({ spot_id: s.spot_id })),
        }),
      }
    )

    if (response.ok) {
      // Turbo Stream で自動更新
      const html = await response.text()
      Turbo.renderStreamMessage(html)

      // 提案ピンをクリア
      clearSuggestionMarkers()
      closeInfoWindow()
      const clearBtn = document.getElementById("suggestion-pin-clear")
      if (clearBtn) clearBtn.hidden = true

      // DOM更新を待ってからマーカー再描画（Turbo Streamの処理完了を待つ）
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          document.dispatchEvent(new CustomEvent("navibar:updated"))
          document.dispatchEvent(new CustomEvent("map:route-updated"))
        })
      })
    } else {
      throw new Error("プランの採用に失敗しました")
    }
  }

  // スポットカードの「プランに追加」ボタンを「追加済み」に更新
  #markSpotCardsAsAdded() {
    const buttons = this.spotsTarget.querySelectorAll(".suggestion-spot-card__link--primary")
    buttons.forEach((btn) => {
      btn.innerHTML = '<i class="bi bi-check-lg"></i> 追加済み'
      btn.classList.remove("suggestion-spot-card__link--primary")
      btn.classList.add("suggestion-spot-card__btn--added")
      btn.disabled = true
      btn.removeAttribute("data-action")
    })
  }

  // マップにマーカーを表示
  #showMarkersOnMap() {
    const map = getMapInstance()
    if (!map) return

    const bounds = new google.maps.LatLngBounds()

    this._resolvedSpots.forEach((spot, index) => {
      const position = { lat: spot.lat, lng: spot.lng }
      bounds.extend(position)

      const marker = new google.maps.Marker({
        map,
        position,
        title: spot.name,
        zIndex: 1000 - (index + 1),  // 番号が小さいほど前面に表示
        icon: {
          url: createSuggestionPinSvg(index + 1),
          scaledSize: new google.maps.Size(36, 36),
          anchor: new google.maps.Point(18, 18),
        },
      })

      // クリックでInfoWindow表示
      marker.addListener("click", () => {
        showInfoWindowWithFrame({
          anchor: marker,
          spotId: spot.spot_id,
          placeId: spot.place_id,
          lat: spot.lat,
          lng: spot.lng,
          showButton: true,
          planId: this.planIdValue,
        })
      })

      addSuggestionMarker(marker)
    })

    // モバイル時: ボトムシートで隠れる領域を考慮
    const isMobile = window.innerWidth < 768
    if (isMobile) {
      const bottomSheetHeight = document.querySelector(".navibar")?.offsetHeight || 0
      map.fitBounds(bounds, {
        top: 60,
        right: 16,
        bottom: bottomSheetHeight + 16,
        left: 16,
      })
    } else {
      map.fitBounds(bounds, { padding: 50 })
    }

    // 提案ピンクリアボタンを表示
    const clearBtn = document.getElementById("suggestion-pin-clear")
    if (clearBtn) clearBtn.hidden = false
  }
}
