// app/javascript/controllers/planbar_resize_controller.js
// ================================================================
// プランバーのリサイズ機能
// - ドラッグでプランバー幅を 300px〜700px に調整
// - 300px 未満にドラッグすると収納（非表示）
// - 収納時もハンドルは表示され、クリック/ドラッグで復元
// - 状態は localStorage に保存
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    min: { type: Number, default: 300 },
    maxPercent: { type: Number, default: 70 }, // 画面幅の何%まで
    default: { type: Number, default: 350 },
    storageKey: { type: String, default: "drive_peek:planbar_width" },
    collapsedKey: { type: String, default: "drive_peek:planbar_collapsed" },
  }

  static targets = ["handle", "map"]

  // 画面幅の指定%を最大値として計算
  get maxWidth() {
    return Math.floor(window.innerWidth * this.maxPercentValue / 100)
  }

  connect() {
    this.isDragging = false
    this.startX = 0
    this.startWidth = 0

    this.boundOnMouseMove = this.onMouseMove.bind(this)
    this.boundOnMouseUp = this.onMouseUp.bind(this)
    this.boundOnTouchMove = this.onTouchMove.bind(this)
    this.boundOnTouchEnd = this.onTouchEnd.bind(this)

    // 保存されている状態を復元
    this.restoreState()

    // Google Maps のリサイズイベントを遅延で発火
    this.triggerMapResize()
  }

  disconnect() {
    document.removeEventListener("mousemove", this.boundOnMouseMove)
    document.removeEventListener("mouseup", this.boundOnMouseUp)
    document.removeEventListener("touchmove", this.boundOnTouchMove)
    document.removeEventListener("touchend", this.boundOnTouchEnd)
  }

  // ================================================================
  // ドラッグ開始（マウス）
  // ================================================================
  startResize(event) {
    // 収納状態でのクリックは展開のみ
    if (this.isCollapsed() && event.type === "click") {
      this.expand()
      return
    }

    event.preventDefault()

    this.isDragging = true
    this.startX = event.type.includes("touch") ? event.touches[0].clientX : event.clientX
    this.startWidth = this.getCurrentWidth()

    document.body.classList.add("planbar-resizing")

    if (event.type.includes("touch")) {
      document.addEventListener("touchmove", this.boundOnTouchMove, { passive: false })
      document.addEventListener("touchend", this.boundOnTouchEnd)
    } else {
      document.addEventListener("mousemove", this.boundOnMouseMove)
      document.addEventListener("mouseup", this.boundOnMouseUp)
    }
  }

  // ================================================================
  // ドラッグ中
  // ================================================================
  onMouseMove(event) {
    if (!this.isDragging) return
    this.handleDrag(event.clientX)
  }

  onTouchMove(event) {
    if (!this.isDragging) return
    event.preventDefault()
    this.handleDrag(event.touches[0].clientX)
  }

  handleDrag(clientX) {
    const delta = clientX - this.startX
    let newWidth = this.startWidth + delta

    // 収納判定（300px 未満で収納）
    if (newWidth < this.minValue) {
      this.collapse()
      return
    }

    // 最大値を超えないように
    newWidth = Math.min(newWidth, this.maxWidth)

    // 収納状態から復帰
    if (this.isCollapsed()) {
      this.element.classList.remove("planbar--collapsed")
    }

    this.setWidth(newWidth)
  }

  // ================================================================
  // ドラッグ終了
  // ================================================================
  onMouseUp() {
    this.endDrag()
    document.removeEventListener("mousemove", this.boundOnMouseMove)
    document.removeEventListener("mouseup", this.boundOnMouseUp)
  }

  onTouchEnd() {
    this.endDrag()
    document.removeEventListener("touchmove", this.boundOnTouchMove)
    document.removeEventListener("touchend", this.boundOnTouchEnd)
  }

  endDrag() {
    if (!this.isDragging) return

    this.isDragging = false
    document.body.classList.remove("planbar-resizing")

    // 状態を保存
    this.saveState()

    // 地図のリサイズを通知
    this.triggerMapResize()
  }

  // ================================================================
  // 収納・展開
  // ================================================================
  collapse() {
    this.element.classList.add("planbar--collapsed")
    // CSS側で地図の位置・幅を制御するため、--planbar-width は変更しない
    // プランバーは300px幅を保持しつつ translateX で画面外に移動
    this.saveState()
    this.triggerMapResize()
  }

  expand() {
    this.element.classList.remove("planbar--collapsed")
    const width = this.getSavedWidth() || this.defaultValue
    this.setWidth(width)
    this.saveState()
    this.triggerMapResize()
  }

  isCollapsed() {
    return this.element.classList.contains("planbar--collapsed")
  }

  // ================================================================
  // 幅の取得・設定
  // ================================================================
  getCurrentWidth() {
    const style = getComputedStyle(this.element)
    const width = style.getPropertyValue("--planbar-width")
    return parseInt(width, 10) || this.defaultValue
  }

  setWidth(width) {
    this.element.style.setProperty("--planbar-width", `${width}px`)
    this.updateSearchBarVisibility(width)
  }

  // 80%を超えたら検索バー・保存ボタンを非表示
  updateSearchBarVisibility(width) {
    const threshold = Math.floor(window.innerWidth * 0.8)
    if (width > threshold) {
      this.element.classList.add("planbar--wide")
    } else {
      this.element.classList.remove("planbar--wide")
    }
  }

  // ================================================================
  // ハンドルクリック（収納時の展開）
  // ================================================================
  handleClick(event) {
    if (this.isCollapsed()) {
      event.preventDefault()
      this.expand()
    }
  }

  // ================================================================
  // 状態の保存・復元
  // ================================================================
  saveState() {
    try {
      const collapsed = this.isCollapsed()
      localStorage.setItem(this.collapsedKeyValue, collapsed ? "1" : "0")

      if (!collapsed) {
        const width = this.getCurrentWidth()
        localStorage.setItem(this.storageKeyValue, String(width))
      }
    } catch (e) {
      console.warn("[planbar-resize] Failed to save state:", e)
    }
  }

  restoreState() {
    try {
      const collapsed = localStorage.getItem(this.collapsedKeyValue) === "1"

      if (collapsed) {
        this.collapse()
      } else {
        const savedWidth = this.getSavedWidth()
        if (savedWidth) {
          this.setWidth(savedWidth)
        } else {
          // デフォルト幅でも検索バーの表示状態を更新
          this.updateSearchBarVisibility(this.defaultValue)
        }
      }
    } catch (e) {
      console.warn("[planbar-resize] Failed to restore state:", e)
    }
  }

  getSavedWidth() {
    try {
      const saved = localStorage.getItem(this.storageKeyValue)
      if (saved) {
        const width = parseInt(saved, 10)
        if (width >= this.minValue && width <= this.maxWidth) {
          return width
        }
      }
    } catch (e) {
      // ignore
    }
    return null
  }

  // ================================================================
  // Google Maps リサイズ通知
  // ================================================================
  triggerMapResize() {
    // 少し遅延させて CSS 変更が反映されてからリサイズ
    requestAnimationFrame(() => {
      if (window.google && window.google.maps && window.mapInstance) {
        google.maps.event.trigger(window.mapInstance, "resize")
      }
    })
  }
}
