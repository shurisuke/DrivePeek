// app/javascript/controllers/start_point_editor_controller.js
//
// ================================================================
// StartPoint Editor（単一責務）
// 用途:
// - 「変更」ボタンでフォームを開閉
// - 変更フォームを「ボタンの右側」に position: fixed で表示し、planbar の overflow から脱出
// - Enterで住所をGeocodingして、出発地点ピンを差し替え
// - 検索ヒットピンがあれば全消去
// - 地図をズーム/フォーカス（viewportがあればfitBounds）
// - サーバへ更新をPATCH（StartPointsController#update）
// - デバッグ用 console.log を追加
// ================================================================

import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  clearSearchHitMarkers,
  clearStartPointMarker,
  setStartPointMarker,
} from "map/state"
import { geocodeAddress, normalizeDisplayAddress } from "map/geocoder"
import { patch } from "services/api_client"

export default class extends Controller {
  static targets = ["toggle", "editArea", "input", "address"]
  static values = {
    iconUrl: { type: String, default: "/icons/house-pin.png" },
    iconWidth: { type: Number, default: 50 },
    iconHeight: { type: Number, default: 55 },
    focusZoom: { type: Number, default: 16 },
  }

  connect() {
    console.log("[start-point-editor] connect", {
      hasAddress: this.hasAddressTarget,
      hasToggle: this.hasToggleTarget,
      hasEditArea: this.hasEditAreaTarget,
      hasInput: this.hasInputTarget,
    })

    this.isImeComposing = false
    this._onReposition = this.reposition.bind(this)
  }

  disconnect() {
    console.log("[start-point-editor] disconnect")
    window.removeEventListener("resize", this._onReposition)
    window.removeEventListener("scroll", this._onReposition, true)
  }

  toggle() {
    const willOpen = this.editAreaTarget.hidden
    console.log("[start-point-editor] toggle", { willOpen })

    if (willOpen) {
      this.editAreaTarget.hidden = false
      this.toggleTarget.setAttribute("aria-expanded", "true")

      // ✅ planbar の overflow の影響を受けないように fixed で出す
      this.editAreaTarget.style.position = "fixed"
      this.editAreaTarget.style.zIndex = "9999"

      // 見た目（必要なら調整）
      this.editAreaTarget.style.width = "320px"
      this.editAreaTarget.style.maxWidth = "calc(100vw - 24px)"
      this.editAreaTarget.style.margin = "0"

      this.reposition()

      window.addEventListener("resize", this._onReposition)
      window.addEventListener("scroll", this._onReposition, true)

      this.inputTarget.focus()
      return
    }

    this.close()
  }

  close() {
    console.log("[start-point-editor] close")

    this.editAreaTarget.hidden = true
    this.toggleTarget.setAttribute("aria-expanded", "false")

    window.removeEventListener("resize", this._onReposition)
    window.removeEventListener("scroll", this._onReposition, true)

    // スタイルを戻す（次回開いた時に再計算する）
    this.editAreaTarget.style.position = ""
    this.editAreaTarget.style.top = ""
    this.editAreaTarget.style.left = ""
    this.editAreaTarget.style.zIndex = ""
    this.editAreaTarget.style.width = ""
    this.editAreaTarget.style.maxWidth = ""
    this.editAreaTarget.style.margin = ""
  }

  reposition() {
    const rect = this.toggleTarget.getBoundingClientRect()

    const gapX = 10
    const offsetY = 50 // ← ここだけで調整（goal_point と同じ）

    const left = rect.right + gapX
    const top = rect.top + offsetY

    const safeLeft = Math.min(left, window.innerWidth - 20)
    const safeTop = Math.max(top, 12)

    this.editAreaTarget.style.left = `${safeLeft}px`
    this.editAreaTarget.style.top = `${safeTop}px`

    console.log("[start-point-editor] reposition", { safeLeft, safeTop })
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
    if (event.key !== "Enter") return

    event.preventDefault()

    const map = getMapInstance()
    if (!map) {
      console.warn("[start-point-editor] map is not ready")
      return
    }

    const planId = this.detectPlanId()
    if (!planId) {
      console.warn("[start-point-editor] planId missing")
      return
    }

    const query = this.inputTarget.value.trim()
    if (!query) return

    console.log("[start-point-editor] search begin", { planId, query })

    try {
      // 検索ヒット地点ピンがある場合、全て消去
      clearSearchHitMarkers()

      // 住所を Geocoding（geocoder の返り値差を吸収）
      const geo = await geocodeAddress(query)
      console.log("[start-point-editor] geocode result", geo)

      const formattedAddress = geo?.formattedAddress || geo?.address || query
      const displayAddress = normalizeDisplayAddress
        ? normalizeDisplayAddress(formattedAddress)
        : formattedAddress

      const location =
        geo?.location ||
        (typeof geo?.lat === "number" && typeof geo?.lng === "number"
          ? { lat: geo.lat, lng: geo.lng }
          : null)

      const viewport = geo?.viewport || null

      if (!location) throw new Error("geocode result has no location")

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

      // 地図の寄せ
      if (viewport) {
        map.fitBounds(viewport)
      } else {
        map.panTo(location)
        map.setZoom(this.focusZoomValue)
      }

      // UIの住所表示も更新（まずはローカル結果で反映）
      this.addressTarget.textContent = displayAddress || query

      // サーバへ保存（StartPointsController#update）
      const lat = typeof location.lat === "function" ? location.lat() : location.lat
      const lng = typeof location.lng === "function" ? location.lng() : location.lng

      const json = await this.persistStartPoint({
        planId,
        lat,
        lng,
        address: displayAddress || query,
      })

      console.log("[start-point-editor] persist OK", json)

      // ✅ サーバ確定値で最終上書き（表示ズレ防止）
      const sp = json.start_point
      this.addressTarget.textContent = sp.address

      // ✅ 他が追従できるようにイベントも飛ばす（必要なら購読側でピン更新）
      document.dispatchEvent(new CustomEvent("plan:start-point-updated", { detail: sp }))

      // フォームは閉じる
      this.close()
    } catch (err) {
      console.error("[start-point-editor] update failed", err)
      alert("住所が見つからない、または保存に失敗しました。別のキーワードで試してください。")
    }
  }

  async persistStartPoint({ planId, lat, lng, address }) {
    const url = `/plans/${planId}/start_point`

    console.log("[start-point-editor] PATCH", { url, lat, lng, address })

    const json = await patch(url, { start_point: { lat, lng, address } })

    if (json.ok !== true) {
      const msg = (json?.errors || []).join(", ") || json?.message || "unknown error"
      throw new Error(`start_point update failed: ${msg}`)
    }

    return json
  }

  detectPlanId() {
    // 1) まず #map の data-plan-id（goal と揃える）
    const fromMap = document.getElementById("map")?.dataset?.planId
    if (fromMap) return fromMap

    // 2) URLから拾う
    const m = window.location.pathname.match(/\/plans\/(\d+)(\/edit)?/)
    return m ? m[1] : null
  }
}