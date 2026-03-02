// app/javascript/controllers/myroute_tab/guide_modal_controller.js
// ================================================================
// GuideModalController
// 用途: スポット未追加時ガイドの機能説明モーダル制御
// - モーダルの表示/非表示
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.boundCloseModal = this.closeModal.bind(this)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseModal)
  }

  // モーダル表示
  showModal(event) {
    const feature = event.currentTarget.dataset.feature
    const modal = document.getElementById(`feature-guide-modal-${feature}`)
    if (modal) {
      modal.hidden = false
      document.body.classList.add("feature-guide-modal-open")
      // 開いた時だけリスナー追加（setTimeoutで現在のクリックイベントを除外）
      setTimeout(() => {
        document.addEventListener("click", this.boundCloseModal)
      }, 0)
    }
  }

  // モーダル非表示（オーバーレイ・OKボタンクリック時）
  closeModal(event) {
    const target = event.target
    if (target.closest(".feature-guide-modal__overlay") ||
        target.closest(".feature-guide-modal__btn")) {
      const modal = target.closest(".feature-guide-modal")
      if (modal && !modal.hidden) {
        modal.hidden = true
        document.body.classList.remove("feature-guide-modal-open")
        document.removeEventListener("click", this.boundCloseModal)
      }
    }
  }
}
