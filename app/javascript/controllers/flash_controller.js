import { Controller } from "@hotwired/stimulus"

// フラッシュメッセージの自動消去
export default class extends Controller {
  connect() {
    setTimeout(() => {
      this.element.remove()
    }, 3000)
  }
}
