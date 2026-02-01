// app/javascript/controllers/start_point_editor_controller.js
//
// ================================================================
// StartPoint Editor（単一責務）
// 用途:
// - 「変更」ボタンでフォームを開閉
// - 変更フォームを「ボタンの右側」に position: fixed で表示し、navibar の overflow から脱出
// - Enterで住所をGeocodingして、出発地点ピンを差し替え
// - 検索ヒットピンがあれば全消去
// - 地図をズーム/フォーカス（viewportがあればfitBounds）
// - サーバへ更新をPATCH（StartPointsController#update）
// ================================================================

import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  clearSearchHitMarkers,
  clearStartPointMarker,
  setStartPointMarker,
} from "map/state"
import { geocodeAddress, normalizeDisplayAddress } from "map/geocoder"
import { patchTurboStream } from "services/api_client"

export default class extends Controller {
  static targets = ["toggle", "editArea", "input", "address"]
  static values = {
    iconUrl: { type: String, default: "/icons/house-pin.png" },
    iconWidth: { type: Number, default: 50 },
    iconHeight: { type: Number, default: 55 },
    focusZoom: { type: Number, default: 16 },
  }

  connect() {
    this.isImeComposing = false
    this._isOpen = false

    // ✅ 孤立したモーダル要素をクリーンアップ
    this.cleanupOrphanedModals()
  }

  cleanupOrphanedModals() {
    // body直下にある孤立したモーダル要素を削除
    const orphanedModals = document.body.querySelectorAll(":scope > .start-point-edit.point-edit-modal")
    orphanedModals.forEach(el => el.remove())

    // 孤立したバックドロップも削除
    const orphanedBackdrops = document.body.querySelectorAll(":scope > .point-edit-modal-backdrop")
    orphanedBackdrops.forEach(el => {
      el.remove()
    })

    // bodyのクラスもクリーンアップ
    document.body.classList.remove("point-edit-modal-open")
  }

  disconnect() {
    if (this._isOpen) {
      this.close()
    }
  }

  toggle() {
    if (!this._isOpen) {
      this.openModal()
    } else {
      this.close()
    }
  }

  openModal() {
    // ✅ 必要なターゲットが存在するか確認
    if (!this.hasEditAreaTarget) {
      console.error("[start-point-editor] editArea target not found")
      return
    }

    this._isOpen = true

    // ✅ bodyにクラスを追加（背景を適用するため）
    document.body.classList.add("point-edit-modal-open")

    // ✅ モーダルオーバーレイを作成（bodyに配置、地図部分用）
    this.backdrop = document.createElement("div")
    this.backdrop.className = "point-edit-modal-backdrop"
    this.backdrop.addEventListener("click", () => this.close())
    document.body.appendChild(this.backdrop)

    // ✅ editAreaを表示
    this.editAreaTarget.removeAttribute("hidden")
    this.editAreaTarget.classList.add("point-edit-modal")

    this.toggleTarget.setAttribute("aria-expanded", "true")

    // ✅ ボタンにイベントリスナーを追加
    this._cancelBtn = this.editAreaTarget.querySelector(".point-edit__cancel-btn")
    this._searchBtn = this.editAreaTarget.querySelector(".point-edit__search-btn")

    this._onCancelClick = (e) => {
      e.preventDefault()
      e.stopPropagation()
      this.close()
    }
    this._onSearchClick = (e) => {
      e.preventDefault()
      e.stopPropagation()
      this.doSearch()
    }

    if (this._cancelBtn) this._cancelBtn.addEventListener("click", this._onCancelClick)
    if (this._searchBtn) this._searchBtn.addEventListener("click", this._onSearchClick)

    // ✅ フォーカス
    requestAnimationFrame(() => {
      this.inputTarget.focus()
    })
  }

  close() {
    if (!this._isOpen) return
    this._isOpen = false

    // ✅ ボタンのイベントリスナーを削除
    if (this._cancelBtn && this._onCancelClick) {
      this._cancelBtn.removeEventListener("click", this._onCancelClick)
    }
    if (this._searchBtn && this._onSearchClick) {
      this._searchBtn.removeEventListener("click", this._onSearchClick)
    }
    this._cancelBtn = null
    this._searchBtn = null
    this._onCancelClick = null
    this._onSearchClick = null

    // ✅ editAreaを非表示に
    if (this.hasEditAreaTarget) {
      this.editAreaTarget.classList.remove("point-edit-modal")
      this.editAreaTarget.setAttribute("hidden", "")
    }

    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", "false")
    }

    // ✅ バックドロップを削除
    if (this.backdrop) {
      this.backdrop.remove()
      this.backdrop = null
    }

    // ✅ bodyからクラスを削除
    document.body.classList.remove("point-edit-modal-open")
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
    this.doSearch()
  }

  async doSearch() {
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

    try {
      // 検索ヒット地点ピンがある場合、全て消去
      clearSearchHitMarkers()

      // 住所を Geocoding（geocoder の返り値差を吸収）
      const geo = await geocodeAddress(query)

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

      // UIの住所表示も更新（ローカル結果で即時反映、turbo_stream で上書きされる）
      this.addressTarget.textContent = displayAddress || query

      // サーバへ保存（StartPointsController#update）
      const lat = typeof location.lat === "function" ? location.lat() : location.lat
      const lng = typeof location.lng === "function" ? location.lng() : location.lng

      await this.persistStartPoint({
        planId,
        lat,
        lng,
        address: displayAddress || query,
      })

      // ✅ turbo_stream で navibar が自動更新される（navibar:updated イベントで地図も同期）

      // フォームは閉じる
      this.close()
    } catch (err) {
      console.error("[start-point-editor] update failed", err)
      alert("住所が見つからない、または保存に失敗しました。別のキーワードで試してください。")
    }
  }

  async persistStartPoint({ planId, lat, lng, address }) {
    const url = `/api/start_point`
    // turbo_stream で navibar が自動更新される（エラー時は例外が投げられる）
    await patchTurboStream(url, { plan_id: planId, start_point: { lat, lng, address } })
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