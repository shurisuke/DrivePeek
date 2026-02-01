import { Controller } from "@hotwired/stimulus"
import { clearSuggestionMarkers } from "map/state"
import { closeInfoWindow } from "map/infowindow"

// ================================================================
// SuggestionController
// 用途: 提案チャットのUI制御
// - メッセージ送受信（Turboイベント連携）
// - テキストエリア自動リサイズ / Enter送信
// - タイピングインジケーター表示
// - 会話クリア時のマーカー削除
// ================================================================

export default class extends Controller {
  static targets = ["messages", "typing"]

  connect() {
    this.isSending = false
    this.scrollToBottom()

    // バインド関数を保持（クリーンアップ用）
    this.boundAutoResize = this.autoResize.bind(this)
    this.boundHandleKeydown = this.handleKeydown.bind(this)
    this.boundHandleSubmitStart = this.handleSubmitStart.bind(this)
    this.boundHandleSubmitEnd = this.handleSubmitEnd.bind(this)

    // 入力欄がスコープ外（ナビバーフッター）にある場合に対応
    this.externalInput = document.querySelector(".suggestion__composer [data-suggestion-target='input']")
    this.externalSendBtn = document.querySelector(".suggestion__composer [data-suggestion-target='sendBtn']")

    // 外部入力欄のイベントを設定
    if (this.externalInput) {
      this.externalInput.addEventListener("input", this.boundAutoResize)
      this.externalInput.addEventListener("keydown", this.boundHandleKeydown)
    }

    // 会話クリアボタンのイベント設定（外部にあるため手動で設定）
    this.clearBtn = document.getElementById("suggestion-clear-btn")
    if (this.clearBtn) {
      this.boundClearConversation = this.clearConversation.bind(this)
      this.clearBtn.addEventListener("turbo:submit-end", this.boundClearConversation)
    }

    this.updateSendButtonState()

    // Turboイベントをリッスン（ナビバー全体から）
    document.addEventListener("turbo:submit-start", this.boundHandleSubmitStart)
    document.addEventListener("turbo:submit-end", this.boundHandleSubmitEnd)
  }

  disconnect() {
    // イベントリスナーのクリーンアップ
    document.removeEventListener("turbo:submit-start", this.boundHandleSubmitStart)
    document.removeEventListener("turbo:submit-end", this.boundHandleSubmitEnd)

    if (this.externalInput) {
      this.externalInput.removeEventListener("input", this.boundAutoResize)
      this.externalInput.removeEventListener("keydown", this.boundHandleKeydown)
    }

    if (this.clearBtn && this.boundClearConversation) {
      this.clearBtn.removeEventListener("turbo:submit-end", this.boundClearConversation)
    }
  }

  // 会話クリア時に提案マーカーもクリア
  clearConversation() {
    clearSuggestionMarkers()
    closeInfoWindow()
    // 提案ピンクリアボタンを非表示に
    const pinClearBtn = document.getElementById("suggestion-pin-clear")
    if (pinClearBtn) pinClearBtn.hidden = true
    // 会話クリアボタンを無効化
    this.setClearButtonEnabled(false)
  }

  // 会話クリアボタンの有効/無効を切り替え
  setClearButtonEnabled(enabled) {
    const btn = document.getElementById("suggestion-clear-btn")
    if (btn) btn.disabled = !enabled
  }

  // テキストエリアの自動リサイズ
  autoResize() {
    const textarea = this.getInput()
    if (!textarea) return

    textarea.style.height = "auto"
    const newHeight = Math.min(textarea.scrollHeight, 100)
    textarea.style.height = `${newHeight}px`

    this.updateSendButtonState()
  }

  // 入力要素を取得（ナビバーフッター内）
  getInput() {
    return this.externalInput
  }

  // 送信ボタンを取得（ナビバーフッター内）
  getSendBtn() {
    return this.externalSendBtn
  }

  // 送信ボタンの状態を更新（テキストがあれば有効）
  updateSendButtonState() {
    const sendBtn = this.getSendBtn()
    if (this.isSending || !sendBtn) return

    const input = this.getInput()
    const hasText = input && input.value.trim().length > 0
    sendBtn.disabled = !hasText
  }

  // Enter で送信、Shift+Enter で改行
  // ※ IME変換中（isComposing）は送信しない
  handleKeydown(event) {
    if (event.key === "Enter" && !event.shiftKey && !event.isComposing) {
      event.preventDefault()
      const input = this.getInput()
      const hasText = input && input.value.trim().length > 0
      if (hasText) {
        // フォームはナビバー側にあるので、外部フォームを取得
        const form = document.querySelector(".suggestion__composer .suggestion__form")
        if (form) form.requestSubmit()
      }
    }
  }

  // フォーム送信開始（Turboイベント）
  handleSubmitStart(event) {
    // ユーザーメッセージを即座に表示
    const input = this.getInput()
    const message = input ? input.value.trim() : ""
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
    clone.querySelector(".suggestion__bubble").innerHTML = content.replace(/\n/g, "<br>")
    clone.querySelector(".suggestion__time").textContent = this.getCurrentTime()

    if (this.hasTypingTarget) {
      this.messagesTarget.insertBefore(clone, this.typingTarget)
    }
    // DOM更新後にスクロール
    requestAnimationFrame(() => {
      this.scrollToBottom()
    })
  }

  // フォーム送信完了（Turboイベント）
  handleSubmitEnd(event) {
    this.setSending(false)
    this.hideTyping()
    this.clearTextInput()
    // 会話が追加されたのでクリアボタンを有効化
    this.setClearButtonEnabled(true)
  }

  // テキスト入力をクリア
  clearTextInput() {
    const input = this.getInput()
    if (input) {
      input.value = ""
      input.style.height = "auto"
    }
    this.updateSendButtonState()
  }

  // 送信中状態の切り替え
  setSending(isSending) {
    this.isSending = isSending

    const sendBtn = this.getSendBtn()
    if (sendBtn) {
      sendBtn.disabled = isSending
      if (isSending) {
        sendBtn.classList.add("suggestion__send-btn--sending")
        sendBtn.innerHTML = '<span class="suggestion__send-spinner"></span>'
      } else {
        sendBtn.classList.remove("suggestion__send-btn--sending")
        sendBtn.innerHTML = '<i class="bi bi-arrow-up"></i>'
      }
    }

    const input = this.getInput()
    if (input) {
      input.disabled = isSending
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
    const bubble = btn.closest(".suggestion__msg").querySelector(".suggestion__bubble")
    const text = bubble.textContent || bubble.innerText

    navigator.clipboard.writeText(text).then(() => {
      const icon = btn.querySelector("i")
      icon.classList.remove("bi-clipboard")
      icon.classList.add("bi-check")
      btn.classList.add("suggestion__action-btn--copied")

      setTimeout(() => {
        icon.classList.remove("bi-check")
        icon.classList.add("bi-clipboard")
        btn.classList.remove("suggestion__action-btn--copied")
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
    if (!this.hasMessagesTarget) return

    // メッセージ一覧自体がスクロール可能な場合（モバイル）
    const el = this.messagesTarget
    if (el.scrollHeight > el.clientHeight) {
      el.scrollTop = el.scrollHeight
    }

    // 親のスクロールコンテナ（デスクトップ: .navibar__content-scroll）
    const scrollParent = el.closest(".navibar__content-scroll")
    if (scrollParent) {
      scrollParent.scrollTop = scrollParent.scrollHeight
    }
  }
}
