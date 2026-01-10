// app/javascript/controllers/community_plan_preview_controller.js
// ================================================================
// コミュニティプランプレビュー用Stimulusコントローラ
// 用途: 「地図で見る」ボタンクリックで該当プランを地図上にプレビュー表示
// ================================================================

import { Controller } from "@hotwired/stimulus"
import { showCommunityPlanPreview, hideCommunityPlanPreview } from "map/community_preview"

// 閉じるボタンの表示/非表示を制御
const showCloseButton = () => {
  const btn = document.getElementById("community-preview-close")
  if (btn) btn.hidden = false
}

const hideCloseButton = () => {
  const btn = document.getElementById("community-preview-close")
  if (btn) btn.hidden = true
}

export default class extends Controller {
  static values = {
    planId: Number,
  }

  connect() {
    // 閉じるボタン用: planIdがない場合はクリアボタンとして動作
    if (!this.hasPlanIdValue) {
      console.log("[community-plan-preview] connected as close button")
    }
  }

  async show(event) {
    event.preventDefault()

    if (!this.planIdValue) {
      console.warn("[community-plan-preview] planId not set")
      return
    }

    console.log("[community-plan-preview] show", { planId: this.planIdValue })
    await showCommunityPlanPreview(this.planIdValue)
    showCloseButton()
  }

  hide() {
    console.log("[community-plan-preview] hide")
    hideCommunityPlanPreview()
    hideCloseButton()
  }
}
