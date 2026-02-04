import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  addSuggestionMarker,
  addSuggestionOverlay,
} from "map/state"
import { showInfoWindowWithFrame, closeInfoWindow } from "map/infowindow"
import { createSuggestionPinSvg } from "map/constants"

// ================================================================
// SuggestionSpotsBatchController
// 用途: 提案スポットカードを一括処理してマップにピン表示
// - DB検証済みスポットをマーカー表示
// - 円は既にパン済みなのでfitBoundsは不要
//
// パルスアニメーション設計:
//   google.maps.Circle はメートル単位のため、ズームレベルで見え方が変わる。
//   ピクセル単位で一貫した表示を実現するため、OverlayView + CSS を採用。
//   → アニメーション定義: app/assets/stylesheets/suggestions/_suggestion_chat.scss
// ================================================================

// パルスオーバーレイを作成（Google Maps API読み込み後に呼び出す）
const createPulseOverlay = (position) => {
  const overlay = new google.maps.OverlayView()

  overlay.onAdd = function () {
    this.div = document.createElement("div")
    this.div.className = "suggestion-pulse-overlay"
    this.div.innerHTML = '<div class="suggestion-pulse-ring"></div>'
    this.getPanes().overlayLayer.appendChild(this.div)
  }

  overlay.draw = function () {
    if (!this.div) return
    const pos = this.getProjection()?.fromLatLngToDivPixel(position)
    if (pos) {
      this.div.style.left = `${pos.x}px`
      this.div.style.top = `${pos.y}px`
    }
  }

  overlay.onRemove = function () {
    this.div?.remove()
    this.div = null
  }

  return overlay
}

export default class extends Controller {
  static values = {
    autoShow: { type: Boolean, default: false },  // 自動でピン表示（デフォルトoff）
  }

  connect() {
    this._isConnected = true
    // autoShow が true の場合のみ自動でピン表示
    if (this.autoShowValue) {
      // 少し遅延してから処理開始（DOM安定化のため）
      setTimeout(() => this.#processAllSpots(), 100)
    }
  }

  disconnect() {
    this._isConnected = false
  }

  #processAllSpots() {
    const map = getMapInstance()
    if (!map) return

    // 子要素からスポットカードを取得
    const cards = this.element.querySelectorAll("[data-controller*='suggestion--suggested-spot']")
    if (cards.length === 0) return

    // 各カードからDB検証済み情報を抽出
    const spotInfos = Array.from(cards).map((card, index) => ({
      card,
      name: card.dataset["suggestion-SuggestedSpotNameValue"],
      planId: card.dataset["suggestion-SuggestedSpotPlanIdValue"],
      number: index + 1,
      spotId: parseInt(card.dataset["suggestion-SuggestedSpotSpotIdValue"], 10),
      lat: parseFloat(card.dataset["suggestion-SuggestedSpotLatValue"]),
      lng: parseFloat(card.dataset["suggestion-SuggestedSpotLngValue"]),
      placeId: card.dataset["suggestion-SuggestedSpotPlaceIdValue"],
    }))

    // 有効なスポット（座標あり）のみ処理
    const validSpots = spotInfos.filter((s) => !isNaN(s.spotId) && !isNaN(s.lat) && !isNaN(s.lng))
    if (validSpots.length === 0) return

    // 全マーカーを一括作成（円は既にパン済みなのでfitBoundsは不要）
    validSpots.forEach((info) => {
      const position = { lat: info.lat, lng: info.lng }

      // マーカー作成（zIndexで番号順に重なるよう制御）
      const marker = new google.maps.Marker({
        map,
        position,
        title: info.name,
        zIndex: 1000 - info.number,  // 番号が小さいほど前面に表示
        icon: {
          url: createSuggestionPinSvg(info.number),
          scaledSize: new google.maps.Size(32, 32),
          anchor: new google.maps.Point(16, 16),
        },
      })

      // パルスオーバーレイ作成
      const latLng = new google.maps.LatLng(position.lat, position.lng)
      const pulse = createPulseOverlay(latLng)
      pulse.setMap(map)
      addSuggestionOverlay(pulse)

      const spotData = { spot_id: info.spotId, lat: info.lat, lng: info.lng, place_id: info.placeId }
      marker.addListener("click", () => {
        this.#showInfoWindow(marker, spotData, info.planId)
      })

      addSuggestionMarker(marker)

      // 子コントローラーにマーカーとspotDataを保存
      const controller = this.application.getControllerForElementAndIdentifier(
        info.card,
        "suggestion--suggested-spot"
      )
      if (controller) {
        controller._marker = marker
        controller._spotData = spotData
      }
    })

    // 提案ピンクリアボタンを表示
    const clearBtn = document.getElementById("suggestion-pin-clear")
    if (clearBtn) clearBtn.hidden = false
  }

  // InfoWindow表示
  #showInfoWindow(marker, spotData, planId) {
    closeInfoWindow()
    showInfoWindowWithFrame({
      anchor: marker,
      spotId: spotData.spot_id,
      placeId: spotData.place_id,
      lat: spotData.lat,
      lng: spotData.lng,
      showButton: true,
      planId: planId || document.getElementById("map")?.dataset.planId,
    })
  }
}
