import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  addAiSuggestionMarker,
  addAiSuggestionOverlay,
  clearAiSuggestionMarkers,
} from "map/state"
import { showInfoWindowWithFrame, closeInfoWindow } from "map/infowindow"
import { createAiSuggestionPinSvg } from "map/constants"

// ================================================================
// AiSpotsBatchController
// 用途: AI提案スポットカードを一括処理してマップにピン表示
// - サーバー側で一括Geocode + Spot解決（1リクエスト）
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
  connect() {
    this._isConnected = true

    // 既存のAI提案マーカーをクリア（オーバーレイも含む）
    clearAiSuggestionMarkers()

    // 少し遅延してから処理開始（DOM安定化のため）
    setTimeout(() => this.#processAllSpots(), 100)
  }

  disconnect() {
    this._isConnected = false
  }

  async #processAllSpots() {
    const map = getMapInstance()
    if (!map) return

    // 子要素からスポットカードを取得
    const cards = this.element.querySelectorAll("[data-controller*='ai-spot-action']")
    if (cards.length === 0) return

    // 各カードから情報を抽出
    const spotInfos = Array.from(cards).map((card, index) => ({
      card,
      name: card.dataset.aiSpotActionNameValue,
      address: card.dataset.aiSpotActionAddressValue,
      planId: card.dataset.aiSpotActionPlanIdValue,
      number: index + 1,
    }))

    // サーバーAPIで一括解決
    const resolvedSpots = await this.#resolveBatch(spotInfos)
    if (resolvedSpots.length === 0) return

    // 全マーカーを一括作成
    const bounds = new google.maps.LatLngBounds()

    resolvedSpots.forEach(({ spotData, info }) => {
      const position = { lat: spotData.lat, lng: spotData.lng }
      bounds.extend(position)

      // マーカー作成
      const marker = new google.maps.Marker({
        map,
        position,
        title: info.name,
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
    if (resolvedSpots.length === 1) {
      map.panTo(resolvedSpots[0].spotData)
      map.setZoom(15)
    } else {
      map.fitBounds(bounds, { padding: 50 })
    }

    // AI提案ピンクリアボタンを表示
    const clearBtn = document.getElementById("ai-suggestion-clear")
    if (clearBtn) clearBtn.hidden = false
  }

  // サーバーAPIで一括解決
  async #resolveBatch(spotInfos) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    const spots = spotInfos.map((info) => ({
      name: info.name,
      address: info.address,
    }))

    try {
      const response = await fetch("/api/ai_spots/resolve_batch", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
        },
        body: JSON.stringify({ spots }),
      })

      if (!response.ok) return []

      const data = await response.json()

      // 成功したスポットのみ返す
      return data.spots
        .filter((spot) => !spot.error && spot.lat && spot.lng)
        .map((spot) => ({
          spotData: spot,
          info: spotInfos[spot.index],
        }))
    } catch {
      return []
    }
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
