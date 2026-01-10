// app/javascript/controllers/navibar_resize_controller.js
// ================================================================
// プランバーのリサイズ機能
// - ドラッグでプランバー幅を 300px〜画面幅の指定% に調整
// - 300px 未満にドラッグすると左にスライド収納
// - 状態は localStorage に保存
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    min: { type: Number, default: 300 },
    maxPercent: { type: Number, default: 70 },
    default: { type: Number, default: 350 },
    railWidth: { type: Number, default: 70 },
    storageKey: { type: String, default: "drive_peek:navibar_width" },
    collapsedKey: { type: String, default: "drive_peek:navibar_collapsed" },
  }

  get maxWidth() {
    return Math.floor(window.innerWidth * this.maxPercentValue / 100)
  }

  get maxSlide() {
    const railOpen = this.element.classList.contains("plan-form--time-rail-on")
    return this.minValue + (railOpen ? this.railWidthValue : 0)
  }

  connect() {
    this.isDragging = false
    this.justDragged = false
    this.startX = 0
    this.startWidth = 0
    this.startSlide = 0

    this.boundOnMouseMove = this.onMouseMove.bind(this)
    this.boundOnMouseUp = this.endDrag.bind(this)
    this.boundOnTouchMove = this.onTouchMove.bind(this)
    this.boundOnTouchEnd = this.endDrag.bind(this)

    this.restoreState()
    this.triggerMapResize()
  }

  disconnect() {
    document.removeEventListener("mousemove", this.boundOnMouseMove)
    document.removeEventListener("mouseup", this.boundOnMouseUp)
    document.removeEventListener("touchmove", this.boundOnTouchMove)
    document.removeEventListener("touchend", this.boundOnTouchEnd)
  }

  // ================================================================
  // ドラッグ操作
  // ================================================================
  startResize(event) {
    event.preventDefault()

    this.isDragging = true
    this.startX = event.type.includes("touch") ? event.touches[0].clientX : event.clientX
    this.startWidth = this.getCurrentWidth()
    this.startSlide = this.getCurrentSlide()

    document.body.classList.add("navibar-resizing")

    if (event.type.includes("touch")) {
      document.addEventListener("touchmove", this.boundOnTouchMove, { passive: false })
      document.addEventListener("touchend", this.boundOnTouchEnd)
    } else {
      document.addEventListener("mousemove", this.boundOnMouseMove)
      document.addEventListener("mouseup", this.boundOnMouseUp)
    }
  }

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

    // スライド中（収納状態から復帰中）
    if (this.startSlide > 0) {
      const newSlide = Math.max(0, Math.min(this.startSlide - delta, this.maxSlide))
      this.setWidthAndSlide(this.minValue, newSlide)
      this.updateCollapsedState(newSlide >= this.maxSlide)

      if (newSlide > 0) return

      // スライド解消後は通常リサイズへ
      const remainingDelta = delta - this.startSlide
      const newWidth = Math.max(this.minValue, Math.min(this.minValue + remainingDelta, this.maxWidth))
      this.setWidthAndSlide(newWidth, 0)
      return
    }

    const newWidth = this.startWidth + delta

    // 収納方向（幅が最小値未満）
    if (newWidth < this.minValue) {
      const slideAmount = Math.min(this.minValue - newWidth, this.maxSlide)
      this.setWidthAndSlide(this.minValue, slideAmount)
      this.updateCollapsedState(slideAmount >= this.maxSlide)
      return
    }

    // 通常リサイズ
    this.setWidthAndSlide(Math.min(newWidth, this.maxWidth), 0)
    this.updateCollapsedState(false)
  }

  endDrag() {
    if (!this.isDragging) return
    this.isDragging = false

    document.removeEventListener("mousemove", this.boundOnMouseMove)
    document.removeEventListener("mouseup", this.boundOnMouseUp)
    document.removeEventListener("touchmove", this.boundOnTouchMove)
    document.removeEventListener("touchend", this.boundOnTouchEnd)

    this.saveState()
    document.body.classList.remove("navibar-resizing")

    this.justDragged = true
    setTimeout(() => { this.justDragged = false }, 100)

    this.triggerMapResize()
  }

  // ================================================================
  // 収納・展開
  // ================================================================
  updateCollapsedState(collapsed) {
    this.element.classList.toggle("navibar--collapsed", collapsed)
  }

  isCollapsed() {
    return this.element.classList.contains("navibar--collapsed")
  }

  handleClick(event) {
    if (this.justDragged) return
    if (this.isCollapsed()) {
      event.preventDefault()
      const width = this.getSavedWidth() || this.defaultValue
      this.setWidthAndSlide(width, 0)
      this.element.classList.remove("navibar--collapsed")
      this.saveState()
      this.triggerMapResize()
    }
  }

  // ================================================================
  // CSS変数の操作
  // ================================================================
  getCurrentWidth() {
    return parseInt(getComputedStyle(this.element).getPropertyValue("--navibar-width"), 10) || this.defaultValue
  }

  getCurrentSlide() {
    return parseInt(getComputedStyle(this.element).getPropertyValue("--navibar-slide"), 10) || 0
  }

  setWidthAndSlide(width, slide) {
    const w = Math.round(Math.max(this.minValue, Math.min(width, this.maxWidth)))
    const s = Math.round(Math.max(0, Math.min(slide, this.maxSlide)))
    this.element.style.setProperty("--navibar-width", `${w}px`)
    this.element.style.setProperty("--navibar-slide", `${s}px`)
  }

  // ================================================================
  // 状態の保存・復元
  // ================================================================
  saveState() {
    try {
      const collapsed = this.isCollapsed()
      localStorage.setItem(this.collapsedKeyValue, collapsed ? "1" : "0")
      if (!collapsed) {
        localStorage.setItem(this.storageKeyValue, String(this.getCurrentWidth()))
      }
    } catch (e) {
      // ignore
    }
  }

  restoreState() {
    try {
      const collapsed = localStorage.getItem(this.collapsedKeyValue) === "1"
      if (collapsed) {
        this.element.classList.add("navibar--collapsed")
        this.setWidthAndSlide(this.minValue, this.maxSlide)
      } else {
        const width = this.getSavedWidth() || this.defaultValue
        this.setWidthAndSlide(width, 0)
      }
    } catch (e) {
      // ignore
    }
  }

  getSavedWidth() {
    try {
      const width = parseInt(localStorage.getItem(this.storageKeyValue), 10)
      if (width >= this.minValue && width <= this.maxWidth) return width
    } catch (e) {
      // ignore
    }
    return null
  }

  // ================================================================
  // Google Maps リサイズ通知
  // ================================================================
  triggerMapResize() {
    requestAnimationFrame(() => {
      if (window.google?.maps && window.mapInstance) {
        google.maps.event.trigger(window.mapInstance, "resize")
      }
    })
  }
}
