// ================================================================
// PopularSpotsClearController
// 用途: 盛り上がりピンをクリアするボタン
// ================================================================

import { Controller } from "@hotwired/stimulus"
import { clearPopularSpotMarkers } from "map/state"
import { closeInfoWindow } from "map/infowindow"

export default class extends Controller {
  clear() {
    clearPopularSpotMarkers()
    closeInfoWindow()
    this.element.hidden = true
  }
}
