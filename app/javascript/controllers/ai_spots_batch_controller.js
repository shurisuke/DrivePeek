import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  addAiSuggestionMarker,
  addAiSuggestionOverlay,
  clearAiSuggestionMarkers,
} from "map/state"
import { showInfoWindowWithFrame, closeInfoWindow } from "map/infowindow"
import { createAiSuggestionPinSvg } from "map/constants"
import { panToVisualCenter, fitBoundsWithPadding } from "map/visual_center"

// ================================================================
// AiSpotsBatchController
// 用途: AI提案スポットカードを一括処理してマップにピン表示
// - DB検証済みスポットをマーカー表示
// - 全マーカーが収まるようにマップをパン
//
// パルスアニメーション設計:
//   google.maps.Circle はメートル単位のため、ズームレベルで見え方が変わる。
//   ピクセル単位で一貫した表示を実現するため、OverlayView + CSS を採用。
//   → アニメーション定義: app/assets/stylesheets/ai/_ai_suggestion_chat.scss
// ================================================================

// パルスオーバーレイを作成（Google Maps API読み込み後に呼び出す）
const createPulseOverlay = (position) => {
  const overlay = new google.maps.OverlayView()

  overlay.onAdd = function () {
    this.div = document.createElement("div")
    this.div.className = "ai-pulse-overlay"
    this.div.innerHTML = '<div class="ai-pulse-ring"></div>'
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
      // 既存のAI提案マーカーをクリア（オーバーレイも含む）
      clearAiSuggestionMarkers()

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
    const cards = this.element.querySelectorAll("[data-controller*='ai-spot-action']")
    if (cards.length === 0) return

    // 各カードからDB検証済み情報を抽出
    const spotInfos = Array.from(cards).map((card, index) => ({
      card,
      name: card.dataset.aiSpotActionNameValue,
      planId: card.dataset.aiSpotActionPlanIdValue,
      number: index + 1,
      spotId: parseInt(card.dataset.aiSpotActionSpotIdValue, 10),
      lat: parseFloat(card.dataset.aiSpotActionLatValue),
      lng: parseFloat(card.dataset.aiSpotActionLngValue),
      placeId: card.dataset.aiSpotActionPlaceIdValue,
    }))

    // 有効なスポット（座標あり）のみ処理
    const validSpots = spotInfos.filter((s) => !isNaN(s.spotId) && !isNaN(s.lat) && !isNaN(s.lng))
    if (validSpots.length === 0) return

    // 全マーカーを一括作成
    const bounds = new google.maps.LatLngBounds()

    validSpots.forEach((info) => {
      const position = { lat: info.lat, lng: info.lng }
      bounds.extend(position)

      // マーカー作成（zIndexで番号順に重なるよう制御）
      const marker = new google.maps.Marker({
        map,
        position,
        title: info.name,
        zIndex: 1000 - info.number,  // 番号が小さいほど前面に表示
        icon: {
          url: createAiSuggestionPinSvg(info.number),
          scaledSize: new google.maps.Size(36, 36),
          anchor: new google.maps.Point(18, 18),
        },
      })

      // パルスオーバーレイ作成
      const latLng = new google.maps.LatLng(position.lat, position.lng)
      const pulse = createPulseOverlay(latLng)
      pulse.setMap(map)
      addAiSuggestionOverlay(pulse)

      const spotData = { spot_id: info.spotId, lat: info.lat, lng: info.lng, place_id: info.placeId }
      marker.addListener("click", () => {
        this.#showInfoWindow(marker, spotData, info.planId)
      })

      addAiSuggestionMarker(marker)

      // 子コントローラーにマーカーとspotDataを保存
      const controller = this.application.getControllerForElementAndIdentifier(
        info.card,
        "ai-spot-action"
      )
      if (controller) {
        controller._marker = marker
        controller._spotData = spotData
      }
    })

    // 全マーカーが収まるようにマップをフィット
    // モバイル時: ボトムシートで隠れる領域を考慮してオフセット
    const isMobile = window.innerWidth < 768
    const bottomSheetHeight = isMobile
      ? (document.querySelector(".navibar")?.offsetHeight || 0)
      : 0

    if (validSpots.length === 1) {
      const firstSpot = validSpots[0]
      map.panTo({ lat: firstSpot.lat, lng: firstSpot.lng })
      map.setZoom(15)
      if (bottomSheetHeight > 0) {
        setTimeout(() => map.panBy(0, bottomSheetHeight / 2), 100)
      }
    } else {
      const padding = isMobile
        ? { top: 60, right: 16, bottom: bottomSheetHeight + 16, left: 16 }
        : { top: 50, right: 50, bottom: 50, left: 50 }
      map.fitBounds(bounds, padding)
    }

    // AI提案ピンクリアボタンを表示
    const clearBtn = document.getElementById("ai-pin-clear")
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
