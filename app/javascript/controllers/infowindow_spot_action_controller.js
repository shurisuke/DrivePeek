import { Controller } from "@hotwired/stimulus"

// InfoWindow内のスポット追加・削除ボタン用
// button_toの代わりにfetchでRails APIを呼び出し、マップを再描画する
export default class extends Controller {
  static values = {
    url: String,
    method: { type: String, default: "POST" },
    spotId: Number
  }

  async submit(event) {
    event.preventDefault()

    // Rails APIを呼び出し
    try {
      const response = await this.fetchApi()

      if (response.ok) {
        // 3. Turbo Streamを処理
        const html = await response.text()
        Turbo.renderStreamMessage(html)

        // 4. DOM更新を待ってからマップを再描画
        // Turbo Stream の DOM 更新完了を待つため、requestAnimationFrame を2回ネスト
        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            document.dispatchEvent(new CustomEvent("navibar:updated"))

            // 5. 追加時はプランタブをアクティブにする
            if (this.methodValue === "POST") {
              document.dispatchEvent(new CustomEvent("navibar:activate-tab", { detail: { tab: "plan" } }))
            }
          })
        })
      } else {
        console.error("[infowindow_spot_action] API error:", response.status)
        alert("操作に失敗しました")
      }
    } catch (error) {
      console.error("[infowindow_spot_action] Error:", error)
      alert("操作に失敗しました")
    }
  }

  fetchApi() {
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    const options = {
      method: this.methodValue,
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html"
      }
    }

    // POSTの場合はbodyにspot_idを含める
    if (this.methodValue === "POST" && this.hasSpotIdValue) {
      options.headers["Content-Type"] = "application/json"
      options.body = JSON.stringify({ spot_id: this.spotIdValue })
    }

    return fetch(this.urlValue, options)
  }
}
