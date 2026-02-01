import { Controller } from "@hotwired/stimulus"
import { getMapInstance, addSuggestionMarker } from "map/state"
import { showInfoWindowWithFrame, closeInfoWindow } from "map/infowindow"
import { createSuggestionPinSvg } from "map/constants"
import { panToVisualCenter } from "map/visual_center"

// ================================================================
// SuggestionSpotActionController
// 用途: 提案スポットカードの「地図で見る」「プランに追加」ボタン
// フロー: DB検証済みスポットをマーカー表示 + InfoWindow
// ================================================================

export default class extends Controller {
  static values = {
    name: String,
    planId: Number,
    number: { type: Number, default: 1 },  // 表示番号
    spotId: Number,
    lat: Number,
    lng: Number,
    placeId: String,
  }

  // 地図で見る（InfoWindowも表示）
  showOnMap(event) {
    event.preventDefault()
    this.#showSpotOnMap()
  }

  // プランに追加（直接API呼び出し）
  async addToPlan(event) {
    event.preventDefault()

    const button = event.currentTarget
    if (button.disabled) return

    button.disabled = true
    button.innerHTML = '<i class="bi bi-hourglass-split"></i> 追加中...'

    try {
      const planId = this.planIdValue || document.getElementById("map")?.dataset.planId
      const response = await fetch(`/api/plans/${planId}/plan_spots`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')?.content,
          Accept: "text/vnd.turbo-stream.html",
        },
        body: JSON.stringify({ spot_id: this.spotIdValue }),
      })

      if (response.ok) {
        Turbo.renderStreamMessage(await response.text())
        document.dispatchEvent(new CustomEvent("navibar:updated"))

        button.innerHTML = '<i class="bi bi-check-lg"></i> 追加済み'
        button.classList.add("suggestion-spot-card__btn--added")

        // 追加成功後に地図で表示
        this.#showSpotOnMap()
      } else {
        throw new Error("追加に失敗しました")
      }
    } catch (error) {
      console.error("[suggestion_spot_action] addToPlan error:", error)
      alert(error.message || "追加に失敗しました")
      button.disabled = false
      button.innerHTML = 'プランに追加<i class="bi bi-chevron-right"></i>'
    }
  }

  // マーカー表示 + InfoWindow（共通処理）
  #showSpotOnMap() {
    const map = getMapInstance()
    if (!map) return

    closeInfoWindow()

    // 既にマーカーがあれば再利用
    if (this._marker && this._spotData) {
      panToVisualCenter({ lat: this._spotData.lat, lng: this._spotData.lng })
      this.#showInfoWindow(this._marker, this._spotData)
      return
    }

    // マーカー作成
    const spotData = {
      spot_id: this.spotIdValue,
      lat: this.latValue,
      lng: this.lngValue,
      place_id: this.placeIdValue,
    }
    const position = { lat: spotData.lat, lng: spotData.lng }

    const marker = new google.maps.Marker({
      map,
      position,
      title: this.nameValue,
      zIndex: 1000 - this.numberValue,
      icon: {
        url: createSuggestionPinSvg(this.numberValue),
        scaledSize: new google.maps.Size(36, 36),
        anchor: new google.maps.Point(18, 18),
      },
    })

    marker.addListener("click", () => {
      this.#showInfoWindow(marker, spotData)
    })

    addSuggestionMarker(marker)
    this.#showClearButton()
    panToVisualCenter(position)
    this.#showInfoWindow(marker, spotData)

    this._marker = marker
    this._spotData = spotData
  }

  // 提案ピンクリアボタンを表示
  #showClearButton() {
    const clearBtn = document.getElementById("suggestion-pin-clear")
    if (clearBtn) clearBtn.hidden = false
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
