// ================================================================
// Planbar Updater（単一責務）
// 用途: プラン作成/編集画面の左ナビ（planbar）を“そこだけ”再描画する
//
// 仕組み:
// - spot_add_handler がスポット追加成功後に "plan:spot-added" を dispatch
// - このファイルはそのイベントを購読し、/plans/:plan_id/planbar を取得
// - 返ってきた turbo-stream を Turbo.renderStreamMessage で適用し、
//   turbo_frame_tag "planbar" の中身だけを差し替える
//
// 注意:
// - Turbo 遷移で同じ画面が再訪されるとイベント登録が重複しやすいので、
//   removeEventListener → addEventListener で冪等化（=二重バインド防止）している
// ================================================================

import { Turbo } from "@hotwired/turbo-rails"

const refreshPlanbar = async () => {
  const map = document.getElementById("map")
  const planId = map?.dataset.planId
  if (!planId) return

  const res = await fetch(`/plans/${planId}/planbar`, {
    headers: { Accept: "text/vnd.turbo-stream.html" },
    credentials: "same-origin",
  })

  if (!res.ok) return

  const streamHtml = await res.text()
  Turbo.renderStreamMessage(streamHtml)
}

export const bindPlanbarRefresh = () => {
  // 二重バインド防止（turbo遷移で何度も呼ばれても1回分にする）
  document.removeEventListener("plan:spot-added", refreshPlanbar)
  document.addEventListener("plan:spot-added", refreshPlanbar)
}