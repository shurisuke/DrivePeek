import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  clearSearchHitMarkers,
  clearStartPointMarker,
  setStartPointMarker,
} from "map/state"
import { geocodeAddress, normalizeDisplayAddress } from "map/geocoder"

// ================================================================
// 出発地点変更UI
// 用途:
// - 「変更」ボタンでフォームを開閉
// - Enterで住所をGeocodingして、出発地点ピンを差し替え
// - 検索ヒットピンがあれば全消去
// - 地図をズーム/フォーカス（デフォルト挙動）
// - サーバへ更新をPATCH（StartPointsController#update）
// ================================================================
export default class extends Controller {
  static targets = ["toggle", "editArea", "input", "address"]
  static values = {
    iconUrl: { type: String, default: "/icons/house-pin.png" },
    iconWidth: { type: Number, default: 50 },
    iconHeight: { type: Number, default: 55 },
    focusZoom: { type: Number, default: 16 }
  }

  connect() {
    this.isImeComposing = false
  }

  toggle() {
    const isOpen = this.editAreaTarget.hidden === false

    this.editAreaTarget.hidden = isOpen
    this.toggleTarget.setAttribute("aria-expanded", String(!isOpen))

    if (!isOpen) this.inputTarget.focus()
  }

  compositionStart() {
    this.isImeComposing = true
  }

  compositionEnd() {
    this.isImeComposing = false
  }

  async search(event) {
    // IME変換中Enterは発火させない（日本語変換対策）
    if (event.isComposing || this.isImeComposing || event.keyCode === 229) return

    // Enter以外は無視
    if (event.key !== "Enter") return

    event.preventDefault()

    const map = getMapInstance()
    if (!map) {
      console.warn("🟡 map がまだ初期化されていません")
      return
    }

    const query = this.inputTarget.value.trim()
    if (!query) return

    try {
      // 検索ヒット地点ピンがある場合、全て消去
      clearSearchHitMarkers()

      // 住所を Geocoding
      const { location, viewport, formattedAddress } = await geocodeAddress(query)

      // 表示用に整形（日本/郵便番号を落とす）
      const displayAddress = normalizeDisplayAddress(formattedAddress)

      // スタート地点pinを消して差し直す
      clearStartPointMarker()

      const marker = new google.maps.Marker({
        map,
        position: location,
        title: "出発地点",
        icon: {
          url: this.iconUrlValue,
          scaledSize: new google.maps.Size(this.iconWidthValue, this.iconHeightValue),
        },
      })

      setStartPointMarker(marker)

      // デフォルト挙動：
      // - viewport がある → fitBounds（Google Maps標準の寄せ）
      // - viewport がない → panTo + setZoom
      if (viewport) {
        map.fitBounds(viewport)
      } else {
        map.panTo(location)
        map.setZoom(this.focusZoomValue)
      }

      // UIの住所表示も更新
      this.addressTarget.textContent = displayAddress || query

      // フォームは閉じる
      this.editAreaTarget.hidden = true
      this.toggleTarget.setAttribute("aria-expanded", "false")

      // サーバへ保存（StartPointsController#update）
      const lat = typeof location.lat === "function" ? location.lat() : location.lat
      const lng = typeof location.lng === "function" ? location.lng() : location.lng

      const resJson = await this.persistStartPoint({
        lat,
        lng,
        address: displayAddress || query,
      })

      // サーバが返した値で最終上書き（表示ズレ防止）
      if (resJson?.ok && resJson?.start_point?.address) {
        this.addressTarget.textContent = resJson.start_point.address
      }

      console.log("✅ start_point update success:", resJson)
    } catch (err) {
      console.warn("⚠️ 出発地点の更新に失敗:", err)
      alert("住所が見つからない、または保存に失敗しました。別のキーワードで試してください。")
    }
  }

  async persistStartPoint({ lat, lng, address }) {
    const planId = this.detectPlanIdFromPath()
    if (!planId) {
      console.warn("🟡 planId が特定できません（サーバ更新をスキップ）")
      return null
    }

    const token = document.querySelector('meta[name="csrf-token"]')?.content
    const url = `/plans/${planId}/start_point`

    const res = await fetch(url, {
      method: "PATCH",
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": token,
        Accept: "application/json",
      },
      body: JSON.stringify({
        start_point: { lat, lng, address },
      }),
    })

    const json = await res.json().catch(() => null)

    if (!res.ok || !json?.ok) {
      const msg = json?.errors?.join(", ") || `status=${res.status}`
      throw new Error(`start_point update failed: ${msg}`)
    }

    return json
  }

  detectPlanIdFromPath() {
    const m = window.location.pathname.match(/\/plans\/(\d+)(\/edit)?/)
    return m ? m[1] : null
  }
}
