import { Controller } from "@hotwired/stimulus"
import { patch } from "services/api_client"

// ================================================================
// TollUsedController
// 用途: 有料道路スイッチの変更をRailsへ保存し、時間・距離表示を更新
//   - plan_spot用: type="plan_spot"
//   - start_point用: type="start_point"
// ================================================================

export default class extends Controller {
  static values = {
    planId: Number,
    planSpotId: Number,
    type: String, // "start_point" | "plan_spot"
  }

  async toggle() {
    const tollUsed = this.element.checked

    try {
      const data = this.typeValue === "start_point"
        ? await this.#patchStartPoint(tollUsed)
        : await this.#patchPlanSpot(tollUsed)

      if (data.start_point) this.#updateStartPointDisplay(data.start_point)
      if (data.spots) data.spots.forEach((s) => this.#updateSpotDisplay(s))
      if (data.footer) this.#updateFooter(data.footer)

      document.dispatchEvent(new CustomEvent("map:route-updated"))
    } catch (err) {
      alert(err.message)
      this.element.checked = !tollUsed
    }
  }

  // --- API ---

  #patchStartPoint(tollUsed) {
    return patch(`/api/start_point`, {
      plan_id: this.planIdValue,
      start_point: { toll_used: tollUsed },
    })
  }

  #patchPlanSpot(tollUsed) {
    return patch(`/api/plan_spots/${this.planSpotIdValue}`, {
      toll_used: tollUsed,
    })
  }

  // --- DOM更新ヘルパー ---

  #formatTime(minutes) {
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    if (hours > 0 && mins > 0) return `${hours}<span class="time-unit">時間</span>${mins}<span class="time-unit">分</span>`
    if (hours > 0) return `${hours}<span class="time-unit">時間</span>`
    return `${mins}<span class="time-unit">分</span>`
  }

  #formatFooterTime(minutes) {
    const hours = Math.floor(minutes / 60)
    const mins = minutes % 60
    if (hours > 0) return `${hours}<span class="plan-summary__unit">時間</span>${mins}<span class="plan-summary__unit">分</span>`
    return `${mins}<span class="plan-summary__unit">分</span>`
  }

  #formatDistance(km) {
    if (km == null) return "—"
    const value = parseFloat(km)
    const formatted = value >= 10 ? Math.floor(value) : value.toFixed(1).replace(/\.0$/, "")
    return `${formatted}<span class="km-unit">km</span>`
  }

  #updateStartPointDisplay(startPointData) {
    const nextMoveEl = document.querySelector('[data-plan-time-role="start-next-move"]')
    if (!nextMoveEl) return
    const kmEl = nextMoveEl.querySelector(".km")
    const timeEl = nextMoveEl.querySelector(".time")
    if (kmEl) kmEl.innerHTML = this.#formatDistance(startPointData.move_distance)
    if (timeEl) timeEl.innerHTML = this.#formatTime(startPointData.move_time)
  }

  #updateSpotDisplay(spotData) {
    const spotBlock = document.querySelector(`[data-plan-spot-id="${spotData.id}"]`)
    if (!spotBlock) return

    const arrivalEl = spotBlock.querySelector(".block-time-panel .time-display:first-child .time-display__value")
    if (arrivalEl) arrivalEl.textContent = spotData.arrival_time || "--:--"

    const departureEl = spotBlock.querySelector('[data-plan-time-role="spot-departure"] .time-display__value')
    if (departureEl) departureEl.textContent = spotData.departure_time || "--:--"

    const nextMoveEl = spotBlock.querySelector('[data-plan-time-role="spot-next-move"]')
    if (nextMoveEl) {
      const kmEl = nextMoveEl.querySelector(".km")
      const timeEl = nextMoveEl.querySelector(".time")
      if (kmEl) kmEl.innerHTML = this.#formatDistance(spotData.move_distance)
      if (timeEl) timeEl.innerHTML = this.#formatTime(spotData.move_time)
    }
  }

  #updateFooter(footerData) {
    const set = (selector, value) => {
      const el = document.querySelector(`[data-plan-total="${selector}"]`)
      if (el) el.textContent = value ?? "—"
    }
    const setHtml = (selector, html) => {
      const el = document.querySelector(`[data-plan-total="${selector}"]`)
      if (el) el.innerHTML = html
    }

    set("spots-only-distance", footerData.spots_only_distance)
    setHtml("spots-only-time", this.#formatFooterTime(footerData.spots_only_time))
    set("with-goal-distance", footerData.with_goal_distance)
    setHtml("with-goal-time", this.#formatFooterTime(footerData.with_goal_time))
  }
}
