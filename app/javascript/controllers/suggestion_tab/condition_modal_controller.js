import { Controller } from "@hotwired/stimulus"
import { clearSuggestionAll } from "map/state"
import { postTurboStream } from "services/navibar_api"

// ================================================================
// SuggestionConditionModalController
// 用途: 提案条件設定モーダルの制御
// - プランモード: エリア選択 → スロットごとにジャンル指定
// ================================================================

export default class extends Controller {
  static values = {
    planId: Number
  }
  static targets = [
    "title",
    "mainView", "genreView",
    "areaInfo", "spotCount", "slot", "slotBtn", "slotInput",
    "submitBtn", "loading"
  ]

  connect() {
    this.areaData = null
    this.editingSlotIndex = null  // 編集中のスロットインデックス

    // エリア選択完了イベントを監視
    this.boundOpen = this.open.bind(this)
    document.addEventListener("suggestion:areaSelected", this.boundOpen)
  }

  disconnect() {
    document.removeEventListener("suggestion:areaSelected", this.boundOpen)
  }

  // ============================================
  // モーダル開閉
  // ============================================

  open(event) {
    const detail = event.detail || {}
    if (!detail.radius_km) return

    this.areaData = {
      center_lat: detail.center_lat,
      center_lng: detail.center_lng,
      radius_km: detail.radius_km
    }

    // フォームを初期状態にリセット
    this.#resetForm()

    this.titleTarget.textContent = "プラン条件を設定"
    this.areaInfoTarget.textContent = `選択エリア（半径 ${this.areaData.radius_km.toFixed(1)} km）`
    this.#showModal()
  }

  close() {
    this.element.hidden = true
    document.body.style.overflow = ""
  }

  // キャンセル時は円も消去
  cancel() {
    clearSuggestionAll()
    this.close()
  }

  // ============================================
  // スロット表示/非表示（プランモード用）
  // ============================================

  updateSlots() {
    const count = parseInt(this.spotCountTarget.value, 10)
    this.slotTargets.forEach((slot, i) => {
      slot.hidden = i >= count
    })
  }

  // ============================================
  // ジャンル選択モード
  // ============================================

  openGenreSelect(event) {
    const slot = event.currentTarget.closest("[data-slot-index]")
    this.editingSlotIndex = slot ? parseInt(slot.dataset.slotIndex, 10) : null

    this.mainViewTarget.hidden = true
    this.genreViewTarget.hidden = false
  }

  closeGenreSelect() {
    this.mainViewTarget.hidden = false
    this.genreViewTarget.hidden = true
  }

  toggleGroup(event) {
    event.stopPropagation()
    const group = event.currentTarget.closest(".selection-list__group")
    if (group) {
      group.classList.toggle("is-expanded")
    }
  }

  selectGenre(event) {
    const { genreId, genreName } = event.currentTarget.dataset

    if (this.editingSlotIndex !== null) {
      this.slotBtnTargets[this.editingSlotIndex].querySelector("span").textContent = genreName
      this.slotInputTargets[this.editingSlotIndex].value = genreId
    }

    this.closeGenreSelect()
  }

  // ============================================
  // AI提案実行
  // ============================================

  async submit() {
    await this.#submitPlanMode()
  }

  // ============================================
  // Private
  // ============================================

  #showModal() {
    this.element.hidden = false
    document.body.style.overflow = "hidden"
  }

  // フォームを初期状態にリセット
  #resetForm() {
    // スポット数を3にリセット
    this.spotCountTarget.value = "3"

    // スロットを初期状態にリセット
    this.slotTargets.forEach((slot, i) => {
      slot.hidden = i >= 3
    })
    this.slotBtnTargets.forEach(btn => {
      btn.querySelector("span").textContent = "おまかせ"
    })
    this.slotInputTargets.forEach(input => {
      input.value = ""
    })
  }

  async #submitPlanMode() {
    if (!this.areaData) return

    const slots = this.slotInputTargets
      .filter((_, i) => !this.slotTargets[i].hidden)
      .map(input => {
        const value = input.value
        return { genre_id: value === "" ? null : parseInt(value, 10) }
      })

    await this.#submitWithLoading({ ...this.areaData, slots })
  }

  async #submitWithLoading(body) {
    this.submitBtnTarget.disabled = true
    this.loadingTarget.hidden = false

    try {
      await postTurboStream(`/suggestions/suggest?plan_id=${this.planIdValue}`, body)
      this.close()
      // UXフローを直接実行
      this.#executeUxFlow()
    } catch (error) {
      console.error("[SuggestionConditionModal] submit error:", error)
      alert("エラーが発生しました。もう一度お試しください。")
    } finally {
      this.submitBtnTarget.disabled = false
      this.loadingTarget.hidden = true
    }
  }

  // UXフロー: ボトムシート展開・スクロール・パン
  #executeUxFlow() {
    // 1. モバイル: ボトムシートをmidに展開
    const isMobile = this.#expandBottomSheet()

    // 2. 新規メッセージが上部に来る位置までスクロール（DOM更新後）
    setTimeout(() => {
      this.#scrollToNewMessage()
    }, 150)

    // 3. モバイル: ボトムシート展開完了後にサークル中心へパン
    if (isMobile && this.areaData) {
      setTimeout(() => {
        this.#panToCircle()
      }, 350) // ボトムシートアニメーション(300ms)完了後
    }
  }

  #expandBottomSheet() {
    const navibar = document.querySelector("[data-controller~='ui--bottom-sheet']")
    if (!navibar) return false

    const controller = this.application.getControllerForElementAndIdentifier(navibar, "ui--bottom-sheet")
    if (controller && controller.isMobile) {
      controller.setState({ params: { state: "mid" } })
      return true
    }
    return false
  }

  #panToCircle() {
    import("map/visual_center").then(({ panToVisualCenter }) => {
      panToVisualCenter({
        lat: this.areaData.center_lat,
        lng: this.areaData.center_lng
      })
    })
  }

  #scrollToNewMessage() {
    // メッセージコンテナ（スクロールコンテナ）を取得
    const messages = document.getElementById("suggestion-messages")
    if (!messages) return

    // 最後のスクロール位置マーカーを取得
    const markers = messages.querySelectorAll(".suggestion-scroll-marker")
    const marker = markers[markers.length - 1]
    if (!marker) return

    // マーカーがスクロール領域の上部に来る位置を計算
    const markerRect = marker.getBoundingClientRect()
    const containerRect = messages.getBoundingClientRect()
    const targetScroll = messages.scrollTop + (markerRect.top - containerRect.top)

    messages.scrollTop = targetScroll
  }
}
