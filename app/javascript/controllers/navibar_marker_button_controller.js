// app/javascript/controllers/navibar_marker_button_controller.js
//
// ================================================================
// プランバー内マーカーボタン
// 用途: プランバー内のボタンクリックで地図をパン＋InfoWindowを表示
// ================================================================

import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  getPlanSpotMarkers,
  getStartPointMarker,
  getEndPointMarker,
} from "map/state"
import { showInfoWindowForPin } from "map/infowindow"

export default class extends Controller {
  // スポットのボタンクリック
  spot(e) {
    // ✅ 親の .spot-block から座標を取得してマーカーを特定
    const spotBlock = e.currentTarget.closest(".spot-block")
    if (!spotBlock) return

    const lat = parseFloat(spotBlock.dataset.lat)
    const lng = parseFloat(spotBlock.dataset.lng)
    if (isNaN(lat) || isNaN(lng)) return

    const marker = this.#findMarkerByPosition(getPlanSpotMarkers(), lat, lng)
    if (marker) this.#panAndTriggerClick(marker)
  }

  // 出発・帰宅のボタンクリック
  point(e) {
    const type = e.currentTarget.dataset.pointType
    const goalMarker = getEndPointMarker()
    const startMarker = getStartPointMarker()

    let marker = type === "start" ? startMarker : goalMarker

    // ✅ 帰宅マーカーが存在しない場合（出発地点と近すぎて省略された場合）
    // 出発マーカーの位置にパンし、帰宅用のInfoWindowを表示
    if (!marker && type === "goal" && startMarker) {
      const map = getMapInstance()
      if (map) {
        map.panTo(startMarker.getPosition())
        const address = this.#getGoalAddressFromDom()
        showInfoWindowForPin({
          marker: startMarker,
          name: "帰宅",
          address,
        })
      }
      return
    }

    if (marker) this.#panAndTriggerClick(marker)
  }

  // 地図をパンしてInfoWindowを表示
  #panAndTriggerClick(marker) {
    getMapInstance()?.panTo(marker.getPosition())
    google.maps.event.trigger(marker, "click")
  }

  // 座標でマーカーを検索（誤差許容）
  #findMarkerByPosition(markers, lat, lng) {
    const threshold = 0.00001 // 約1m以内の誤差を許容
    return markers.find((m) => {
      const pos = m.getPosition()
      return (
        Math.abs(pos.lat() - lat) < threshold &&
        Math.abs(pos.lng() - lng) < threshold
      )
    })
  }

  // DOMから帰宅地点の住所を取得
  #getGoalAddressFromDom() {
    const el = document.querySelector(".goal-point-block .address")
    return el?.textContent?.trim() || null
  }
}
