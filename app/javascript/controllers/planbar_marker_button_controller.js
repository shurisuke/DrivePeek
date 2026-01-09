// app/javascript/controllers/planbar_marker_button_controller.js
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
    const marker = type === "start"
      ? getStartPointMarker()
      : getEndPointMarker()
    if (marker) this.#panAndTriggerClick(marker)
  }

  // 地図をパンしてInfoWindowを表示
  #panAndTriggerClick(marker) {
    getMapInstance()?.panTo(marker.getPosition())
    google.maps.event.trigger(marker, "click")
  }
}
