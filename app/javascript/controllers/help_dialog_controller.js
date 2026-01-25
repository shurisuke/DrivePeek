// app/javascript/controllers/help_dialog_controller.js
// ================================================================
// Help Dialog Controller
// 用途: iOS風ヘルプダイアログを汎用的に表示
//
// 使い方:
//   <button data-controller="help-dialog"
//           data-help-dialog-title-value="タイトル"
//           data-help-dialog-body-value="<p>本文HTML</p>"
//           data-action="click->help-dialog#show">?</button>
// ================================================================

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    title: String,
    body: String,
    buttonText: { type: String, default: "OK" }
  }

  show(event) {
    event.preventDefault()
    event.stopPropagation()
    this._showDialog()
  }

  _showDialog() {
    // 既存のダイアログがあれば削除
    const existingDialog = document.getElementById("help-dialog")
    if (existingDialog) existingDialog.remove()

    const dialog = document.createElement("dialog")
    dialog.id = "help-dialog"
    dialog.className = "help-dialog"
    dialog.innerHTML = `
      <div class="help-dialog__content">
        <h3 class="help-dialog__title">${this.titleValue}</h3>
        <div class="help-dialog__body">${this.bodyValue}</div>
      </div>
      <button type="button" class="help-dialog__btn">${this.buttonTextValue}</button>
    `
    document.body.appendChild(dialog)

    const closeBtn = dialog.querySelector(".help-dialog__btn")
    closeBtn.addEventListener("click", () => {
      dialog.close()
      dialog.remove()
    })

    dialog.addEventListener("click", (e) => {
      if (e.target === dialog) {
        dialog.close()
        dialog.remove()
      }
    })

    dialog.showModal()
  }
}
