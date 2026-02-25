// app/javascript/controllers/time_rail_sync_controller.js
// ================================================================
// 時刻レールの高さをコンテンツブロックに同期
// ResizeObserverで高さ変化を検知し、対応する時刻レールブロックを更新
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "rail"]

  connect() {
    this.observer = new ResizeObserver(entries => {
      entries.forEach(entry => {
        this.syncHeight(entry.target)
      })
    })

    // 全コンテンツブロックを監視開始
    this.contentTargets.forEach(content => {
      this.observer.observe(content)
    })

    // 初期同期
    this.syncAllHeights()
  }

  disconnect() {
    if (this.observer) {
      this.observer.disconnect()
    }
  }

  syncAllHeights() {
    this.contentTargets.forEach(content => {
      this.syncHeight(content)
    })
  }

  syncHeight(contentBlock) {
    const blockType = contentBlock.dataset.timeRailSync
    if (!blockType) return

    const railBlock = this.railTargets.find(
      rail => rail.dataset.timeRailFor === blockType
    )

    if (railBlock) {
      const height = contentBlock.offsetHeight
      railBlock.style.height = `${height}px`
    }
  }
}
