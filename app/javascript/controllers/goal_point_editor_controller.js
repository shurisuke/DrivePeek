// app/javascript/controllers/goal_point_editor_controller.js
//
// ================================================================
// GoalPoint Editor（単一責務）
// 用途: 帰宅地点ブロックの「変更」UIを開閉し、Enterで住所を更新する
//       - start_point と同じ体験の goal_point 版
//
// 追加:
// - 変更フォームを「ボタンの右側」に position: fixed で表示し、
//   navibar__content の overflow クリップから脱出させる
// ================================================================

import { Controller } from "@hotwired/stimulus"
import { geocodeAddress, normalizeDisplayAddress } from "map/geocoder"
import {
  getMapInstance,
  clearSearchHitMarkers,
  clearEndPointMarker,
  setEndPointMarker,
} from "map/state"
import { patchTurboStream } from "services/api_client"

export default class extends Controller {
  static targets = ["address", "toggle", "editArea", "input"]
  static values = {
    iconUrl: { type: String, default: "/icons/house-pin.png" },
    iconWidth: { type: Number, default: 50 },
    iconHeight: { type: Number, default: 55 },
    focusZoom: { type: Number, default: 16 },
  }

  connect() {
    this.composing = false
    this._isOpen = false

    // ✅ 孤立したモーダル要素をクリーンアップ
    this.cleanupOrphanedModals()
  }

  cleanupOrphanedModals() {
    // body直下にある孤立したモーダル要素を削除
    const orphanedModals = document.body.querySelectorAll(":scope > .goal-point-edit.point-edit-modal")
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
      console.error("[goal-point-editor] editArea target not found")
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
    this.composing = true
  }

  compositionEnd() {
    this.composing = false
  }

  async search(e) {
    if (this.composing) return
    if (e.key !== "Enter") return
    e.preventDefault()
    this.doSearch()
  }

  async doSearch() {
    const map = getMapInstance()
    if (!map) {
      console.warn("[goal-point-editor] map is not ready")
      return
    }

    const input = this.inputTarget.value.trim()
    if (!input) return

    const planId = document.getElementById("map")?.dataset?.planId
    if (!planId) {
      alert("プランIDが見つかりません")
      console.warn("[goal-point-editor] planId missing (#map.dataset.planId)")
      return
    }

    try {
      // ✅ 検索ヒットピンを全て消去
      clearSearchHitMarkers()

      const geo = await geocodeAddress(input)

      // ✅ geocodeAddress の戻り値から location と address を正しく取得
      const formattedAddress = geo?.formattedAddress || input
      const displayAddress = normalizeDisplayAddress
        ? normalizeDisplayAddress(formattedAddress)
        : formattedAddress

      const location = geo?.location
      const viewport = geo?.viewport || null

      if (!location) {
        throw new Error("Geocode結果にlocationがありません")
      }

      // ✅ google.maps.LatLng の lat()/lng() メソッドを呼ぶ
      const lat = typeof location.lat === "function" ? location.lat() : location.lat
      const lng = typeof location.lng === "function" ? location.lng() : location.lng

      // ✅ 帰宅ピンを消して差し直す
      clearEndPointMarker()

      const marker = new google.maps.Marker({
        map,
        position: location,
        title: "帰宅地点",
        icon: {
          url: this.iconUrlValue,
          scaledSize: new google.maps.Size(this.iconWidthValue, this.iconHeightValue),
        },
      })

      setEndPointMarker(marker)

      // ✅ 地図を寄せる
      if (viewport) {
        map.fitBounds(viewport)
      } else {
        map.panTo(location)
        map.setZoom(this.focusZoomValue)
      }

      // ✅ goalPointVisible を true にセット（ピンを表示状態に）
      const mapEl = document.getElementById("map")
      if (mapEl) {
        mapEl.dataset.goalPointVisible = "true"
      }

      // ✅ body クラスも同期（navibar:updated ハンドラーが body から読み取るため）
      document.body.classList.add("goal-point-visible")

      // ✅ トグルスイッチも ON にする（UI の一貫性のため）
      const toggleSwitch = document.querySelector("[data-goal-point-visibility-target='switch']")
      if (toggleSwitch) {
        toggleSwitch.checked = true
      }

      // UIの住所表示を更新（ローカル結果で即反映、turbo_stream で上書きされる）
      this.addressTarget.textContent = displayAddress

      // ✅ サーバへ保存（turbo_stream で navibar が自動更新される）
      await patchTurboStream(`/api/plans/${planId}/goal_point`, {
        goal_point: {
          address: displayAddress,
          lat,
          lng,
        },
      })

      // ✅ turbo_stream で navibar が自動更新される（navibar:updated イベントで地図も同期）

      this.close()
    } catch (err) {
      console.error("[goal-point-editor] update failed", err)
      alert(err.message)
    }
  }
}