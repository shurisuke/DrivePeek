// app/javascript/controllers/ui/popular_spots_controller.js
// ================================================================
// PopularSpotsController
// 用途: 人気スポット（盛り上がってるスポット）の表示制御
// - 炎ボタンクリック → 即座に人気スポットを地図に表示
// - 詳細ボタン → ジャンル選択モーダルを開く（複数選択可）
// ================================================================

import { Controller } from "@hotwired/stimulus"
import { getMapInstance, clearPopularSpotMarkers, setPopularSpotMarkers } from "map/state"
import { showInfoWindowWithFrame, closeInfoWindow, closeMobileInfoWindow } from "map/infowindow"
import { getMapPadding } from "map/visual_center"

export default class extends Controller {
  static targets = ["modal", "genreCheckbox"]

  // ============================================
  // 人気スポット表示（ジャンル指定なし）
  // ============================================

  show() {
    this.#fetchAndShowSpots([])
  }

  // ============================================
  // モーダル開閉
  // ============================================

  openModal() {
    // InfoWindowを閉じる
    closeInfoWindow()
    closeMobileInfoWindow()

    // モバイル時はナビバーボトムシートを閉じる
    this.#collapseBottomSheet()

    this.modalTarget.hidden = false
    document.body.style.overflow = "hidden"
  }

  #collapseBottomSheet() {
    const navibar = document.querySelector("[data-controller~='ui--bottom-sheet']")
    if (!navibar) return

    const controller = this.application.getControllerForElementAndIdentifier(navibar, "ui--bottom-sheet")
    if (controller && controller.isMobile) {
      controller.collapse()
    }
  }

  closeModal() {
    this.modalTarget.hidden = true
    document.body.style.overflow = ""
  }

  // ============================================
  // ジャンル選択（複数選択対応）
  // ============================================

  submit() {
    const selectedIds = this.genreCheckboxTargets
      .filter(cb => cb.checked)
      .map(cb => cb.value)

    this.closeModal()
    this.#fetchAndShowSpots(selectedIds)
  }

  toggleGroup(event) {
    event.stopPropagation()
    const group = event.currentTarget.closest(".selection-list__group")
    if (group) {
      group.classList.toggle("is-expanded")
    }
  }

  toggleParent(event) {
    if (event.target.type === "checkbox" || event.target.classList.contains("selection-list__toggle")) {
      return
    }
    const group = event.currentTarget.closest(".selection-list__group")
    if (group) {
      group.classList.toggle("is-expanded")
    }
  }

  selectParent(event) {
    event.stopPropagation()
    const parentCheckbox = event.currentTarget
    const group = parentCheckbox.closest("[data-parent-group]")
    if (!group) return

    const childCheckboxes = group.querySelectorAll(".selection-list__children input[type='checkbox']")
    childCheckboxes.forEach(cb => {
      cb.checked = parentCheckbox.checked
    })
  }

  updateParent(event) {
    const group = event.currentTarget.closest("[data-parent-group]")
    if (!group) return

    const parentCheckbox = group.querySelector("[data-parent-checkbox]")
    if (!parentCheckbox) return

    const childCheckboxes = group.querySelectorAll(".selection-list__children input[type='checkbox']")
    const checkedCount = Array.from(childCheckboxes).filter(cb => cb.checked).length

    if (checkedCount === 0) {
      parentCheckbox.checked = false
      parentCheckbox.indeterminate = false
    } else if (checkedCount === childCheckboxes.length) {
      parentCheckbox.checked = true
      parentCheckbox.indeterminate = false
    } else {
      parentCheckbox.checked = false
      parentCheckbox.indeterminate = true
    }
  }

  // ============================================
  // Private
  // ============================================

  async #fetchAndShowSpots(genreIds = []) {
    const map = getMapInstance()
    if (!map) return

    const bounds = map.getBounds()
    if (!bounds) return

    const adjustedBounds = this.#getVisibleBounds(map, bounds)

    const params = new URLSearchParams({
      north: adjustedBounds.north,
      south: adjustedBounds.south,
      east: adjustedBounds.east,
      west: adjustedBounds.west,
      limit: 20
    })

    genreIds.forEach(id => params.append("genre_ids[]", id))

    try {
      const response = await fetch(`/popular_spots?${params}`)
      if (!response.ok) throw new Error("API error")

      const data = await response.json()
      this.#displayMarkers(map, data.spots)
    } catch (error) {
      console.error("[PopularSpots] Fetch error:", error)
    }
  }

  #displayMarkers(map, spots) {
    clearPopularSpotMarkers()

    if (spots.length === 0) return

    const markers = spots.map(spot => this.#createMarker(map, spot))
    setPopularSpotMarkers(markers)

    // クリアボタンを表示
    const clearBtn = document.getElementById("popular-spots-clear")
    if (clearBtn) clearBtn.hidden = false
  }

  #getVisibleBounds(map, bounds) {
    const ne = bounds.getNorthEast()
    const sw = bounds.getSouthWest()
    const padding = getMapPadding()

    const latPerPixel = (ne.lat() - sw.lat()) / map.getDiv().offsetHeight
    const lngPerPixel = (ne.lng() - sw.lng()) / map.getDiv().offsetWidth

    return {
      north: ne.lat() - padding.top * latPerPixel,
      south: sw.lat() + padding.bottom * latPerPixel,
      east: ne.lng() - padding.right * lngPerPixel,
      west: sw.lng() + padding.left * lngPerPixel
    }
  }

  #createMarker(map, spot) {
    const emoji = spot.emoji || "✨"
    const marker = new google.maps.Marker({
      map,
      position: { lat: spot.lat, lng: spot.lng },
      title: spot.name,
      icon: {
        url: this.#createEmojiIconSvg(emoji),
        scaledSize: new google.maps.Size(44, 46),
        anchor: new google.maps.Point(22, 22),
      }
    })

    marker.addListener("click", () => {
      showInfoWindowWithFrame({
        anchor: marker,
        spotId: spot.id,
        name: spot.name,
        lat: spot.lat,
        lng: spot.lng,
        showButton: true,
        planId: document.getElementById("map")?.dataset.planId
      })
    })

    return marker
  }

  #createEmojiIconSvg(emoji) {
    const svg = `
      <svg xmlns="http://www.w3.org/2000/svg" width="44" height="46" viewBox="0 0 44 46">
        <circle cx="22" cy="24" r="18" fill="rgba(0,0,0,0.15)"/>
        <circle cx="22" cy="22" r="18" fill="#fff" stroke="#ccc" stroke-width="1"/>
        <text x="22" y="28" text-anchor="middle" font-size="18">${emoji}</text>
      </svg>
    `
    return "data:image/svg+xml," + encodeURIComponent(svg.trim())
  }
}
