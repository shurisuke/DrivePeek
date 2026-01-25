// ================================================================
// AiSuggestionClearController
// 用途: AI提案マーカーをクリアするボタン
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

  // 外部から表示を切り替えるためのメソッド
  show() {
    this.element.hidden = false
  }
}
