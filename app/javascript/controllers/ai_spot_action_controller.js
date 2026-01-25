import { Controller } from "@hotwired/stimulus"
import { geocodeAddress } from "map/geocoder"
import {
  getMapInstance,
  addAiSuggestionMarker,
  getAiSuggestionMarkers,
} from "map/state"
import { showInfoWindowWithFrame, closeInfoWindow } from "map/infowindow"
import { createAiSuggestionPinSvg } from "map/constants"

// ================================================================
// AiSpotActionController
// 用途: AI提案スポットカードの「地図で見る」「プランに追加」ボタン
// フロー:
//   1. Geocode で lat/lng 取得
//   2. サーバーAPI で既存Spot検索 or 新規作成
//   3. マーカー表示 + InfoWindow
// ================================================================

export default class extends Controller {
  static values = {
    name: String,
    address: String,
    planId: Number,
    number: { type: Number, default: 1 },        // 表示番号
    autoShow: { type: Boolean, default: true },  // 自動でピン表示
  }

  // コントローラ接続時に自動でピン表示
  connect() {
    if (this.autoShowValue) {
      this.#showMarkerOnly()
    }
  }

  // 地図で見る（InfoWindowも表示）
  async showOnMap(event) {
    event.preventDefault()

    const map = getMapInstance()
    if (!map) {
      console.warn("[ai_spot_action] Map instance not available")
      return
    }

    closeInfoWindow()

    // 既にマーカーとspotDataがあれば再利用
    if (this._marker && this._spotData) {
      const position = { lat: this._spotData.lat, lng: this._spotData.lng }
      map.panTo(position)
      this.#showInfoWindow(this._marker, this._spotData)
      return
    }

    // なければ新規取得
    try {
      const geocodeResult = await geocodeAddress(this.addressValue)
      const lat = geocodeResult.location.lat()
      const lng = geocodeResult.location.lng()

      const spotData = await this.#resolveSpot(lat, lng)
      if (!spotData) return

      const position = { lat: spotData.lat, lng: spotData.lng }

      // 既存マーカーがあれば再利用
      const existingMarker = this.#findExistingMarker(position)
      if (existingMarker) {
        map.panTo(position)
        this.#showInfoWindow(existingMarker, spotData)
        return
      }

      // 新規マーカー作成（番号付き）
      const marker = new google.maps.Marker({
        map,
        position,
        title: this.nameValue,
        icon: {
          url: createAiSuggestionPinSvg(this.numberValue),
          scaledSize: new google.maps.Size(36, 36),
          anchor: new google.maps.Point(18, 18),
        },
      })

      marker.addListener("click", () => {
        this.#showInfoWindow(marker, spotData)
      })

      addAiSuggestionMarker(marker)
      this.#showClearButton()
      map.panTo(position)
      this.#showInfoWindow(marker, spotData)

      this._marker = marker
      this._spotData = spotData

    } catch (error) {
      console.error("[ai_spot_action] Error:", error)
      alert("スポットの取得に失敗しました")
    }
  }

  // プランに追加（InfoWindow経由で既存フローを再利用）
  async addToPlan(event) {
    event.preventDefault()

    const button = event.currentTarget
    if (button.disabled) return

    // ボタンを無効化
    button.disabled = true
    const originalText = button.innerHTML
    button.innerHTML = '<i class="bi bi-hourglass-split"></i> 追加中...'

    try {
      // InfoWindowを表示
      await this.showOnMap(event)

      // Turbo Frame読み込み完了を待ってから、InfoWindow内のボタンをクリック
      this.#waitForInfoWindowAndClickAdd(button, originalText)

    } catch (error) {
      console.error("[ai_spot_action] Add to plan error:", error)
      alert(error.message || "プランへの追加に失敗しました")
      button.disabled = false
      button.innerHTML = originalText
    }
  }

  // InfoWindow内の「プランに追加」ボタンを待ってクリック
  #waitForInfoWindowAndClickAdd(cardButton, originalText) {
    const maxAttempts = 20  // 最大2秒待機
    let attempts = 0

    const tryClick = () => {
      attempts++
      const addBtn = document.querySelector('.dp-infowindow__btn:not(.dp-infowindow__btn--delete)')

      if (addBtn) {
        addBtn.click()
        // カードのボタンを「追加済み」に変更
        cardButton.innerHTML = '<i class="bi bi-check-lg"></i> 追加済み'
        cardButton.classList.remove("ai-spot-card__btn--add")
        cardButton.classList.add("ai-spot-card__btn--added")
        return
      }

      if (attempts < maxAttempts) {
        setTimeout(tryClick, 100)
      } else {
        // タイムアウト - ボタンを元に戻す
        console.warn("[ai_spot_action] InfoWindow add button not found")
        cardButton.disabled = false
        cardButton.innerHTML = originalText
      }
    }

    // 少し待ってから開始（Turbo Frame読み込み時間）
    setTimeout(tryClick, 300)
  }

  // サーバーAPIでSpotを解決
  async #resolveSpot(lat, lng) {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    const response = await fetch("/api/ai_spots/resolve", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": csrfToken,
      },
      body: JSON.stringify({
        name: this.nameValue,
        address: this.addressValue,
        lat,
        lng,
      }),
    })

    if (!response.ok) {
      const error = await response.json()
      console.error("[ai_spot_action] API error:", error)
      alert(error.error || "スポットの解決に失敗しました")
      return null
    }

    return response.json()
  }

  // マーカーのみ表示（InfoWindowは開かない）
  async #showMarkerOnly() {
    const map = getMapInstance()
    if (!map) return

    try {
      // Geocode で lat/lng 取得
      const geocodeResult = await geocodeAddress(this.addressValue)
      const lat = geocodeResult.location.lat()
      const lng = geocodeResult.location.lng()

      // サーバーAPI で Spot 解決
      const spotData = await this.#resolveSpot(lat, lng)
      if (!spotData) return

      const position = { lat: spotData.lat, lng: spotData.lng }

      // 既存マーカーがあればスキップ
      if (this.#findExistingMarker(position)) return

      // マーカー作成（番号付き）
      const marker = new google.maps.Marker({
        map,
        position,
        title: this.nameValue,
        icon: {
          url: createAiSuggestionPinSvg(this.numberValue),
          scaledSize: new google.maps.Size(36, 36),
          anchor: new google.maps.Point(18, 18),
        },
      })

      // クリックでInfoWindow表示
      marker.addListener("click", () => {
        this.#showInfoWindow(marker, spotData)
      })

      addAiSuggestionMarker(marker)
      this.#showClearButton()

      // spotDataを保持（後でshowOnMapで使用）
      this._spotData = spotData
      this._marker = marker

    } catch (error) {
      console.warn("[ai_spot_action] Auto-show marker failed:", error.message)
    }
  }

  // AI提案ピンクリアボタンを表示
  #showClearButton() {
    const clearBtn = document.getElementById("ai-suggestion-clear")
    if (clearBtn) clearBtn.hidden = false
  }

  // 既存のAI提案マーカーを探す
  #findExistingMarker(position) {
    const markers = getAiSuggestionMarkers()
    return markers.find((m) => {
      const pos = m.getPosition()
      if (!pos) return false
      return (
        Math.abs(pos.lat() - position.lat) < 0.0001 &&
        Math.abs(pos.lng() - position.lng) < 0.0001
      )
    })
  }

  // InfoWindow表示（spot_idを使用）
  #showInfoWindow(marker, spotData) {
    showInfoWindowWithFrame({
      anchor: marker,
      spotId: spotData.spot_id,
      placeId: spotData.place_id,
      lat: spotData.lat,
      lng: spotData.lng,
      showButton: true,
      planId: this.planIdValue || document.getElementById("map")?.dataset.planId,
    })
  }
}
