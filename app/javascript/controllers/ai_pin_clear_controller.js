// ================================================================
// AiPinClearController
// 用途: AI提案ピンをクリアするボタン
// ================================================================

import { Controller } from "@hotwired/stimulus"
import { clearAiSuggestionMarkers } from "map/state"
import { closeInfoWindow } from "map/infowindow"

export default class extends Controller {
  clear() {
    clearAiSuggestionMarkers()
    closeInfoWindow()
    this.element.hidden = true
  }
}
