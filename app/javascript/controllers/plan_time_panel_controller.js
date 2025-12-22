// app/javascript/controllers/plan_time_panel_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.injectAll()

    // Turbo/SortableなどでDOMが差し替わっても再注入できるように監視
    this.observer = new MutationObserver(() => this.injectAll())
    this.observer.observe(this.element, { childList: true, subtree: true })
  }

  disconnect() {
    if (this.observer) this.observer.disconnect()
  }

  injectAll() {
    this.injectForSelector(".start-point-block", this.startTemplate())
    this.injectForSelector(".spot-block", this.spotTemplate())
    this.injectForSelector(".goal-point-block", this.goalTemplate())
  }

  injectForSelector(selector, templateHtml) {
    const blocks = this.element.querySelectorAll(selector)
    blocks.forEach((block) => {
      // 二重差し込み防止
      if (block.querySelector(":scope > .plan-time-panel")) return

      // 位置決めのため relative を付ける（既に付いててもOK）
      block.classList.add("has-plan-time-panel")

      block.insertAdjacentHTML("beforeend", templateHtml)
    })
  }

  startTemplate() {
    return `
      <div class="plan-time-panel" aria-hidden="true">
        <div class="plan-time-panel__inner">
          <div class="plan-time-panel__row">
            <div class="plan-time-panel__label">出発</div>
            <div class="plan-time-panel__value">—:—</div>
          </div>
        </div>
      </div>
    `
  }

  spotTemplate() {
    return `
      <div class="plan-time-panel" aria-hidden="true">
        <div class="plan-time-panel__inner">
          <div class="plan-time-panel__row">
            <div class="plan-time-panel__label">到着</div>
            <div class="plan-time-panel__value">—:—</div>
          </div>

          <div class="plan-time-panel__row">
            <div class="plan-time-panel__label">滞在</div>
            <div class="plan-time-panel__value">—</div>
          </div>

          <div class="plan-time-panel__row">
            <div class="plan-time-panel__label">出発</div>
            <div class="plan-time-panel__value">—:—</div>
          </div>

          <!-- ✅ 境目を分かりやすくする矢印（土台） -->
          <div class="plan-time-panel__arrow" aria-hidden="true">
            <i class="bi bi-caret-down-fill"></i>
          </div>
        </div>
      </div>
    `
  }

  goalTemplate() {
    return `
      <div class="plan-time-panel" aria-hidden="true">
        <div class="plan-time-panel__inner">
          <div class="plan-time-panel__row">
            <div class="plan-time-panel__label">到着</div>
            <div class="plan-time-panel__value">—:—</div>
          </div>
        </div>
      </div>
    `
  }
}