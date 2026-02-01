import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "slider",
    "indicator",
    "zoomOutBtn",
    "zoomInBtn"
  ]

  static values = {
    spotId: Number,
    placeId: String,
    photoCount: Number,
    zoomScales: Array,
    zoomIndex: Number
  }

  connect() {
    this.currentSlideIndex = 0
    this.updateZoomButtons()
  }

  // ==================== 写真スライダー ====================
  prevSlide(event) {
    event.stopPropagation()
    this.goToSlide(this.currentSlideIndex - 1)
  }

  nextSlide(event) {
    event.stopPropagation()
    this.goToSlide(this.currentSlideIndex + 1)
  }

  goToSlide(event) {
    // イベントから呼ばれた場合はdata-indexを取得
    let index = typeof event === "number"
      ? event
      : parseInt(event.currentTarget.dataset.index, 10)

    const slides = this.sliderTarget.querySelectorAll(".dp-infowindow__slide")
    const dots = this.hasIndicatorTarget
      ? this.indicatorTarget.querySelectorAll(".dp-infowindow__dot")
      : []

    // ループ処理
    if (index < 0) index = slides.length - 1
    if (index >= slides.length) index = 0

    slides.forEach((slide, i) => {
      slide.classList.toggle("dp-infowindow__slide--active", i === index)
    })
    dots.forEach((dot, i) => {
      dot.classList.toggle("dp-infowindow__dot--active", i === index)
    })

    this.currentSlideIndex = index
  }

  // ==================== ズーム ====================
  zoomIn(event) {
    event.stopPropagation()
    if (this.zoomIndexValue < this.zoomScalesValue.length - 1) {
      this.zoomIndexValue++
      this.applyZoom()
    }
  }

  zoomOut(event) {
    event.stopPropagation()
    if (this.zoomIndexValue > 0) {
      this.zoomIndexValue--
      this.applyZoom()
    }
  }

  applyZoom() {
    // 全スケールクラスを削除して現在のスケールクラスを追加
    this.zoomScalesValue.forEach(scale => {
      this.element.classList.remove(`dp-infowindow--${scale}`)
    })
    const currentScale = this.zoomScalesValue[this.zoomIndexValue]
    this.element.classList.add(`dp-infowindow--${currentScale}`)
    this.updateZoomButtons()

    // infowindow.jsに通知（次回のInfoWindow生成時に使用）
    this.dispatch("zoomChange", { detail: { zoomIndex: this.zoomIndexValue } })
  }

  updateZoomButtons() {
    if (this.hasZoomOutBtnTarget) {
      this.zoomOutBtnTarget.disabled = this.zoomIndexValue === 0
    }
    if (this.hasZoomInBtnTarget) {
      this.zoomInBtnTarget.disabled = this.zoomIndexValue === this.zoomScalesValue.length - 1
    }
  }

  // ==================== いいね ====================
  // Turbo Frame で処理するため、JSでの処理は不要

  // ==================== 写真ギャラリー ====================
  openGallery(event) {
    event.stopPropagation()
    // InfoWindow内の写真URLを取得
    const imgs = this.element.querySelectorAll(".dp-infowindow__img")
    const photoUrls = Array.from(imgs).map(img => img.src).filter(Boolean)

    this.dispatch("openGallery", {
      detail: {
        photoUrls
      }
    })
  }

  // ==================== 編集ボタン（出発・帰宅地点用） ====================
  handleEditButton(event) {
    event.stopPropagation()
    const action = event.currentTarget.dataset.editAction
    this.dispatch("editAction", { detail: { action } })
    // InfoWindowを閉じる（Googleの閉じるボタンをクリック）
    this.element.closest(".gm-style-iw-a")?.querySelector("button.gm-ui-hover-effect")?.click()
  }

  // ==================== 外部からのズーム状態取得 ====================
  get currentZoomScale() {
    return this.zoomScalesValue[this.zoomIndexValue]
  }
}
