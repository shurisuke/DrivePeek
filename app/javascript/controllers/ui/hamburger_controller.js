import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button", "menu"]

  toggle() {
    // ハンバーガーボタンのクラスを切り替え
    this.buttonTarget.classList.toggle("js-menu-open")

    // メニュー本体のクラスを切り替え
    this.menuTarget.classList.toggle("js-open")

    // メニュー内のリンクのクラスを切り替え
    const links = this.menuTarget.querySelectorAll("li a")
    links.forEach((link) => {
      link.classList.toggle("js-menu-open")
    })
  }
}
