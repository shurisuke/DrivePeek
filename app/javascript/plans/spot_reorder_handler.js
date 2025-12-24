// app/javascript/plans/spot_reorder_handler.js
//
// ================================================================
// Spot Reorder Handler（単一責務）
// 用途: SortableJS でスポットブロックの並び替えを可能にし、
//       並び替え完了時にサーバーへ position を保存する
//
// ✅ 安定化ポイント
// - planbar差し替え直前(planbar:will-update)に destroy してリーク/多重を防ぐ
// - planbar差し替え直後(planbar:updated)に init（差し替え後DOMにだけ付ける）
// - Sortable.get(container) で「既に付いているか」を判定して多重生成を防ぐ
// ================================================================

import Sortable from "sortablejs"

let sortableInstance = null
let bound = false

let initTimer = null
const requestInitSortable = (delay = 0) => {
  if (initTimer) return

  requestAnimationFrame(() => {
    initTimer = window.setTimeout(() => {
      initTimer = null
      initSortable()
    }, delay)
  })
}

const getContainer = () => {
  // planbar内のものだけを拾う（将来の拡張にも強い）
  const el = document.querySelector(".planbar #plan-spots-sortable")
  return el || document.getElementById("plan-spots-sortable")
}

const getPlanId = () => {
  return document.getElementById("map")?.dataset?.planId || null
}

const getOrderedPlanSpotIds = (container) => {
  const items = container.querySelectorAll(".spot-block[data-plan-spot-id]")
  return Array.from(items).map((el) => parseInt(el.dataset.planSpotId, 10))
}

const saveReorder = async (planId, orderedIds) => {
  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

  const res = await fetch(`/plans/${planId}/plan_spots/reorder`, {
    method: "PATCH",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": csrfToken,
      Accept: "application/json",
    },
    credentials: "same-origin",
    body: JSON.stringify({ ordered_plan_spot_ids: orderedIds }),
  })

  if (!res.ok) {
    const errorData = await res.json().catch(() => ({}))
    throw new Error(errorData.message || "並び替えの保存に失敗しました")
  }

  return res
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
  console.log("[spot_reorder_handler] destroySortable called")

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

  console.log("[spot_reorder_handler] initSortable called", { container, planId })

  if (!container || !planId) return

  // 既に付いていればスキップ
  const existing = getExistingSortable(container)
  if (existing && existing.el === container) {
    sortableInstance = existing
    console.log("[spot_reorder_handler] already attached -> skip")
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
        await saveReorder(planId, orderedIds)
        document.dispatchEvent(new CustomEvent("plan:spots-reordered"))
      } catch (err) {
        console.error("並び替え保存エラー:", err)
        alert(err.message)
        document.dispatchEvent(new CustomEvent("plan:spots-reordered"))
      }
      // ✅ ここでは再initしない（planbar_updater が差し替えて planbar:updated を出す）
    },
  })

  console.log("[spot_reorder_handler] initialized successfully", { planId })
}

export const bindSpotReorderHandler = () => {
  if (bound) return
  bound = true

  console.log("[spot_reorder_handler] bindSpotReorderHandler")

  // 初回
  document.addEventListener("turbo:load", () => requestInitSortable(0))

  // ✅ planbar差し替えとペアで運用（これが最重要）
  document.addEventListener("planbar:will-update", destroySortable)
  document.addEventListener("planbar:updated", () => requestInitSortable(0))

  // キャッシュ時
  document.addEventListener("turbo:before-cache", destroySortable)
}