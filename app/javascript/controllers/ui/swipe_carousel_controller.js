import { Controller } from "@hotwired/stimulus"

// PC・スマホ両対応のスワイプカルーセル
export default class extends Controller {
  connect() {
    this.startX = 0
    this.startY = 0
    this.isDragging = false
    this.threshold = 50 // スワイプ判定の閾値（px）

    // カルーセル要素（guideページ用）
    this.carousel = this.element.querySelector("#guideCarousel")
    this.pageDisplay = this.element.querySelector(".guide-carousel__current")

    // タッチイベント（スマホ）
    this.element.addEventListener("touchstart", this.handleTouchStart.bind(this), { passive: true })
    this.element.addEventListener("touchmove", this.handleTouchMove.bind(this), { passive: false })
    this.element.addEventListener("touchend", this.handleTouchEnd.bind(this))

    // マウスイベント（PC）
    this.element.addEventListener("mousedown", this.handleMouseDown.bind(this))
    this.element.addEventListener("mousemove", this.handleMouseMove.bind(this))
    this.element.addEventListener("mouseup", this.handleMouseUp.bind(this))
    this.element.addEventListener("mouseleave", this.handleMouseUp.bind(this))

    // スワイプゾーン・ナビボタンのクリック
    this.element.querySelectorAll(".guide-swipe-zone, .guide-carousel__nav-btn").forEach(btn => {
      btn.addEventListener("click", this.handleNavClick.bind(this))
    })

    // スライド変更イベント
    if (this.carousel) {
      this.carousel.addEventListener("slid.bs.carousel", this.updatePageNumber.bind(this))
    }
  }

  // ナビボタンクリック
  handleNavClick(e) {
    const btn = e.currentTarget
    const direction = btn.dataset.bsSlide

    if (!this.carousel) return
    const bsCarousel = bootstrap.Carousel.getOrCreateInstance(this.carousel)

    if (direction === "prev") {
      bsCarousel.prev()
    } else if (direction === "next") {
      bsCarousel.next()
    }
  }

  // ページ番号更新
  updatePageNumber() {
    if (!this.pageDisplay || !this.carousel) return

    const activeItem = this.carousel.querySelector(".carousel-item.active")
    if (activeItem) {
      const page = activeItem.dataset.page || "1"
      this.pageDisplay.textContent = page
    }
  }

  // タッチ開始
  handleTouchStart(e) {
    this.startX = e.touches[0].clientX
    this.startY = e.touches[0].clientY
    this.isDragging = true
  }

  // タッチ移動
  handleTouchMove(e) {
    if (!this.isDragging) return

    const diffX = e.touches[0].clientX - this.startX
    const diffY = e.touches[0].clientY - this.startY

    // 横スワイプが縦スクロールより大きい場合、スクロールを防止
    if (Math.abs(diffX) > Math.abs(diffY)) {
      e.preventDefault()
    }
  }

  // タッチ終了
  handleTouchEnd(e) {
    if (!this.isDragging) return
    this.isDragging = false

    const endX = e.changedTouches[0].clientX
    const diffX = endX - this.startX

    this.handleSwipe(diffX)
  }

  // マウス押下
  handleMouseDown(e) {
    // ボタン、リンクの場合は無視
    if (e.target.closest("a, button")) return

    this.startX = e.clientX
    this.isDragging = true
    this.element.style.cursor = "grabbing"
  }

  // マウス移動
  handleMouseMove(e) {
    if (!this.isDragging) return
    e.preventDefault()
  }

  // マウス離す
  handleMouseUp(e) {
    if (!this.isDragging) return
    this.isDragging = false
    this.element.style.cursor = ""

    const diffX = e.clientX - this.startX
    this.handleSwipe(diffX)
  }

  // スワイプ処理
  handleSwipe(diffX) {
    if (!this.carousel) return

    const bsCarousel = bootstrap.Carousel.getOrCreateInstance(this.carousel)

    if (diffX > this.threshold) {
      // 右スワイプ → 前へ
      bsCarousel.prev()
    } else if (diffX < -this.threshold) {
      // 左スワイプ → 次へ
      bsCarousel.next()
    }
  }

  disconnect() {
    this.element.removeEventListener("touchstart", this.handleTouchStart)
    this.element.removeEventListener("touchmove", this.handleTouchMove)
    this.element.removeEventListener("touchend", this.handleTouchEnd)
    this.element.removeEventListener("mousedown", this.handleMouseDown)
    this.element.removeEventListener("mousemove", this.handleMouseMove)
    this.element.removeEventListener("mouseup", this.handleMouseUp)
    this.element.removeEventListener("mouseleave", this.handleMouseUp)

    if (this.carousel) {
      this.carousel.removeEventListener("slid.bs.carousel", this.updatePageNumber)
    }
  }
}
