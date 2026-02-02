import { Controller } from "@hotwired/stimulus"

/**
 * モバイル用InfoWindowコントローラー
 * マーカークリック時に下からスライドアップするシート
 *
 * - モバイル専用パーシャル（3カラムヘッダー構造）を使用
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

    // 共通高さ保存用（%）- ナビバーとInfoWindowで共有
    this.savedHeightPercent = null

    // ドラッグイベント（document で捕捉し、シート内かをチェック）
    this.boundTouchStart = this.handleTouchStart.bind(this)
    this.boundTouchMove = this.handleTouchMove.bind(this)
    this.boundTouchEnd = this.handleTouchEnd.bind(this)

    document.addEventListener("touchstart", this.boundTouchStart, { passive: false })
    document.addEventListener("touchmove", this.boundTouchMove, { passive: false })
    document.addEventListener("touchend", this.boundTouchEnd)
  }

  disconnect() {
    document.removeEventListener("mobileInfowindow:show", this.boundShow)
    document.removeEventListener("mobileInfowindow:close", this.boundClose)

    document.removeEventListener("touchstart", this.boundTouchStart)
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

    // ナビバーの状態を保存して最小化（先に実行して高さを取得）
    this.saveAndCollapseNavibar()

    // 初期高さを設定
    const sheet = this.sheetTarget
    const isPoint = contentEl?.querySelector(".dp-infowindow--point")

    sheet.style.transition = "none"

    if (isPoint) {
      // 出発/帰宅地点: コンテンツの高さに合わせる
      sheet.style.height = "auto"
      const contentHeight = sheet.scrollHeight
      sheet.style.height = `${contentHeight}px`
      this.currentHeight = contentHeight
    } else {
      // スポット: 共通高さまたはデフォルト50%
      const heightPercent = this.savedHeightPercent ?? 50
      const initialHeight = window.innerHeight * (heightPercent / 100)
      sheet.style.height = `${initialHeight}px`
      this.currentHeight = initialHeight
    }


    // 写真ギャラリー連携（infowindow-ui → photo-gallery）
    const infoWindowEl = contentEl?.querySelector(".dp-infowindow")
    if (infoWindowEl) {
      infoWindowEl.addEventListener("infowindow--ui:openGallery", (e) => {
        document.dispatchEvent(new CustomEvent("photo-gallery:open", {
          detail: {
            photoUrls: e.detail?.photoUrls || [],
            name: infoWindowEl.querySelector(".dp-infowindow__name")?.textContent?.trim() || "名称不明"
          }
        }))
      })
    }
  }

  /**
   * InfoWindowを閉じる（アニメーションなし）
   */
  close() {
    const sheet = this.sheetTarget

    // 即座に非表示
    this.element.classList.remove("mobile-infowindow--visible")
    this.element.hidden = true
    sheet.style.transition = "none"
    sheet.style.height = ""

    // コンテンツクリア
    const contentEl = document.getElementById("mobile-infowindow-content")
    if (contentEl) {
      contentEl.innerHTML = ""
    }

    // ナビバーを共通高さで復元
    this.restoreNavibar()
  }

  /**
   * ナビバーの高さを保存して最小化（アニメーションなし）
   * 既に保存済みの場合は上書きしない（InfoWindow間遷移対応）
   */
  saveAndCollapseNavibar() {
    const navibar = document.querySelector("[data-controller~='ui--bottom-sheet']")
    if (!navibar) return

    const controller = this.application.getControllerForElementAndIdentifier(navibar, "ui--bottom-sheet")
    if (controller) {
      // 未保存の場合のみ保存（連続表示時に元の状態を維持）
      if (this.savedHeightPercent === null) {
        const percent = (controller.currentHeight / window.innerHeight) * 100
        this.savedHeightPercent = percent
      }
      // アニメーションなしで即座に最小化
      navibar.style.transition = "none"
      controller.setHeight(controller.minValue)
    }
  }

  /**
   * ナビバーを共通高さで復元（アニメーションなし）
   * 高さはリセットせず維持（次回InfoWindowで再利用）
   */
  restoreNavibar() {
    if (this.savedHeightPercent === null) return

    const navibar = document.querySelector("[data-controller~='ui--bottom-sheet']")
    if (!navibar) return

    const controller = this.application.getControllerForElementAndIdentifier(navibar, "ui--bottom-sheet")
    if (controller) {
      navibar.style.transition = "none"
      controller.setHeight(this.savedHeightPercent)
    }
    // savedHeightPercentはリセットしない（次回InfoWindowで再利用）
  }

  // --- ドラッグ操作 ---

  handleTouchStart(e) {
    const target = e.target

    // シート外のタッチは無視
    const sheet = target.closest(".mobile-infowindow__sheet")
    if (!sheet) return

    // スクロール可能なコンテンツ内からのタッチは無視
    const scrollable = target.closest(".dp-infowindow__comments, .dp-infowindow__panel--comment")
    if (scrollable) return

    // ボタンやリンクからのタッチは無視
    // ただし、ヘッダー行の要素（×ボタン、お気に入り、コメント）はドラッグ許可
    const headerDraggable = target.closest(".dp-infowindow__close-btn, .dp-infowindow__stat, .dp-infowindow__stats")
    if (!headerDraggable) {
      const interactive = target.closest("button, a, input, textarea, select, .dp-infowindow__btn")
      if (interactive) return
    }

    const touch = e.touches[0]
    this.potentialDrag = true
    this.isDragging = false
    this.startY = touch.clientY
    this.startHeight = this.currentHeight
    this.dragThreshold = 10

    this.sheetTarget.style.transition = "none"
    // タップを許可するためここではpreventDefaultを呼ばない
  }

  handleTouchMove(e) {
    if (!this.potentialDrag) return

    const touch = e.touches[0]
    const deltaY = this.startY - touch.clientY

    // 閾値を超えたらドラッグ開始
    if (!this.isDragging && Math.abs(deltaY) > this.dragThreshold) {
      this.isDragging = true
    }

    if (!this.isDragging) return

    // ドラッグ中の処理
    const newHeight = this.startHeight + deltaY
    const windowHeight = window.innerHeight
    const minH = 100
    const maxH = windowHeight * 0.85
    const clamped = Math.max(minH, Math.min(maxH, newHeight))

    this.sheetTarget.style.height = `${clamped}px`
    this.currentHeight = clamped

    if (e.cancelable) e.preventDefault()
  }

  handleTouchEnd() {
    // ドラッグ後の高さを共通変数に保存（ナビバー・次のInfoWindowで再利用）
    if (this.isDragging) {
      this.savedHeightPercent = (this.currentHeight / window.innerHeight) * 100
    }
    this.potentialDrag = false
    this.isDragging = false
  }
}
