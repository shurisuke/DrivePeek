import { Controller } from "@hotwired/stimulus"
import { clearAiSuggestionMarkers } from "map/state"
import { closeInfoWindow } from "map/infowindow"

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

  // 会話クリア時にAI提案マーカーもクリア
  clearConversation() {
    clearAiSuggestionMarkers()
    closeInfoWindow()
    // AI提案ピンクリアボタンを非表示に
    const pinClearBtn = document.getElementById("ai-suggestion-clear")
    if (pinClearBtn) pinClearBtn.hidden = true
    // 会話クリアボタンを無効化
    this.setClearButtonEnabled(false)
  }

  // 会話クリアボタンの有効/無効を切り替え
  setClearButtonEnabled(enabled) {
    const btn = document.getElementById("ai-chat-clear-btn")
    if (btn) btn.disabled = !enabled
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
        this.element.querySelector("#ai-chat-form").requestSubmit()
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

  // ユーザーメッセージを即座に追加（テンプレートを使用）
  appendUserMessage(content) {
    const template = document.getElementById("user-message-template")
    if (!template) return

    const clone = template.content.cloneNode(true)
    clone.querySelector(".ai-chat__bubble").innerHTML = content.replace(/\n/g, "<br>")
    clone.querySelector(".ai-chat__time").textContent = this.getCurrentTime()

    if (this.hasTypingTarget) {
      this.messagesTarget.insertBefore(clone, this.typingTarget)
    }
    this.scrollToBottom()
  }

  // フォーム送信完了（Turboイベント）
  handleSubmitEnd(event) {
    this.setSending(false)
    this.hideTyping()
    // 会話が追加されたのでクリアボタンを有効化
    this.setClearButtonEnabled(true)
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

  // タイピングインジケーター表示
  showTyping() {
    if (this.hasTypingTarget) {
      this.typingTarget.style.display = "flex"
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
