// app/javascript/controllers/plan_spot_delete_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    planId: Number,
    planSpotId: Number,
  }

  // turbo:submit-end で呼ぶ想定
  afterSubmit(event) {
    if (!event.detail?.success) return

    // ✅ 先に value を退避（requestAnimationFrame 時点で disconnect されている可能性あり）
    const planId = this.planIdValue
    const planSpotId = this.planSpotIdValue

    // Turbo Stream (remove) がDOMへ反映された"後"に通知したい
    requestAnimationFrame(() => {
      document.dispatchEvent(
        new CustomEvent("plan:spot-deleted", {
          detail: { planId, planSpotId },
        })
      )
    })
  }
}
