import { Controller } from "@hotwired/stimulus"

// AI提案チャットのUI制御
export default class extends Controller {
  static targets = ["messages", "input", "sendBtn", "typing"]

  connect() {
    this.isSending = false
    this.scrollToBottom()
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
  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey) {
      event.preventDefault()
      if (this.inputTarget.value.trim()) {
        this.element.querySelector("form").requestSubmit()
      }
    }
  }

  // フォーム送信（Phase 1: ダミー動作）
  send(event) {
    event.preventDefault()

    const message = this.inputTarget.value.trim()
    if (!message) return

    // ユーザーメッセージを追加
    this.appendMessage(message, "user")

    // 入力欄をクリア
    this.inputTarget.value = ""
    this.autoResize()

    // 送信中状態にする
    this.setSending(true)

    // タイピングインジケーター表示
    this.showTyping()

    // 2秒後にダミー応答（Phase 2で実際のAPI呼び出しに置き換え）
    setTimeout(() => {
      this.hideTyping()
      this.setSending(false)
      this.appendMessage("申し訳ありません。AI機能は現在開発中です。もうしばらくお待ちください。", "assistant")
    }, 2000)
  }

  // 送信中状態の切り替え
  setSending(isSending) {
    this.isSending = isSending
    this.sendBtnTarget.disabled = isSending
    this.inputTarget.disabled = isSending

    if (isSending) {
      this.sendBtnTarget.classList.add("ai-chat__send-btn--sending")
      this.sendBtnTarget.innerHTML = '<span class="ai-chat__send-spinner"></span>'
    } else {
      this.sendBtnTarget.classList.remove("ai-chat__send-btn--sending")
      this.sendBtnTarget.innerHTML = '<i class="bi bi-arrow-up"></i>'
    }
  }

  // メッセージを追加
  appendMessage(content, role) {
    // 区切り線を追加
    const divider = document.createElement("div")
    divider.className = "ai-chat__divider"

    const msgDiv = document.createElement("div")
    msgDiv.className = `ai-chat__msg ai-chat__msg--${role}`

    if (role === "assistant") {
      const iconDiv = document.createElement("div")
      iconDiv.className = "ai-chat__icon"
      iconDiv.innerHTML = '<i class="bi bi-stars"></i>'
      msgDiv.appendChild(iconDiv)
    }

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

    if (role === "assistant") {
      const copyBtn = document.createElement("button")
      copyBtn.type = "button"
      copyBtn.className = "ai-chat__action-btn"
      copyBtn.title = "コピー"
      copyBtn.innerHTML = '<i class="bi bi-clipboard"></i>'
      copyBtn.addEventListener("click", (e) => this.copyMessage(e))
      metaDiv.appendChild(copyBtn)

      const regenBtn = document.createElement("button")
      regenBtn.type = "button"
      regenBtn.className = "ai-chat__action-btn"
      regenBtn.title = "再生成"
      regenBtn.innerHTML = '<i class="bi bi-arrow-clockwise"></i>'
      regenBtn.addEventListener("click", (e) => this.regenerate(e))
      metaDiv.appendChild(regenBtn)
    }

    contentDiv.appendChild(metaDiv)
    msgDiv.appendChild(contentDiv)

    // タイピングインジケーターの前に挿入
    if (this.hasTypingTarget) {
      this.messagesTarget.insertBefore(divider, this.typingTarget)
      this.messagesTarget.insertBefore(msgDiv, this.typingTarget)
    } else {
      this.messagesTarget.appendChild(divider)
      this.messagesTarget.appendChild(msgDiv)
    }

    this.scrollToBottom()
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

  // 再生成（Phase 2で実装）
  regenerate(event) {
    // TODO: Phase 2で実装
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
    this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
  }
}
