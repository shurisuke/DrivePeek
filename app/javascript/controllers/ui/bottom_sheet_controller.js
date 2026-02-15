import { Controller } from "@hotwired/stimulus"

/**
 * ボトムシートコントローラー
 * Google Maps風のスワイプ可能なボトムシートUI
 *
 * 使用例:
 * <div data-controller="ui--bottom-sheet"
 *      data-ui--bottom-sheet-min-value="80"
 *      data-ui--bottom-sheet-mid-value="50"
 *      data-ui--bottom-sheet-max-value="90">
 * </div>
 */
export default class extends Controller {
  static values = {
    // スナップ位置（%）
    min: { type: Number, default: 10 },   // 最小（タブバーのみ）
    mid: { type: Number, default: 50 },   // 中間
    max: { type: Number, default: 90 },   // 最大
    // 現在の状態
    state: { type: String, default: "min" }, // "min" | "mid" | "max"
    // アニメーション時間（ms）
    duration: { type: Number, default: 300 }
  }

  connect() {
    this.isDragging = false
    this.potentialDrag = false
    this.startY = 0
    this.startHeight = 0
    this.currentHeight = 0
    this.isMobile = false
    this.dragThreshold = 10

    // モバイル判定
    this.checkMobile()

    // イベントリスナー設定（ドキュメントレベルで捕捉）
    this.boundTouchStart = this.handleTouchStart.bind(this)
    this.boundTouchMove = this.handleTouchMove.bind(this)
    this.boundTouchEnd = this.handleTouchEnd.bind(this)

    document.addEventListener("touchstart", this.boundTouchStart, { passive: false })
    document.addEventListener("touchmove", this.boundTouchMove, { passive: false })
    document.addEventListener("touchend", this.boundTouchEnd)

    // 画面リサイズ時に再計算
    this.boundResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.boundResize)

    // エリア描画開始時に最小化
    this.boundAreaDrawStart = () => this.collapse()
    document.addEventListener("suggestion:startAreaDraw", this.boundAreaDrawStart)
  }

  // モバイル判定（768px未満）
  checkMobile() {
    const wasMobile = this.isMobile
    this.isMobile = window.innerWidth < 768

    if (this.isMobile && !wasMobile) {
      // モバイルになった場合、初期状態を設定
      this.setSnapPosition(this.stateValue, false)
    } else if (!this.isMobile && wasMobile) {
      // デスクトップになった場合、スタイルをリセット
      this.resetStyles()
    }
  }

  // スタイルをリセット（デスクトップ用）
  resetStyles() {
    this.element.style.height = ""
    this.element.style.transition = ""
    this.element.classList.remove("bottom-sheet--min", "bottom-sheet--mid", "bottom-sheet--max", "bottom-sheet--dragging")
  }

  disconnect() {
    document.removeEventListener("touchstart", this.boundTouchStart)
    document.removeEventListener("touchmove", this.boundTouchMove)
    document.removeEventListener("touchend", this.boundTouchEnd)
    window.removeEventListener("resize", this.boundResize)
    document.removeEventListener("suggestion:startAreaDraw", this.boundAreaDrawStart)
  }

  // タッチイベント
  handleTouchStart(e) {
    if (!this.isMobile) return

    const target = e.target

    // ナビバー外のタッチは無視
    if (!target.closest(".navibar")) return

    // スクロール可能なコンテンツ内からのタッチは無視
    const scrollable = target.closest(".navibar__content-scroll")
    if (scrollable) return

    // タブボタンはドラッグ対象として許可
    const isTabButton = target.closest(".tab-btn, .plan-tab-nav")
    if (!isTabButton) {
      // その他のボタンやリンクからのタッチは無視
      const interactive = target.closest("button, a, input, textarea, select")
      if (interactive) return
    }

    const touch = e.touches[0]
    this.potentialDrag = true
    this.isDragging = false
    this.startY = touch.clientY
    this.startHeight = this.currentHeight

    this.element.style.transition = "none"
  }

  handleTouchMove(e) {
    if (!this.isMobile || !this.potentialDrag) return

    const touch = e.touches[0]
    const deltaY = this.startY - touch.clientY

    // 閾値を超えたらドラッグ開始
    if (!this.isDragging && Math.abs(deltaY) > this.dragThreshold) {
      this.isDragging = true
      this.element.classList.add("bottom-sheet--dragging")
    }

    if (!this.isDragging) return

    this.updateDrag(touch.clientY)
    if (e.cancelable) e.preventDefault()
  }

  handleTouchEnd() {
    if (!this.isMobile) return

    if (this.isDragging) {
      this.endDrag()
    }

    this.potentialDrag = false
    this.isDragging = false
  }

  // ドラッグ中
  updateDrag(y) {
    const windowHeight = window.innerHeight
    const deltaY = this.startY - y // 上にドラッグで正
    const newHeightPx = this.startHeight + deltaY
    const newHeightPercent = (newHeightPx / windowHeight) * 100

    // 範囲制限
    const clampedPercent = Math.max(this.minValue, Math.min(this.maxValue, newHeightPercent))

    // 高さを更新
    this.setHeight(clampedPercent)
  }

  // ドラッグ終了
  endDrag() {
    this.isDragging = false
    this.element.classList.remove("bottom-sheet--dragging")

  }

  // スナップ位置に移動
  setSnapPosition(state, animate = true) {
    // デスクトップでは何もしない
    if (!this.isMobile) return

    let targetPercent
    switch (state) {
      case "min":
        targetPercent = this.minValue
        break
      case "mid":
        targetPercent = this.midValue
        break
      case "max":
        targetPercent = this.maxValue
        break
      default:
        targetPercent = this.minValue
        state = "min"
    }

    // アニメーション設定
    if (animate) {
      this.element.style.transition = `height ${this.durationValue}ms cubic-bezier(0.4, 0, 0.2, 1)`
    } else {
      this.element.style.transition = "none"
    }

    this.setHeight(targetPercent)
    this.stateValue = state

    // クラス更新
    this.element.classList.remove("bottom-sheet--min", "bottom-sheet--mid", "bottom-sheet--max")
    this.element.classList.add(`bottom-sheet--${state}`)
  }

  // 高さを設定（%）
  setHeight(percent) {
    const windowHeight = window.innerHeight
    this.currentHeight = (percent / 100) * windowHeight
    this.element.style.height = `${percent}vh`
  }

  // 画面リサイズ時
  handleResize() {
    // モバイル判定を再実行
    this.checkMobile()

    // モバイルの場合のみ、現在の状態を維持して再計算
    if (this.isMobile) {
      this.setSnapPosition(this.stateValue, false)
    }
  }

  // 外部から状態を変更するアクション
  expand() {
    this.setSnapPosition("max", true)
  }

  collapse() {
    this.setSnapPosition("min", true)
  }

  toggle() {
    if (this.stateValue === "min") {
      this.setSnapPosition("mid", true)
    } else {
      this.setSnapPosition("min", true)
    }
  }

  // 状態を指定して変更
  setState({ params }) {
    const state = params.state || "min"
    this.setSnapPosition(state, true)
  }
}
