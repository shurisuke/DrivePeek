import { Controller } from "@hotwired/stimulus"
import { clearAiSuggestionMarkers } from "map/state"
import { postTurboStream } from "services/api_client"

// ================================================================
// AiConditionModalController
// 用途: AI提案条件設定モーダルの制御（プランモード/スポットモード対応）
// - プランモード: エリア選択 → スロットごとにジャンル指定
// - スポットモード: エリア選択 → 単一ジャンル + 件数指定
// ================================================================

export default class extends Controller {
  static values = {
    planId: Number,
    mode: String  // "plan" | "spots"
  }
  static targets = [
    "title",
    "planContent", "areaInfo", "spotCount", "slot",
    "spotContent", "spotGenre", "spotResultCount",
    "submitBtn", "loading"
  ]

  connect() {
    this.areaData = null
  }

  // ============================================
  // モーダル開閉
  // ============================================

  open(event) {
    const detail = event.detail || {}
    if (!detail.radius_km) return

    this.modeValue = detail.mode || "plan"
    this.areaData = {
      center_lat: detail.center_lat,
      center_lng: detail.center_lng,
      radius_km: detail.radius_km
    }

    // モードに応じてUI切り替え
    if (this.modeValue === "spots") {
      this.titleTarget.textContent = "スポット提案の条件"
      this.planContentTarget.hidden = true
      this.spotContentTarget.hidden = false
    } else {
      this.titleTarget.textContent = "プラン条件を設定"
      this.planContentTarget.hidden = false
      this.spotContentTarget.hidden = true
    }

    this.areaInfoTarget.textContent = `選択エリア（半径 ${this.areaData.radius_km.toFixed(1)} km）`
    this.#showModal()
  }

  close() {
    this.element.hidden = true
    document.body.style.overflow = ""
  }

  // キャンセル時は円も消去
  cancel() {
    clearAiSuggestionMarkers()
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
  // AI提案実行
  // ============================================

  async submit() {
    if (this.modeValue === "plan") {
      await this.#submitPlanMode()
    } else {
      await this.#submitSpotMode()
    }
  }

  // ============================================
  // Private
  // ============================================

  #showModal() {
    this.element.hidden = false
    document.body.style.overflow = "hidden"
  }

  async #submitPlanMode() {
    if (!this.areaData) return

    const slots = this.slotTargets
      .filter(slot => !slot.hidden)
      .map(slot => {
        const select = slot.querySelector("select")
        const value = select?.value
        return { genre_id: value === "" ? null : parseInt(value, 10) }
      })

    await this.#submitWithLoading({ ...this.areaData, slots })
  }

  async #submitSpotMode() {
    if (!this.areaData) return

    await this.#submitWithLoading({
      ...this.areaData,
      mode: "spots",
      genre_id: parseInt(this.spotGenreTarget.value, 10),
      count: parseInt(this.spotResultCountTarget.value, 10)
    })
  }

  async #submitWithLoading(body) {
    this.submitBtnTarget.disabled = true
    this.loadingTarget.hidden = false

    try {
      await postTurboStream(`/api/ai_area/suggest?plan_id=${this.planIdValue}`, body)
      this.close()
    } catch (error) {
      console.error("[AiConditionModal] submit error:", error)
      alert("エラーが発生しました。もう一度お試しください。")
    } finally {
      this.submitBtnTarget.disabled = false
      this.loadingTarget.hidden = true
    }
  }
}
