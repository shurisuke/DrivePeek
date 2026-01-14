// app/javascript/controllers/share_modal_controller.js
// ================================================================
// 共有モーダル: ボタンクリックでX/LINE選択モーダルを表示
// モーダルは動的に生成してbodyに追加（HTML構造の問題を回避）
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    text: String,
    planId: Number
  }

  open() {
    // プラン作成画面の場合、スポットの有無をDOMからチェック
    if (this.hasPlanIdValue) {
      const spotBlocks = document.querySelectorAll(".spot-block")
      if (spotBlocks.length === 0) {
        alert("スポットを追加してから共有してください")
        return
      }
      // 共有テキストを動的に生成
      this.textValue = this.generateShareText()
    }

    // 既存のモーダルがあれば削除
    this.removeExistingModal()

    // モーダルを作成
    this.modal = this.createModal()
    document.body.appendChild(this.modal)

    // bodyにクラス追加
    document.body.classList.add("share-modal-open")
  }

  generateShareText() {
    const circleNumbers = ["⓪", "①", "②", "③", "④", "⑤", "⑥", "⑦", "⑧", "⑨", "⑩", "⑪", "⑫", "⑬", "⑭", "⑮", "⑯", "⑰", "⑱", "⑲", "⑳"]
    const spotBlocks = document.querySelectorAll(".spot-block")
    const lines = []

    spotBlocks.forEach((block, index) => {
      const nameEl = block.querySelector(".spot-name")
      if (nameEl) {
        const num = circleNumbers[index + 1] || (index + 1).toString()
        lines.push(`${num} ${nameEl.textContent.trim()}`)
      }
    })

    return lines.join("\n") + "\n\n"
  }

  close() {
    this.removeExistingModal()
    document.body.classList.remove("share-modal-open")
  }

  removeExistingModal() {
    const existing = document.querySelector(".share-modal")
    if (existing) existing.remove()
  }

  createModal() {
    const modal = document.createElement("div")
    modal.className = "share-modal"
    modal.innerHTML = `
      <div class="share-modal__overlay"></div>
      <div class="share-modal__sheet">
        <div class="share-modal__content">
          <div class="share-modal__title">プランをシェア</div>
          <div class="share-modal__buttons">
            <button type="button" class="share-modal__btn share-modal__btn--x">
              <i class="bi bi-twitter-x" aria-hidden="true"></i>
              <span>X</span>
            </button>
            <button type="button" class="share-modal__btn share-modal__btn--line">
              <i class="bi bi-line" aria-hidden="true"></i>
              <span>LINE</span>
            </button>
          </div>
          <button type="button" class="share-modal__cancel">キャンセル</button>
        </div>
      </div>
    `

    // イベントリスナー
    modal.querySelector(".share-modal__overlay").addEventListener("click", () => this.close())
    modal.querySelector(".share-modal__cancel").addEventListener("click", () => this.close())
    modal.querySelector(".share-modal__btn--x").addEventListener("click", () => this.shareX())
    modal.querySelector(".share-modal__btn--line").addEventListener("click", () => this.shareLine())

    return modal
  }

  shareX() {
    const encodedText = encodeURIComponent(this.textValue)
    const encodedUrl = encodeURIComponent(this.urlValue)
    window.open(
      `https://twitter.com/intent/tweet?text=${encodedText}&url=${encodedUrl}`,
      "_blank",
      "noopener,noreferrer"
    )
    this.close()
  }

  shareLine() {
    const encodedUrl = encodeURIComponent(this.urlValue)
    window.open(
      `https://social-plugins.line.me/lineit/share?url=${encodedUrl}`,
      "_blank",
      "noopener,noreferrer"
    )
    this.close()
  }
}
