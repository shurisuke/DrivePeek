// ================================================================
// SuggestionPinClearController
// 用途: 提案ピンをクリアするボタン
// ================================================================

import { Controller } from "@hotwired/stimulus"
import { clearSuggestionMarkers } from "map/state"
import { closeInfoWindow } from "map/infowindow"

export default class extends Controller {
  clear() {
    clearSuggestionMarkers()
    closeInfoWindow()
    this.element.hidden = true
  }
}
