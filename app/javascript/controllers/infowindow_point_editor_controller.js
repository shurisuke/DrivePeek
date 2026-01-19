// app/javascript/controllers/infowindow_point_editor_controller.js
//
// InfoWindow内で出発・帰宅地点を編集するコントローラ

import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  clearStartPointMarker,
  setStartPointMarker,
  clearEndPointMarker,
  setEndPointMarker,
} from "map/state"
import { geocodeAddress, normalizeDisplayAddress } from "map/geocoder"
import { patchTurboStream } from "services/api_client"
import { closeInfoWindow } from "map/infowindow"

export default class extends Controller {
  static targets = ["displayMode", "editMode", "input"]
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

    try {
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

      const lat = typeof location.lat === "function" ? location.lat() : location.lat
      const lng = typeof location.lng === "function" ? location.lng() : location.lng

      // マーカー更新
      this.updateMarker(map, { lat, lng })

      // 地図を移動
      if (viewport) {
        map.fitBounds(viewport)
      } else {
        map.panTo(location)
        map.setZoom(16)
      }

      // サーバーに保存
      await this.persist({ planId, lat, lng, address: displayAddress || query })

      // InfoWindowを閉じる
      closeInfoWindow()

    } catch (err) {
      console.error("[infowindow-point-editor] update failed", err)
      alert("住所が見つからない、または保存に失敗しました。")
    }
  }

  updateMarker(map, location) {
    const iconUrl = "/icons/house-pin.png"
    const iconSize = new google.maps.Size(50, 55)

    if (this.editModeValue === "start_point") {
      clearStartPointMarker()
      const marker = new google.maps.Marker({
        map,
        position: location,
        title: "出発地点",
        icon: { url: iconUrl, scaledSize: iconSize },
      })
      setStartPointMarker(marker)
    } else if (this.editModeValue === "goal_point") {
      clearEndPointMarker()
      const marker = new google.maps.Marker({
        map,
        position: location,
        title: "帰宅地点",
        icon: { url: iconUrl, scaledSize: iconSize },
      })
      setEndPointMarker(marker)
    }
  }

  async persist({ planId, lat, lng, address }) {
    const isStartPoint = this.editModeValue === "start_point"
    const url = isStartPoint
      ? `/api/plans/${planId}/start_point`
      : `/api/plans/${planId}/goal_point`
    const key = isStartPoint ? "start_point" : "goal_point"

    await patchTurboStream(url, { [key]: { lat, lng, address } })
  }

  detectPlanId() {
    const fromMap = document.getElementById("map")?.dataset?.planId
    if (fromMap) return fromMap

    const m = window.location.pathname.match(/\/plans\/(\d+)(\/edit)?/)
    return m ? m[1] : null
  }
}
