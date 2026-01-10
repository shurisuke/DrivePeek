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
    const index = parseInt(e.currentTarget.dataset.spotIndex, 10)
    const marker = getPlanSpotMarkers()[index]
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

  // DOMから帰宅地点の住所を取得
  #getGoalAddressFromDom() {
    const el = document.querySelector(".goal-point-block .address")
    return el?.textContent?.trim() || null
  }
}
