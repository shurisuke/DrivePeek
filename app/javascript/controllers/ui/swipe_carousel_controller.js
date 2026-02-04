import { Controller } from "@hotwired/stimulus"
import { Carousel } from "bootstrap"

// PC・スマホ両対応のスワイプカルーセル
// Pointer Events + setPointerCapture で確実にドラッグ検知
export default class extends Controller {
  connect() {
    this.startX = 0
    this.startY = 0
    this.isDragging = false
    this.threshold = 50

    this.carousel = this.element.querySelector("#guideCarousel")
    this.pageDisplay = this.element.querySelector(".guide-carousel__current")

    // Bind
    this._onPointerDown = this.handlePointerDown.bind(this)
    this._onPointerMove = this.handlePointerMove.bind(this)
    this._onPointerUp = this.handlePointerUp.bind(this)
    this._onNavClick = this.handleNavClick.bind(this)
    this._onSlid = this.updatePageNumber.bind(this)
    this._onDragStart = (e) => e.preventDefault()

    // Pointer Events（タッチ＋マウス統一）
    this.element.addEventListener("pointerdown", this._onPointerDown)
    this.element.addEventListener("pointermove", this._onPointerMove)
    this.element.addEventListener("pointerup", this._onPointerUp)
    this.element.addEventListener("pointercancel", this._onPointerUp)

    // ネイティブドラッグ防止（画像ドラッグ等）
    this.element.addEventListener("dragstart", this._onDragStart)

    // ナビボタンクリック
    this.element.querySelectorAll(".guide-swipe-zone, .guide-carousel__nav-btn").forEach(btn => {
      btn.addEventListener("click", this._onNavClick)
    })

    if (this.carousel) {
      this.carousel.addEventListener("slid.bs.carousel", this._onSlid)
    }
  }

  handleNavClick(e) {
    const btn = e.currentTarget
    const direction = btn.dataset.bsSlide

    if (!this.carousel) return
    const bsCarousel = Carousel.getOrCreateInstance(this.carousel)

    if (direction === "prev") {
      bsCarousel.prev()
    } else if (direction === "next") {
      bsCarousel.next()
    }
  }

  updatePageNumber() {
    if (!this.pageDisplay || !this.carousel) return

    const activeItem = this.carousel.querySelector(".carousel-item.active")
    if (activeItem) {
      const page = activeItem.dataset.page || "1"
      this.pageDisplay.textContent = page
    }
  }

  handlePointerDown(e) {
    if (e.target.closest("a, button")) return

    this.startX = e.clientX
    this.startY = e.clientY
    this.isDragging = true
    this.element.style.cursor = "grabbing"

    this.element.setPointerCapture(e.pointerId)
    e.preventDefault()
  }

  handlePointerMove(e) {
    if (!this.isDragging) return
    e.preventDefault()
  }

  handlePointerUp(e) {
    if (!this.isDragging) return
    this.isDragging = false
    this.element.style.cursor = ""

    const diffX = e.clientX - this.startX
    this.handleSwipe(diffX)
  }

  handleSwipe(diffX) {
    if (!this.carousel) return

    const bsCarousel = Carousel.getOrCreateInstance(this.carousel)

    if (diffX > this.threshold) {
      bsCarousel.prev()
    } else if (diffX < -this.threshold) {
      bsCarousel.next()
    }
  }

  disconnect() {
    this.element.removeEventListener("pointerdown", this._onPointerDown)
    this.element.removeEventListener("pointermove", this._onPointerMove)
    this.element.removeEventListener("pointerup", this._onPointerUp)
    this.element.removeEventListener("pointercancel", this._onPointerUp)
    this.element.removeEventListener("dragstart", this._onDragStart)

    if (this.carousel) {
      this.carousel.removeEventListener("slid.bs.carousel", this._onSlid)
    }
  }
}
