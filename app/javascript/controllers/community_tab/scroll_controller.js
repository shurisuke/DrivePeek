// ================================================================
// CommunityScrollController
// みんなの旅: Turbo Frame更新時のスクロール制御
// - ナビバー内: 結果バー位置までスクロール
// - スタンドアロン: ページトップへスクロール
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    // ナビバー内: 初回リモート読み込みをスキップ
    // スタンドアロン: 初回からスクロール（インラインコンテンツなので）
    const isInNavibar = !!this.element.closest(".navibar__content-scroll")
    this.isInitialLoad = isInNavibar
    this.handleFrameLoad = this.scrollToResults.bind(this)
    this.element.addEventListener("turbo:frame-load", this.handleFrameLoad)
  }

  disconnect() {
    this.element.removeEventListener("turbo:frame-load", this.handleFrameLoad)
  }

  scrollToResults() {
    // 初回読み込みはスキップ（タブ切り替え時）
    if (this.isInitialLoad) {
      this.isInitialLoad = false
      return
    }

    const scrollContainer = this.element.closest(".navibar__content-scroll")
    if (scrollContainer) {
      // ナビバー内: results-barまでスクロール
      const resultsBar = this.element.querySelector(".results-bar")
      if (resultsBar) {
        const offsetTop = resultsBar.offsetTop - 8
        scrollContainer.scrollTo({ top: offsetTop, behavior: "smooth" })
      } else {
        scrollContainer.scrollTo({ top: 0, behavior: "smooth" })
      }
    } else {
      // スタンドアロン: ページトップへ
      window.scrollTo({ top: 0, behavior: "smooth" })
    }
  }
}
