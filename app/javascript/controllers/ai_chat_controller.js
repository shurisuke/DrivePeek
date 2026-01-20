import { Controller } from "@hotwired/stimulus"

// AI提案チャットのUI制御
export default class extends Controller {
  static targets = ["messages", "input", "sendBtn", "typing"]

  connect() {
    this.isSending = false
    this.scrollToBottom()

    // Turboイベントをリッスン
    this.element.addEventListener("turbo:submit-start", this.handleSubmitStart.bind(this))
    this.element.addEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-start", this.handleSubmitStart.bind(this))
    this.element.removeEventListener("turbo:submit-end", this.handleSubmitEnd.bind(this))
  }

  // テキストエリアの自動リサイズ
  autoResize() {
    const textarea = this.inputTarget
    textarea.style.height = "auto"
    const newHeight = Math.min(textarea.scrollHeight, 100)
    textarea.style.height = `${newHeight}px`

    // 送信中でなければ、空の場合は送信ボタンを無効化
    if (!this.isSending) {
      this.sendBtnTarget.disabled = !textarea.value.trim()
    }
  }

  // Enter で送信、Shift+Enter で改行
  // ※ IME変換中（isComposing）は送信しない
  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
      event.preventDefault()
      if (this.inputTarget.value.trim()) {
        this.element.querySelector("form").requestSubmit()
      }
    }
  }

  // フォーム送信開始（Turboイベント）
  handleSubmitStart(event) {
    // ユーザーメッセージを即座に表示
    const message = this.inputTarget.value.trim()
    if (message) {
      this.appendUserMessage(message)
    }

    this.setSending(true)
    this.showTyping()
  }

  // ユーザーメッセージを即座に追加
  appendUserMessage(content) {
    const divider = document.createElement("div")
    divider.className = "ai-chat__divider"

    const msgDiv = document.createElement("div")
    msgDiv.className = "ai-chat__msg ai-chat__msg--user"

    const contentDiv = document.createElement("div")
    contentDiv.className = "ai-chat__content"

    const bubbleDiv = document.createElement("div")
    bubbleDiv.className = "ai-chat__bubble"
    bubbleDiv.innerHTML = content.replace(/\n/g, "<br>")
    contentDiv.appendChild(bubbleDiv)

    const metaDiv = document.createElement("div")
    metaDiv.className = "ai-chat__meta"
    const timeSpan = document.createElement("span")
    timeSpan.className = "ai-chat__time"
    timeSpan.textContent = this.getCurrentTime()
    metaDiv.appendChild(timeSpan)

    contentDiv.appendChild(metaDiv)
    msgDiv.appendChild(contentDiv)

    if (this.hasTypingTarget) {
      this.messagesTarget.insertBefore(divider, this.typingTarget)
      this.messagesTarget.insertBefore(msgDiv, this.typingTarget)
    }

    this.scrollToBottom()
  }

  // フォーム送信完了（Turboイベント）
  handleSubmitEnd(event) {
    this.setSending(false)
    this.hideTyping()
    // 少し遅延してスクロール（Turbo Streamの反映を待つ）
    setTimeout(() => this.scrollToBottom(), 100)
  }

  // 送信中状態の切り替え
  setSending(isSending) {
    this.isSending = isSending

    if (this.hasSendBtnTarget) {
      this.sendBtnTarget.disabled = isSending
      if (isSending) {
        this.sendBtnTarget.classList.add("ai-chat__send-btn--sending")
        this.sendBtnTarget.innerHTML = '<span class="ai-chat__send-spinner"></span>'
      } else {
        this.sendBtnTarget.classList.remove("ai-chat__send-btn--sending")
        this.sendBtnTarget.innerHTML = '<i class="bi bi-arrow-up"></i>'
      }
    }

    if (this.hasInputTarget) {
      this.inputTarget.disabled = isSending
    }
  }

  // 現在時刻を取得
  getCurrentTime() {
    const now = new Date()
    return `${now.getHours()}:${String(now.getMinutes()).padStart(2, "0")}`
  }

  // メッセージをコピー
  copyMessage(event) {
    const btn = event.currentTarget
    const bubble = btn.closest(".ai-chat__msg").querySelector(".ai-chat__bubble")
    const text = bubble.textContent || bubble.innerText

    navigator.clipboard.writeText(text).then(() => {
      // アイコンを一時的に変更
      const icon = btn.querySelector("i")
      icon.classList.remove("bi-clipboard")
      icon.classList.add("bi-check")
      btn.classList.add("ai-chat__action-btn--copied")

      setTimeout(() => {
        icon.classList.remove("bi-check")
        icon.classList.add("bi-clipboard")
        btn.classList.remove("ai-chat__action-btn--copied")
      }, 2000)
    })
  }

  // 再生成（将来実装）
  regenerate(event) {
    console.log("再生成機能は開発中です")
  }

  // タイピングインジケーター表示
  showTyping() {
    if (this.hasTypingTarget) {
      this.typingTarget.style.display = "flex"
      this.scrollToBottom()
    }
  }

  // タイピングインジケーター非表示
  hideTyping() {
    if (this.hasTypingTarget) {
      this.typingTarget.style.display = "none"
    }
  }

  // 最下部にスクロール
  scrollToBottom() {
    if (this.hasMessagesTarget) {
      this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
    }
  }
}
