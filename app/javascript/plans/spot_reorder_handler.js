// app/javascript/plans/spot_reorder_handler.js
//
// ================================================================
// Spot Reorder Handler（単一責務）
// 用途: SortableJS でスポットブロックの並び替えを可能にし、
//       並び替え完了時にサーバーへ position を保存する
//
// ✅ 安定化ポイント
// - navibar差し替え直前(navibar:will-update)に destroy してリーク/多重を防ぐ
// - navibar差し替え直後(navibar:updated)に init（差し替え後DOMにだけ付ける）
// - Sortable.get(container) で「既に付いているか」を判定して多重生成を防ぐ
// ================================================================

import Sortable from "sortablejs"
import { patchTurboStream } from "services/api_client"

let sortableInstance = null
let bound = false

// ✅ 1 RAF で DOM 更新完了を待ってから初期化（setTimeout は不要）
const requestInitSortable = () => {
  requestAnimationFrame(() => {
    initSortable()
  })
}

const getContainer = () => {
  // navibar内のものだけを拾う（将来の拡張にも強い）
  const el = document.querySelector(".navibar #plan-spots-sortable")
  return el || document.getElementById("plan-spots-sortable")
}

const getPlanId = () => {
  return document.getElementById("map")?.dataset?.planId || null
}

const getOrderedPlanSpotIds = (container) => {
  const items = container.querySelectorAll(".spot-block[data-plan-spot-id]")
  return Array.from(items).map((el) => parseInt(el.dataset.planSpotId, 10))
}

const getExistingSortable = (container) => {
  if (!container) return null
  try {
    return Sortable.get(container) || null
  } catch (_) {
    return null
  }
}

const destroySortable = () => {
  if (sortableInstance) {
    try {
      sortableInstance.destroy()
    } catch (_) {}
    sortableInstance = null
  }

  // 念のため、container 側に既に付いているものも破棄
  const container = getContainer()
  const existing = getExistingSortable(container)
  if (existing) {
    try {
      existing.destroy()
    } catch (_) {}
  }
}

const initSortable = () => {
  const container = getContainer()
  const planId = getPlanId()

  if (!container || !planId) return

  // 既に付いていればスキップ
  const existing = getExistingSortable(container)
  if (existing && existing.el === container) {
    sortableInstance = existing
    return
  }

  // 付け直す前に掃除
  destroySortable()

  sortableInstance = new Sortable(container, {
    animation: 150,
    draggable: ".spot-block",

    filter: "button, a, input, textarea, select, option, label, .detail-toggle",
    preventOnFilter: false,

    ghostClass: "spot-block--ghost",
    chosenClass: "spot-block--chosen",
    dragClass: "spot-block--drag",

    onEnd: async (evt) => {
      if (evt.oldIndex === evt.newIndex) return

      const orderedIds = getOrderedPlanSpotIds(container)

      try {
        await patchTurboStream(`/api/plans/${planId}/plan_spots/reorder`, {
          ordered_plan_spot_ids: orderedIds,
        })
        document.dispatchEvent(new CustomEvent("map:route-updated"))
      } catch (err) {
        console.error("並び替え保存エラー:", err)
        alert(err.message)
      }
    },
  })
}

export const bindSpotReorderHandler = () => {
  if (bound) return
  bound = true

  // 初回
  document.addEventListener("turbo:load", () => requestInitSortable())

  // ✅ navibar差し替えとペアで運用（これが最重要）
  document.addEventListener("navibar:will-update", destroySortable)
  document.addEventListener("navibar:updated", () => requestInitSortable())

  // キャッシュ時
  document.addEventListener("turbo:before-cache", destroySortable)
}