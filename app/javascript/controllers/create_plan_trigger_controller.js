import { Controller } from "@hotwired/stimulus"
import { getCsrfToken } from "services/api_client"

// ================================================================
// プラン作成トリガー
// 用途: プラン作成ボタン押下時に位置情報を取得してからplans#create に誘導
// ================================================================
export default class extends Controller {
  static values = {
    url: { type: String, default: "/plans" },
    defaultLat: { type: Number, default: 35.681236 },
    defaultLng: { type: Number, default: 139.767125 }
  }

  create(event) {
    event.preventDefault()

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
    // NOTE: リダイレクトレスポンスを期待するため api_client.post は使用しない
    fetch(this.urlValue, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": getCsrfToken()
      },
      body: JSON.stringify({ lat, lng })
    }).then((response) => {
      if (response.redirected) {
        window.location.href = response.url
      } else {
        alert("プラン作成に失敗しました")
      }
    })
  }
}
