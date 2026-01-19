import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "slider",
    "indicator",
    "likeBtn",
    "likeCount",
    "mainBtn",
    "zoomOutBtn",
    "zoomInBtn",
    "commentField"
  ]

  static values = {
    placeId: String,
    photoCount: Number,
    zoomScales: Array,
    zoomIndex: Number
  }

  connect() {
    this.currentSlideIndex = 0
    this.updateZoomButtons()
  }

  // ==================== 閉じる ====================
  close() {
    // カスタムイベントで親に通知（infowindow.jsで処理）
    this.dispatch("close")
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
  toggleLike(event) {
    event.stopPropagation()
    const btn = this.likeBtnTarget
    const isLiked = btn.dataset.liked === "true"
    const icon = btn.querySelector("i")
    let count = parseInt(this.likeCountTarget.textContent, 10) || 0

    if (isLiked) {
      btn.dataset.liked = "false"
      btn.classList.remove("dp-infowindow__stat--liked")
      icon.classList.remove("bi-heart-fill")
      icon.classList.add("bi-heart")
      count = Math.max(0, count - 1)
    } else {
      btn.dataset.liked = "true"
      btn.classList.add("dp-infowindow__stat--liked")
      icon.classList.remove("bi-heart")
      icon.classList.add("bi-heart-fill")
      count += 1
    }

    this.likeCountTarget.textContent = count

    // TODO: サーバーに送信
  }

  // ==================== 写真ギャラリー ====================
  openGallery(event) {
    event.stopPropagation()
    this.dispatch("openGallery", {
      detail: {
        placeId: this.placeIdValue
      }
    })
  }

  // ==================== ボタン ====================
  handleMainButton(event) {
    event.stopPropagation()
    const btn = this.mainBtnTarget
    const planSpotId = btn.dataset.planSpotId

    if (planSpotId) {
      // 削除モード
      this.dispatch("deleteSpot", { detail: { planSpotId } })
    } else {
      // 追加モード
      this.dispatch("addSpot", { detail: { placeId: this.placeIdValue } })
    }
  }

  handleEditButton(event) {
    event.stopPropagation()
    const action = event.currentTarget.dataset.editAction
    this.dispatch("editAction", { detail: { action } })
    this.close()
  }

  // ==================== コメント ====================
  submitComment(event) {
    event.stopPropagation()
    const text = this.commentFieldTarget.value.trim()
    if (!text) return

    // TODO: サーバーに送信
    console.log("Submit comment:", text)
    this.commentFieldTarget.value = ""
  }

  // ==================== 外部からのズーム状態取得 ====================
  get currentZoomScale() {
    return this.zoomScalesValue[this.zoomIndexValue]
  }
}
