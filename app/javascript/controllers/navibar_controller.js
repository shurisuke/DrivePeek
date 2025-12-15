import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "content"]

  switch(event) {
    const selected = event.currentTarget.dataset.tab

    // ボタンの active 状態を切り替え
    this.buttonTargets.forEach((btn) => btn.classList.remove("active"))
    event.currentTarget.classList.add("active")

    // コンテンツの表示切り替え
    this.contentTargets.forEach((content) => {
      content.classList.remove("active")
      if (content.classList.contains(`tab-${selected}`)) {
        content.classList.add("active")
      }
    })
  }
}
