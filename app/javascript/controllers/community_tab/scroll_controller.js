// ================================================================
// CommunityScrollController
// みんなの旅: Turbo Frame更新時のスクロール制御
// - ページネーションクリック時のみスクロール
// - 検索フォーム操作時はスクロールしない
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.shouldScroll = false

    // ページネーションクリックを検知
    this.handlePaginationClick = this.markPaginationClick.bind(this)
    this.element.addEventListener("click", this.handlePaginationClick)

    // フレーム読み込み完了時にスクロール判定
    this.handleFrameLoad = this.scrollToResults.bind(this)
    this.element.addEventListener("turbo:frame-load", this.handleFrameLoad)
  }

  disconnect() {
    this.element.removeEventListener("click", this.handlePaginationClick)
    this.element.removeEventListener("turbo:frame-load", this.handleFrameLoad)
  }

  // ページネーションリンクがクリックされたらフラグを立てる
  markPaginationClick(event) {
    const pagination = event.target.closest("[data-pagination]")
    if (pagination) {
      this.shouldScroll = true
    }
  }

  scrollToResults() {
    // ページネーション以外の操作ではスクロールしない
    if (!this.shouldScroll) {
      return
    }
    this.shouldScroll = false

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
