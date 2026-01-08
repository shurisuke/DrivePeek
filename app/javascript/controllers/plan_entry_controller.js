import { Controller } from "@hotwired/stimulus"

// ================================================================
// プラン作成エントリー画面
// 用途: 既存プランがない場合は自動でプラン作成を開始
// ================================================================
export default class extends Controller {
  static targets = ["modal", "loading", "autoTrigger"]
  static values = { hasPlan: Boolean }

  connect() {
    if (!this.hasPlanValue) {
      // 既存プランがない場合は自動でプラン作成を開始
      // 子コントローラーの初期化を待つため次フレームで実行
      requestAnimationFrame(() => {
        this.autoTriggerTarget.click()
      })
    }
  }
}
