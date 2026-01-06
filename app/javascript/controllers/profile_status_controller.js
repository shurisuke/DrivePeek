import { Controller } from "@hotwired/stimulus"
import { patch } from "services/api_client"

// ================================================================
// プロフィール公開設定の非同期更新
// ================================================================
export default class extends Controller {
  static values = {
    url: String
  }

  async update(event) {
    const status = event.target.value

    try {
      const data = await patch(this.urlValue, { user: { status: status } })
      if (data.success) {
        this.showMessage("設定を更新しました", "success")
      } else {
        this.showMessage("更新に失敗しました", "error")
      }
    } catch {
      this.showMessage("更新に失敗しました", "error")
    }
  }

  showMessage(message, type) {
    // 簡易的なフラッシュメッセージ表示
    const flash = document.createElement("div")
    flash.className = `flash-message flash-message--${type}`
    flash.textContent = message
    flash.style.cssText = `
      position: fixed;
      top: 20px;
      left: 20px;
      padding: 12px 24px;
      border-radius: 8px;
      background: ${type === "success" ? "#4CAF50" : "#f44336"};
      color: white;
      font-weight: bold;
      z-index: 9999;
      animation: fadeIn 0.3s ease;
    `
    document.body.appendChild(flash)

    setTimeout(() => {
      flash.remove()
    }, 3000)
  }
}
