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
 *   <div data-ui--bottom-sheet-target="handle">ドラッグハンドル</div>
 *   <div data-ui--bottom-sheet-target="content">コンテンツ</div>
 * </div>
 */
export default class extends Controller {
  static targets = ["handle", "content"]

  static values = {
    // スナップ位置（%）
    min: { type: Number, default: 10 },   // 最小（タブバーのみ）
    mid: { type: Number, default: 50 },   // 中間
    max: { type: Number, default: 90 },   // 最大
    // 現在の状態
    state: { type: String, default: "min" }, // "min" | "mid" | "max"
    // アニメーション時間（ms）
    duration: { type: Number, default: 300 },
    // スワイプ速度閾値（px/ms）
    velocityThreshold: { type: Number, default: 0.5 }
  }

  connect() {
    this.isDragging = false
    this.startY = 0
    this.startHeight = 0
    this.currentHeight = 0
    this.lastY = 0
    this.lastTime = 0
    this.velocity = 0
    this.isMobile = false

    // モバイル判定
    this.checkMobile()

    // イベントリスナー設定
    this.boundTouchStart = this.handleTouchStart.bind(this)
    this.boundTouchMove = this.handleTouchMove.bind(this)
    this.boundTouchEnd = this.handleTouchEnd.bind(this)
    this.boundMouseDown = this.handleMouseDown.bind(this)
    this.boundMouseMove = this.handleMouseMove.bind(this)
    this.boundMouseUp = this.handleMouseUp.bind(this)

    // ハンドル部分にイベント設定
    if (this.hasHandleTarget) {
      this.handleTarget.addEventListener("touchstart", this.boundTouchStart, { passive: false })
      this.handleTarget.addEventListener("mousedown", this.boundMouseDown)
    }

    // グローバルイベント（ドラッグ中のみ有効化）
    document.addEventListener("touchmove", this.boundTouchMove, { passive: false })
    document.addEventListener("touchend", this.boundTouchEnd)
    document.addEventListener("mousemove", this.boundMouseMove)
    document.addEventListener("mouseup", this.boundMouseUp)

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
    if (this.hasHandleTarget) {
      this.handleTarget.removeEventListener("touchstart", this.boundTouchStart)
      this.handleTarget.removeEventListener("mousedown", this.boundMouseDown)
    }
    document.removeEventListener("touchmove", this.boundTouchMove)
    document.removeEventListener("touchend", this.boundTouchEnd)
    document.removeEventListener("mousemove", this.boundMouseMove)
    document.removeEventListener("mouseup", this.boundMouseUp)
    window.removeEventListener("resize", this.boundResize)
    document.removeEventListener("suggestion:startAreaDraw", this.boundAreaDrawStart)
  }

  // タッチイベント
  handleTouchStart(e) {
    if (!this.isMobile) return
    const touch = e.touches[0]
    this.startDrag(touch.clientY)
    e.preventDefault()
  }

  handleTouchMove(e) {
    if (!this.isMobile || !this.isDragging) return
    const touch = e.touches[0]
    this.updateDrag(touch.clientY)
    e.preventDefault()
  }

  handleTouchEnd(e) {
    if (!this.isMobile || !this.isDragging) return
    this.endDrag()
  }

  // マウスイベント（デバッグ用）
  handleMouseDown(e) {
    if (!this.isMobile) return
    this.startDrag(e.clientY)
    e.preventDefault()
  }

  handleMouseMove(e) {
    if (!this.isMobile || !this.isDragging) return
    this.updateDrag(e.clientY)
  }

  handleMouseUp(e) {
    if (!this.isMobile || !this.isDragging) return
    this.endDrag()
  }

  // ドラッグ開始
  startDrag(y) {
    this.isDragging = true
    this.startY = y
    this.startHeight = this.currentHeight
    this.lastY = y
    this.lastTime = Date.now()
    this.velocity = 0

    // アニメーションを無効化
    this.element.style.transition = "none"
    this.element.classList.add("bottom-sheet--dragging")
  }

  // ドラッグ中
  updateDrag(y) {
    const windowHeight = window.innerHeight
    const deltaY = this.startY - y // 上にドラッグで正
    const newHeightPx = this.startHeight + deltaY
    const newHeightPercent = (newHeightPx / windowHeight) * 100

    // 範囲制限
    const clampedPercent = Math.max(this.minValue, Math.min(this.maxValue, newHeightPercent))

    // 速度計算
    const now = Date.now()
    const dt = now - this.lastTime
    if (dt > 0) {
      this.velocity = (this.lastY - y) / dt // 上向きで正
    }
    this.lastY = y
    this.lastTime = now

    // 高さを更新
    this.setHeight(clampedPercent)
  }

  // ドラッグ終了
  endDrag() {
    this.isDragging = false
    this.element.classList.remove("bottom-sheet--dragging")

    // 自由調整モード: 現在の位置をそのまま維持（スナップしない）
    const windowHeight = window.innerHeight
    const currentPercent = (this.currentHeight / windowHeight) * 100

    // 状態変更イベントを発火
    this.dispatch("stateChange", { detail: { heightPercent: currentPercent } })
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

    // 状態変更イベントを発火
    this.dispatch("stateChange", { detail: { state, heightPercent: targetPercent } })

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
