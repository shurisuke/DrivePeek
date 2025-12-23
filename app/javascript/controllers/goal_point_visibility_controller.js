// app/javascript/controllers/goal_point_visibility_controller.js
// ================================================================
// 単一責務: 帰宅地点ブロックの表示/非表示をトグルで切り替える
// 用途: goal-point の表示切替に連動して「最後のスポット」の右レール表示も調整する
// 補足: 帰宅地点が非表示のとき、最後のスポットの「出発」行と矢印を非表示にする
// ================================================================

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["blockArea", "switch"];
  static values = { planId: Number };

  connect() {
    this.apply();
  }

  toggle() {
    this.apply();
  }

  apply() {
    const goalVisible = this.hasSwitchTarget ? this.switchTarget.checked : false;

    // 帰宅ブロック本体の表示切替
    if (this.hasBlockAreaTarget) this.blockAreaTarget.hidden = !goalVisible;

    // 帰宅が非表示なら、最後のスポットの右レール「出発」行と矢印を消す
    this.updateLastSpotRail(goalVisible);
  }

  // ------------------------------------------------------------
  // 帰宅地点の表示状態に応じて、最後のスポットの右レールを調整
  // ------------------------------------------------------------
  updateLastSpotRail(goalVisible) {
    // ✅ このコントローラが置かれている planbar（または近い親）配下だけを対象にする
    const scope =
      this.element.closest(".planbar") ||
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

    // spot_block 側で付けた目印
    const departureRow = lastSpot.querySelector('[data-plan-time-role="spot-departure"]');
    const arrowArea = lastSpot.querySelector('[data-plan-time-role="spot-arrow"]');

    // goalVisible=true なら表示、false なら非表示
    if (departureRow) departureRow.hidden = !goalVisible;
    if (arrowArea) arrowArea.hidden = !goalVisible;
  }
}