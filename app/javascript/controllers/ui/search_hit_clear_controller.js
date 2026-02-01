// ================================================================
// SearchHitClearController
// 用途: 検索結果のマーカーをクリアするボタン
// ================================================================

import { Controller } from "@hotwired/stimulus"
import { clearSearchHitMarkers } from "map/state"
import { closeInfoWindow } from "map/infowindow"

export default class extends Controller {
  clear() {
    clearSearchHitMarkers()
    closeInfoWindow()
    this.element.hidden = true
  }
}
