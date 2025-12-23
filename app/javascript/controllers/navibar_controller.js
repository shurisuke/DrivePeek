// app/javascript/controllers/navibar_controller.js
//
// ================================================================
// Navibar（単一責務）
// 用途: プラン作成画面のタブ切替のみ
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "content"]

  connect() {
    console.log("[navibar] connect", {
      buttons: this.buttonTargets.map((b) => ({ tab: b.dataset.tab, active: b.classList.contains("active") }))
    })
  }

  switch(event) {
    const selected = event.currentTarget.dataset.tab
    console.log("[navibar] switch", { selected })

    // ボタンの active 状態を切り替え
    this.buttonTargets.forEach((btn) => btn.classList.remove("active"))
    event.currentTarget.classList.add("active")

    // コンテンツの表示切り替え
    this.contentTargets.forEach((content) => {
      content.classList.remove("active")
      if (content.classList.contains(`tab-${selected}`)) {
        content.classList.add("active")
      }
    })
  }
}
