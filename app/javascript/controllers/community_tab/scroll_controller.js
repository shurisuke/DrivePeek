// ================================================================
// CommunityScrollController
// みんなの旅タブ: Turbo Frame更新時のスクロール制御
// - ページネーション・検索時に結果バー位置までスクロール
// - ナビバー内でのみ動作（スタンドアロンページでは何もしない）
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.handleFrameLoad = this.scrollToResults.bind(this)
    this.element.addEventListener("turbo:frame-load", this.handleFrameLoad)
  }

  disconnect() {
    this.element.removeEventListener("turbo:frame-load", this.handleFrameLoad)
  }

  scrollToResults() {
    const scrollContainer = this.element.closest(".navibar__content-scroll")
    if (!scrollContainer) return

    const resultsBar = this.element.querySelector(".results-bar")
    if (resultsBar) {
      const offsetTop = resultsBar.offsetTop - 8
      scrollContainer.scrollTo({ top: offsetTop, behavior: "smooth" })
    } else {
      scrollContainer.scrollTo({ top: 0, behavior: "smooth" })
    }
  }
}
