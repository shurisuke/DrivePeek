import { Controller } from "@hotwired/stimulus"

/**
 * モバイル用InfoWindowコントローラー
 * マーカークリック時に下からスライドアップするシート
 * ナビバーと同様の自由ドラッグ対応
 *
 * - コメントフッターをシート直下に移動（ナビバーフッターと同じ構造）
 * - タブ切替でフッター表示/非表示
 * - 出発/帰宅地点はコンパクト表示（25vh）
 */
export default class extends Controller {
  static targets = ["content", "handle", "sheet"]

  connect() {
    // グローバルイベントリスナー（モバイルInfoWindow表示用）
    this.boundShow = this.show.bind(this)
    this.boundClose = this.close.bind(this)

    document.addEventListener("mobileInfowindow:show", this.boundShow)
    document.addEventListener("mobileInfowindow:close", this.boundClose)

    // ドラッグ関連
    this.isDragging = false
    this.startY = 0
    this.startHeight = 0
    this.currentHeight = 0

    // ドラッグイベント
    this.boundTouchStart = this.handleTouchStart.bind(this)
    this.boundTouchMove = this.handleTouchMove.bind(this)
    this.boundTouchEnd = this.handleTouchEnd.bind(this)

    if (this.hasHandleTarget) {
      this.handleTarget.addEventListener("touchstart", this.boundTouchStart, { passive: false })
    }
    document.addEventListener("touchmove", this.boundTouchMove, { passive: false })
    document.addEventListener("touchend", this.boundTouchEnd)
  }

  disconnect() {
    document.removeEventListener("mobileInfowindow:show", this.boundShow)
    document.removeEventListener("mobileInfowindow:close", this.boundClose)

    if (this.hasHandleTarget) {
      this.handleTarget.removeEventListener("touchstart", this.boundTouchStart)
    }
    document.removeEventListener("touchmove", this.boundTouchMove)
    document.removeEventListener("touchend", this.boundTouchEnd)
  }

  /**
   * InfoWindowを表示
   */
  show(event) {
    const { html } = event.detail || {}
    if (!html) return

    // コンテンツを挿入
    const contentEl = document.getElementById("mobile-infowindow-content")
    if (contentEl) {
      contentEl.innerHTML = html
    }

    // 表示
    this.element.hidden = false
    this.element.classList.add("mobile-infowindow--visible")

    // 初期高さを設定（出発/帰宅地点はコンパクトに）
    const sheet = this.sheetTarget
    const isPoint = contentEl?.querySelector(".dp-infowindow--point")
    const initialHeight = isPoint
      ? window.innerHeight * 0.25
      : window.innerHeight * 0.5
    sheet.style.transition = "height 0.3s cubic-bezier(0.4, 0, 0.2, 1)"
    sheet.style.height = `${initialHeight}px`
    this.currentHeight = initialHeight


    // コメントフッターをシート直下に移動（ナビバーフッターと同じ構造）
    this.#setupCommentFooter(contentEl)

    // タブ切替でフッター表示/非表示
    this.#setupTabListeners(contentEl)

    // 写真ギャラリー連携（infowindow-ui → photo-gallery）
    const infoWindowEl = contentEl?.querySelector(".dp-infowindow")
    if (infoWindowEl) {
      infoWindowEl.addEventListener("infowindow-ui:openGallery", (e) => {
        document.dispatchEvent(new CustomEvent("photo-gallery:open", {
          detail: {
            photoUrls: e.detail?.photoUrls || [],
            name: infoWindowEl.querySelector(".dp-infowindow__name")?.textContent?.trim() || "名称不明"
          }
        }))
      })
    }

    // ナビバーを最小化
    this.collapseNavibar()
  }

  /**
   * InfoWindowを閉じる
   */
  close() {
    const sheet = this.sheetTarget
    sheet.style.transition = "height 0.3s cubic-bezier(0.4, 0, 0.2, 1)"
    sheet.style.height = "0px"

    this.element.classList.remove("mobile-infowindow--visible")

    // アニメーション後に非表示
    setTimeout(() => {
      this.element.hidden = true
      sheet.style.height = ""
      sheet.style.transition = ""
      const contentEl = document.getElementById("mobile-infowindow-content")
      if (contentEl) {
        contentEl.innerHTML = ""
      }
      // フッターを非表示・クリア
      const footerEl = document.getElementById("mobile-infowindow-footer")
      if (footerEl) {
        footerEl.innerHTML = ""
        footerEl.hidden = true
      }
    }, 300)

  }

  /**
   * ナビバーを最小化
   */
  collapseNavibar() {
    const navibar = document.querySelector("[data-controller~='bottom-sheet']")
    if (!navibar) return

    const controller = this.application.getControllerForElementAndIdentifier(navibar, "bottom-sheet")
    if (controller) {
      controller.collapse()
    }
  }

  // --- コメントフッター管理（ナビバーフッターと同じ構造） ---

  /**
   * コメントフッターをシート直下に移動
   * dp-infowindow内からsheet直下に引き上げることで、flexチェーン問題を解消
   */
  #setupCommentFooter(contentEl) {
    const commentFooter = contentEl?.querySelector(".dp-infowindow__comment-footer")
    const footerSlot = document.getElementById("mobile-infowindow-footer")
    if (!commentFooter || !footerSlot) return

    // フッターをシート直下に移動
    footerSlot.appendChild(commentFooter)
    // 初期状態ではスポットタブなのでフッター非表示
    footerSlot.hidden = true
  }

  /**
   * タブ切替でフッター表示/非表示を切り替え
   */
  #setupTabListeners(contentEl) {
    const footerSlot = document.getElementById("mobile-infowindow-footer")
    if (!footerSlot) return

    const radios = contentEl?.querySelectorAll('input[name="iw-tab"]')
    if (!radios) return

    radios.forEach((radio) => {
      radio.addEventListener("change", () => {
        footerSlot.hidden = radio.id !== "iw-tab-comment" || !radio.checked
      })
    })
  }

  // --- ドラッグ操作 ---

  handleTouchStart(e) {
    const touch = e.touches[0]
    this.isDragging = true
    this.startY = touch.clientY
    this.startHeight = this.currentHeight

    const sheet = this.sheetTarget
    sheet.style.transition = "none"

    e.preventDefault()
  }

  handleTouchMove(e) {
    if (!this.isDragging) return

    const touch = e.touches[0]
    const deltaY = this.startY - touch.clientY // 上方向で正
    const newHeight = this.startHeight + deltaY
    const windowHeight = window.innerHeight

    // 範囲制限（最小100px、最大85vh）
    const minH = 100
    const maxH = windowHeight * 0.85
    const clamped = Math.max(minH, Math.min(maxH, newHeight))

    this.sheetTarget.style.height = `${clamped}px`
    this.currentHeight = clamped

    e.preventDefault()
  }

  handleTouchEnd() {
    if (!this.isDragging) return
    this.isDragging = false
  }
}
