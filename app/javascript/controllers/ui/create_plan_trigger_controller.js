import { Controller } from "@hotwired/stimulus"
import { getCsrfToken } from "services/api_client"

// ================================================================
// プラン作成トリガー
// 用途: プラン作成ボタン押下時に位置情報を取得してからplans#create に誘導
// スポット詳細画面では、マーカークリック時にスポットIDを動的に更新
// ================================================================
export default class extends Controller {
  static values = {
    url: { type: String, default: "/plans" },
    defaultLat: { type: Number, default: 35.681236 },
    defaultLng: { type: Number, default: 139.767125 },
    listenSpotChange: { type: Boolean, default: false }
  }

  connect() {
    if (this.listenSpotChangeValue) {
      this.boundHandleSpotChange = this.handleSpotChange.bind(this)
      document.addEventListener("spotShow:spotChanged", this.boundHandleSpotChange)
    }
  }

  disconnect() {
    if (this.boundHandleSpotChange) {
      document.removeEventListener("spotShow:spotChanged", this.boundHandleSpotChange)
    }
  }

  handleSpotChange(event) {
    const { spotId } = event.detail
    if (spotId) {
      this.urlValue = `/plans?add_spot=${spotId}`
    }
  }

  create(event) {
    event.preventDefault()
    this.showLoading()

    if (navigator.geolocation) {
      navigator.geolocation.getCurrentPosition(
        (position) => {
          this.sendRequest(position.coords.latitude, position.coords.longitude)
        },
        () => {
          alert("現在地の取得に失敗しました。東京を出発地点としてプランを作成します。")
          this.sendRequest(this.defaultLatValue, this.defaultLngValue)
        }
      )
    } else {
      alert("位置情報が取得できません。東京を出発地点としてプランを作成します。")
      this.sendRequest(this.defaultLatValue, this.defaultLngValue)
    }
  }

  sendRequest(lat, lng) {
    const body = { lat, lng }

    // NOTE: リダイレクトレスポンスを期待するため api_client.post は使用しない
    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": getCsrfToken()
      },
      body: JSON.stringify(body)
    }).then((response) => {
      if (response.redirected) {
        window.location.href = response.url
      } else {
        this.hideLoading()
        alert("プラン作成に失敗しました")
      }
    }).catch(() => {
      this.hideLoading()
      alert("プラン作成に失敗しました")
    })
  }

  showLoading() {
    // 既存のローディング要素があれば使用、なければ作成
    let overlay = document.getElementById("create-plan-loading")
    if (!overlay) {
      overlay = document.createElement("div")
      overlay.id = "create-plan-loading"
      overlay.className = "create-plan-loading"
      overlay.innerHTML = `
        <div class="create-plan-loading__content">
          <i class="fa-solid fa-spinner fa-spin fa-2x"></i>
          <p>プランを準備しています...</p>
        </div>
      `
      document.body.appendChild(overlay)
    }
    overlay.hidden = false
  }

  hideLoading() {
    const overlay = document.getElementById("create-plan-loading")
    if (overlay) {
      overlay.hidden = true
    }
  }
}
