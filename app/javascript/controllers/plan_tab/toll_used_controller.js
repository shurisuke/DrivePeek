import { Controller } from "@hotwired/stimulus"
import { patchTurboStream } from "services/navibar_api"

// ================================================================
// TollUsedController
// 用途: 有料道路スイッチの変更をRailsへ保存
//   - plan_spot用: type="plan_spot"
//   - start_point用: type="start_point"
// ================================================================

export default class extends Controller {
  static values = {
    planId: Number,
    planSpotId: Number,
    type: String, // "start_point" | "plan_spot"
  }

  async toggle() {
    const tollUsed = this.element.checked
    const block = this.#getParentBlock()

    try {
      // ✅ JSでトグルアニメーションを強制実行（API並行）
      this.#animateToggle(tollUsed)

      // ローディング状態を表示（距離・時間のスケルトン）
      block?.classList.add("is-loading")

      if (this.typeValue === "start_point") {
        await patchTurboStream(`/api/start_point`, {
          plan_id: this.planIdValue,
          start_point: { toll_used: tollUsed },
        })
      } else {
        await patchTurboStream(`/api/plan_spots/${this.planSpotIdValue}`, {
          toll_used: tollUsed,
        })
      }

      document.dispatchEvent(new CustomEvent("map:route-updated"))
    } catch (err) {
      block?.classList.remove("is-loading")
      alert(err.message)
      // エラー時はアニメーションを戻す
      this.#animateToggle(!tollUsed)
      this.element.checked = !tollUsed
    }
  }

  // トグルのアニメーションをJSで強制実行
  #animateToggle(isOn) {
    const toggle = this.element

    // まず逆の状態のクラスを設定（トランジションの開始点）
    if (isOn) {
      toggle.classList.add("is-off")
      toggle.classList.remove("is-on")
    } else {
      toggle.classList.add("is-on")
      toggle.classList.remove("is-off")
    }

    // 次フレームで目標状態に切り替え（トランジション発火）
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        if (isOn) {
          toggle.classList.remove("is-off")
          toggle.classList.add("is-on")
        } else {
          toggle.classList.remove("is-on")
          toggle.classList.add("is-off")
        }
      })
    })
  }

  // 親ブロック要素を取得
  #getParentBlock() {
    return this.element.closest(".spot-block, .start-point-block")
  }
}
