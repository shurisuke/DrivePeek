import { Controller } from "@hotwired/stimulus"

/**
 * 写真ギャラリーモーダル用Stimulusコントローラ
 * - document上の "photo-gallery:open" イベントで開く
 * - CSS scroll-snapによるスワイプ対応
 * - 遅延読み込み（1枚目即時、残りはモーダル表示時に取得）
 */
export default class extends Controller {
  static targets = ["slider", "indicator", "title", "prevBtn", "nextBtn"]

  // Google Places photos 配列（getUrl()を持つ）
  photos = []
  currentIndex = 0

  connect() {
    // body にスクロール禁止用クラスを追加/削除するための参照
    this.bodyClass = "photo-gallery-open"
  }

  /**
   * モーダルを開く
   * @param {CustomEvent} event - detail: { placeId, photos, name }
   */
  open(event) {
    const { photos, name } = event.detail
    if (!photos || photos.length === 0) return

    this.photos = photos.slice(0, 5) // 最大5枚
    this.currentIndex = 0

    // タイトル設定
    if (this.hasTitleTarget) {
      this.titleTarget.textContent = name || ""
    }

    // スライダー・インジケーター生成
    this.renderSlider()
    this.renderIndicator()

    // モーダル表示
    this.element.hidden = false
    document.body.classList.add(this.bodyClass)

    // 最初のスライドへスクロール
    this.scrollToIndex(0, false)

    // 矢印の初期表示
    this.updateArrows()
  }

  /**
   * モーダルを閉じる
   */
  close() {
    this.element.hidden = true
    document.body.classList.remove(this.bodyClass)

    // クリーンアップ
    this.sliderTarget.innerHTML = ""
    this.indicatorTarget.innerHTML = ""
    this.photos = []
  }

  /**
   * スライダーをレンダリング
   */
  renderSlider() {
    this.sliderTarget.innerHTML = this.photos.map((photo, index) => {
      const photoUrl = photo.getUrl ? photo.getUrl({ maxWidth: 1200, maxHeight: 900 }) : null
      if (!photoUrl) {
        return `<div class="photo-gallery-modal__slide">
          <div class="photo-gallery-modal__loading">写真を読み込めませんでした</div>
        </div>`
      }

      return `<div class="photo-gallery-modal__slide" data-index="${index}">
        <div class="photo-gallery-modal__spinner"></div>
        <img class="photo-gallery-modal__img"
             src="${photoUrl}"
             alt="写真 ${index + 1}"
             loading="${index === 0 ? 'eager' : 'lazy'}">
      </div>`
    }).join("")

    // 画像読み込み完了時のフェードイン処理
    this.sliderTarget.querySelectorAll(".photo-gallery-modal__img").forEach(img => {
      const showImage = () => {
        img.classList.add("is-loaded")
        const spinner = img.previousElementSibling
        if (spinner) spinner.style.display = "none"
      }

      if (img.complete) {
        showImage()
      } else {
        img.addEventListener("load", showImage, { once: true })
      }
    })
  }

  /**
   * インジケーター（ドット）をレンダリング
   */
  renderIndicator() {
    if (this.photos.length <= 1) {
      this.indicatorTarget.innerHTML = ""
      return
    }

    this.indicatorTarget.innerHTML = this.photos.map((_, index) => {
      const activeClass = index === 0 ? " photo-gallery-modal__dot--active" : ""
      return `<span class="photo-gallery-modal__dot${activeClass}"
                    data-index="${index}"
                    data-action="click->photo-gallery#goToSlide"></span>`
    }).join("")
  }

  /**
   * スクロールイベントでインジケーター・矢印更新
   */
  onScroll() {
    const slider = this.sliderTarget
    const slideWidth = slider.clientWidth
    const newIndex = Math.round(slider.scrollLeft / slideWidth)

    if (newIndex !== this.currentIndex && newIndex >= 0 && newIndex < this.photos.length) {
      this.currentIndex = newIndex
      this.updateIndicator()
      this.updateArrows()
    }
  }

  /**
   * ドットクリックでスライド移動
   */
  goToSlide(event) {
    const index = parseInt(event.target.dataset.index, 10)
    if (!Number.isNaN(index)) {
      this.scrollToIndex(index)
    }
  }

  /**
   * 前の写真へ
   */
  prev() {
    if (this.currentIndex > 0) {
      this.scrollToIndex(this.currentIndex - 1)
    }
  }

  /**
   * 次の写真へ
   */
  next() {
    if (this.currentIndex < this.photos.length - 1) {
      this.scrollToIndex(this.currentIndex + 1)
    }
  }

  /**
   * 指定インデックスへスクロール
   */
  scrollToIndex(index, smooth = true) {
    const slider = this.sliderTarget
    const slideWidth = slider.clientWidth
    slider.scrollTo({
      left: slideWidth * index,
      behavior: smooth ? "smooth" : "instant"
    })
    this.currentIndex = index
    this.updateIndicator()
    this.updateArrows()
  }

  /**
   * インジケーターのアクティブ状態を更新
   */
  updateIndicator() {
    const dots = this.indicatorTarget.querySelectorAll(".photo-gallery-modal__dot")
    dots.forEach((dot, index) => {
      dot.classList.toggle("photo-gallery-modal__dot--active", index === this.currentIndex)
    })
  }

  /**
   * 矢印ボタンの表示/非表示を更新
   */
  updateArrows() {
    if (this.photos.length <= 1) {
      // 1枚以下なら両方非表示
      if (this.hasPrevBtnTarget) this.prevBtnTarget.hidden = true
      if (this.hasNextBtnTarget) this.nextBtnTarget.hidden = true
      return
    }

    // 最初の写真なら左矢印非表示
    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.hidden = this.currentIndex === 0
    }

    // 最後の写真なら右矢印非表示
    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.hidden = this.currentIndex === this.photos.length - 1
    }
  }
}
