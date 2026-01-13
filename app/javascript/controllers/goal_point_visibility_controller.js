// app/javascript/controllers/goal_point_visibility_controller.js
// ================================================================
// 単一責務: 帰宅地点ブロックの表示/非表示をトグルで切り替える
// 用途: goal-point の表示切替に連動して「最後のスポット」の右レール表示も調整する
// ================================================================

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["blockArea", "switch"];
  static values = { planId: Number };

  connect() {
    // ✅ Turbo更新後の再接続時は、復元された body クラスの状態をスイッチに反映
    // （サーバーから返る HTML の switch は checked 属性がないため）
    const restoredVisible = document.body.classList.contains("goal-point-visible")
    if (restoredVisible && this.hasSwitchTarget && !this.switchTarget.checked) {
      this.switchTarget.checked = true
    }

    this.apply();

    // ✅ navibar更新時にも最後スポットのクラスを再計算
    this.handlePlanbarUpdated = () => this.apply();
    document.addEventListener("navibar:updated", this.handlePlanbarUpdated);
  }

  disconnect() {
    document.removeEventListener("navibar:updated", this.handlePlanbarUpdated);
  }

  toggle() {
    this.apply();
  }

  apply() {
    const goalVisible = this.hasSwitchTarget ? this.switchTarget.checked : false;

    // 帰宅ブロック本体の表示切替
    if (this.hasBlockAreaTarget) this.blockAreaTarget.hidden = !goalVisible;

    // ✅ body に goal-point-visible クラスを追加/削除（CSS判定用）
    if (goalVisible) {
      document.body.classList.add("goal-point-visible");
    } else {
      document.body.classList.remove("goal-point-visible");
    }

    // 帰宅が非表示なら、最後のスポットの右レール「出発」行と矢印を消す
    this.updateLastSpotRail(goalVisible);

    // ✅ 帰宅地点の表示状態変更を通知（polyline描画と連動）
    document.dispatchEvent(
      new CustomEvent("plan:goal-point-visibility-changed", {
        detail: { goalVisible },
      })
    );
  }

  // ------------------------------------------------------------
  // 帰宅地点の表示状態に応じて、最後のスポットの右レールを調整
  // ------------------------------------------------------------
  updateLastSpotRail(goalVisible) {
    // ✅ このコントローラが置かれている navibar（または近い親）配下だけを対象にする
    const scope =
      this.element.closest(".navibar") ||
      this.element.closest(".plan-form") ||
      document;

    const spotBlocks = Array.from(scope.querySelectorAll(".spot-block[data-position]"));
    if (spotBlocks.length === 0) return;

    // position 最大＝最後のスポット
    const lastSpot = spotBlocks.reduce((acc, el) => {
      const pos = Number(el.dataset.position || 0);
      const accPos = Number(acc?.dataset?.position || 0);
      return pos >= accPos ? el : acc;
    }, spotBlocks[0]);

    // ✅ 全スポットから spot-block--last を外し、最後のスポットにだけ付与
    // これにより CSS で帰宅地点表示状態に応じたトグル出し分けが効く
    spotBlocks.forEach((el) => el.classList.remove("spot-block--last"));
    lastSpot.classList.add("spot-block--last");

    // spot_block 側で付けた目印
    const nextMoveRow = lastSpot.querySelector('[data-plan-time-role="spot-next-move"]');

    // goalVisible=false でも表示するが、数値を「--」に置き換える
    if (nextMoveRow) {
      nextMoveRow.hidden = false; // 常に表示

      const kmEl = nextMoveRow.querySelector('.km');
      const timeEl = nextMoveRow.querySelector('.time');

      if (!goalVisible) {
        // 元の値を保存（初回のみ）
        if (kmEl && !kmEl.dataset.originalValue) {
          kmEl.dataset.originalValue = kmEl.innerHTML;
        }
        if (timeEl && !timeEl.dataset.originalValue) {
          timeEl.dataset.originalValue = timeEl.innerHTML;
        }
        // 「--」に置き換え
        if (kmEl) kmEl.innerHTML = '--<span class="km-unit">km</span>';
        if (timeEl) timeEl.innerHTML = '--<span class="time-unit">分</span>';
      } else {
        // 元の値を復元
        if (kmEl && kmEl.dataset.originalValue) {
          kmEl.innerHTML = kmEl.dataset.originalValue;
        }
        if (timeEl && timeEl.dataset.originalValue) {
          timeEl.innerHTML = timeEl.dataset.originalValue;
        }
      }
    }
  }
}