// app/javascript/controllers/goal_point_editor_controller.js
//
// ================================================================
// GoalPoint Editor（単一責務）
// 用途: 帰宅地点ブロックの「変更」UIを開閉し、Enterで住所を更新する
//       - start_point と同じ体験の goal_point 版
//
// 追加:
// - 変更フォームを「ボタンの右側」に position: fixed で表示し、
//   planbar__content の overflow クリップから脱出させる
// - デバッグ用の console.log を追加
// ================================================================

import { Controller } from "@hotwired/stimulus"
import { geocodeAddress } from "map/geocoder"

export default class extends Controller {
  static targets = ["address", "toggle", "editArea", "input"]

  connect() {
    console.log("[goal-point-editor] connect", {
      hasAddress: this.hasAddressTarget,
      hasToggle: this.hasToggleTarget,
      hasEditArea: this.hasEditAreaTarget,
      hasInput: this.hasInputTarget,
    })

    this.composing = false
    this._onReposition = this.reposition.bind(this)
  }

  disconnect() {
    console.log("[goal-point-editor] disconnect")
    window.removeEventListener("resize", this._onReposition)
    window.removeEventListener("scroll", this._onReposition, true)
  }

  toggle() {
    const willOpen = this.editAreaTarget.hidden
    console.log("[goal-point-editor] toggle", { willOpen })

    if (willOpen) {
      this.editAreaTarget.hidden = false
      this.toggleTarget.setAttribute("aria-expanded", "true")

      // ✅ planbarのoverflowの影響を受けないように fixed で出す
      this.editAreaTarget.style.position = "fixed"
      this.editAreaTarget.style.zIndex = "9999"

      // 見た目（必要なら調整）
      this.editAreaTarget.style.width = "320px"
      this.editAreaTarget.style.maxWidth = "calc(100vw - 24px)"
      this.editAreaTarget.style.margin = "0"

      this.reposition()

      window.addEventListener("resize", this._onReposition)
      // どこがスクロールしても追従できるように capture=true
      window.addEventListener("scroll", this._onReposition, true)

      this.inputTarget.focus()
      return
    }

    this.close()
  }

  close() {
    console.log("[goal-point-editor] close")

    this.editAreaTarget.hidden = true
    this.toggleTarget.setAttribute("aria-expanded", "false")

    window.removeEventListener("resize", this._onReposition)
    window.removeEventListener("scroll", this._onReposition, true)

    // スタイルを戻す（次回開いた時に再計算する）
    this.editAreaTarget.style.position = ""
    this.editAreaTarget.style.top = ""
    this.editAreaTarget.style.left = ""
    this.editAreaTarget.style.zIndex = ""
    this.editAreaTarget.style.width = ""
    this.editAreaTarget.style.maxWidth = ""
  }

  reposition() {
    const rect = this.toggleTarget.getBoundingClientRect()

    const gapX = 10
    const offsetY = 50 // ← ここだけで調整

    const left = rect.right + gapX
    const top = rect.top + offsetY

    const safeLeft = Math.min(left, window.innerWidth - 20)
    const safeTop = Math.max(top, 12)

    this.editAreaTarget.style.left = `${safeLeft}px`
    this.editAreaTarget.style.top = `${safeTop}px`

    console.log("[goal-point-editor] reposition", { safeLeft, safeTop })
  }

  compositionStart() {
    this.composing = true
  }

  compositionEnd() {
    this.composing = false
  }

  async search(e) {
    if (this.composing) return
    if (e.key !== "Enter") return

    e.preventDefault()

    const input = this.inputTarget.value.trim()
    if (!input) return

    const planId = document.getElementById("map")?.dataset?.planId
    if (!planId) {
      alert("プランIDが見つかりません")
      console.warn("[goal-point-editor] planId missing (#map.dataset.planId)")
      return
    }

    console.log("[goal-point-editor] search begin", { planId, input })

    try {
      const geo = await geocodeAddress(input)
      console.log("[goal-point-editor] geocode result", geo)

      const payload = {
        goal_point: {
          address: geo.address || input,
          lat: geo.lat,
          lng: geo.lng,
        },
      }

      const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

      const res = await fetch(`/plans/${planId}/goal_point`, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": csrfToken,
          Accept: "application/json",
        },
        credentials: "same-origin",
        body: JSON.stringify(payload),
      })

      if (!res.ok) {
        const err = await res.json().catch(() => ({}))
        throw new Error(err.message || "帰宅地点の更新に失敗しました")
      }

      const json = await res.json().catch(() => ({}))
      console.log("[goal-point-editor] update OK", json)

      this.addressTarget.textContent = json.address || payload.goal_point.address

      // マーカー差し替え等のきっかけ（init_map.js 側で購読）
      document.dispatchEvent(new CustomEvent("plan:goal-point-updated", { detail: json }))

      this.close()
    } catch (err) {
      console.error("[goal-point-editor] update failed", err)
      alert(err.message)
    }
  }
}