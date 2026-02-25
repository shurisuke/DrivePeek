// app/javascript/controllers/infowindow/point_editor_controller.js
// ================================================================
// PointEditorController
// 用途: InfoWindow内で出発地点・帰宅地点の住所を編集
//   - 住所入力 → サーバーでジオコーディング → Turbo Stream でDOM更新
//   - DOM更新後に座標を読み取りマーカー更新
//   - editModeValue: "start_point" | "goal_point"
// ================================================================

import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  clearStartPointMarker,
  setStartPointMarker,
  clearEndPointMarker,
  setEndPointMarker,
} from "map/state"
import { patchTurboStream } from "services/navibar_api"
import { closeInfoWindow, showInfoWindowWithFrame } from "map/infowindow"
import { panToVisualCenter } from "map/visual_center"

export default class extends Controller {
  static targets = ["displayMode", "editMode", "input", "submitBtn", "submitText", "spinner"]
  static values = {
    editMode: String,  // "start_point" | "goal_point"
    planId: String,
  }

  connect() {
    this.isImeComposing = false
  }

  showEditMode() {
    this.displayModeTarget.hidden = true
    this.editModeTarget.hidden = false
    // 少し遅延させてフォーカス（DOM更新後）
    requestAnimationFrame(() => this.inputTarget.focus())
  }

  showDisplayMode() {
    this.editModeTarget.hidden = true
    this.displayModeTarget.hidden = false
    this.inputTarget.value = ""
  }

  onKeydown(event) {
    if (event.isComposing || this.isImeComposing || event.keyCode === 229) return
    if (event.key === "Enter") {
      event.preventDefault()
      this.search()
    } else if (event.key === "Escape") {
      this.showDisplayMode()
    }
  }

  compositionStart() {
    this.isImeComposing = true
  }

  compositionEnd() {
    this.isImeComposing = false
  }

  async search() {
    const query = this.inputTarget.value.trim()
    if (!query) return

    const map = getMapInstance()
    if (!map) {
      console.warn("[infowindow-point-editor] map is not ready")
      return
    }

    const planId = this.planIdValue || this.detectPlanId()
    if (!planId) {
      console.warn("[infowindow-point-editor] planId missing")
      return
    }

    this.showLoading()

    try {
      // サーバーに address_query を送信（サーバー側でジオコーディング）
      await this.persist({ planId, addressQuery: query })

      // InfoWindowを閉じる
      closeInfoWindow()

      // DOM更新後に座標を読み取ってマーカー更新
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          const selector = this.editModeValue === "start_point"
            ? ".start-point-block"
            : ".goal-point-block"
          const block = document.querySelector(selector)
          if (!block) return

          const lat = parseFloat(block.dataset.lat)
          const lng = parseFloat(block.dataset.lng)
          if (isNaN(lat) || isNaN(lng)) return

          // マーカー更新
          this.updateMarker(map, { lat, lng })

          // 地図を移動（ボトムシート考慮）
          map.setZoom(16)
          panToVisualCenter({ lat, lng })
        })
      })

    } catch (err) {
      console.error("[infowindow-point-editor] update failed", err)
      this.hideLoading()
    }
  }

  showLoading() {
    this.inputTarget.disabled = true
    this.submitBtnTarget.disabled = true
    this.submitTextTarget.hidden = true
    this.spinnerTarget.hidden = false
  }

  hideLoading() {
    this.inputTarget.disabled = false
    this.submitBtnTarget.disabled = false
    this.submitTextTarget.hidden = false
    this.spinnerTarget.hidden = true
  }

  updateMarker(map, location) {
    const iconUrl = "/icons/house-pin.png"
    const iconSize = new google.maps.Size(50, 55)
    const planId = this.planIdValue || this.detectPlanId()

    if (this.editModeValue === "start_point") {
      clearStartPointMarker()
      const marker = new google.maps.Marker({
        map,
        position: location,
        title: "出発地点",
        icon: { url: iconUrl, scaledSize: iconSize, anchor: new google.maps.Point(25, 40) },
      })
      marker.addListener("click", () => {
        showInfoWindowWithFrame({
          anchor: marker,
          name: "出発",
          editMode: "start_point",
          planId
        })
      })
      setStartPointMarker(marker)
    } else if (this.editModeValue === "goal_point") {
      clearEndPointMarker()
      const marker = new google.maps.Marker({
        map,
        position: location,
        title: "帰宅地点",
        icon: { url: iconUrl, scaledSize: iconSize, anchor: new google.maps.Point(25, 40) },
      })
      marker.addListener("click", () => {
        showInfoWindowWithFrame({
          anchor: marker,
          name: "帰宅",
          editMode: "goal_point",
          planId
        })
      })
      setEndPointMarker(marker)
    }
  }

  async persist({ planId, addressQuery }) {
    const isStartPoint = this.editModeValue === "start_point"
    const url = isStartPoint ? `/plans/${planId}/start_point` : `/plans/${planId}/goal_point`
    const key = isStartPoint ? "start_point" : "goal_point"

    await patchTurboStream(url, { [key]: { address_query: addressQuery } })
  }

  detectPlanId() {
    const fromMap = document.getElementById("map")?.dataset?.planId
    if (fromMap) return fromMap

    const m = window.location.pathname.match(/\/plans\/(\d+)(\/edit)?/)
    return m ? m[1] : null
  }
}
