// ================================================================
// Spot Reorder Handler（単一責務）
// 用途: SortableJS でスポットブロックの並び替えを可能にし、
//       並び替え完了時にサーバーへ position を保存する
// ================================================================

import Sortable from "sortablejs"

let sortableInstance = null
let bound = false

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

const initSortable = () => {
  const container = document.getElementById("plan-spots-sortable")
  if (!container) {
    console.log("[spot_reorder_handler] initSortable: #plan-spots-sortable not found")
    return
  }

  // 二重初期化防止
  if (container.dataset.sortableInitialized === "true") {
    console.log("[spot_reorder_handler] initSortable: already initialized, skip")
    return
  }

  const mapElement = document.getElementById("map")
  const planId = mapElement?.dataset.planId
  if (!planId) {
    console.log("[spot_reorder_handler] initSortable: planId not found")
    return
  }

  // 既存インスタンスを破棄
  if (sortableInstance) {
    sortableInstance.destroy()
    sortableInstance = null
  }

  sortableInstance = new Sortable(container, {
    animation: 150,
    draggable: ".spot-block",

    // ✅ handle を指定しない = スポットブロック全体が掴める
    // ✅ 触ったら困るUIはドラッグ開始を無効化
    filter: "button, a, input, textarea, select, option, label, .detail-toggle",
    preventOnFilter: true,

    ghostClass: "spot-block--ghost",
    chosenClass: "spot-block--chosen",

    onEnd: async (evt) => {
      if (evt.oldIndex === evt.newIndex) return

      const orderedIds = getOrderedPlanSpotIds(container)

      try {
        await saveReorder(planId, orderedIds)
        document.dispatchEvent(new CustomEvent("plan:spots-reordered"))
      } catch (err) {
        console.error("並び替え保存エラー:", err)
        alert(err.message)
        // エラー時は planbar 再描画などで戻す想定
        document.dispatchEvent(new CustomEvent("plan:spots-reordered"))
      }
    },
  })

  container.dataset.sortableInitialized = "true"
  console.log("[spot_reorder_handler] initSortable: initialized successfully", { planId })
}

const destroySortable = () => {
  console.log("[spot_reorder_handler] destroySortable called")
  if (sortableInstance) {
    sortableInstance.destroy()
    sortableInstance = null
  }

  const container = document.getElementById("plan-spots-sortable")
  if (container) {
    delete container.dataset.sortableInitialized
  }
}

export const bindSpotReorderHandler = () => {
  if (bound) return
  bound = true

  console.log("[spot_reorder_handler] bindSpotReorderHandler")

  // turbo:load で初期化
  document.addEventListener("turbo:load", initSortable)

  // turbo:before-cache で破棄（キャッシュ時に古いインスタンスを残さない）
  document.addEventListener("turbo:before-cache", destroySortable)

  // planbar が Turbo Stream で更新された後に再初期化
  document.addEventListener("plan:spot-added", () => {
    destroySortable()
    setTimeout(initSortable, 100)
  })
  document.addEventListener("plan:spots-reordered", () => {
    destroySortable()
    setTimeout(initSortable, 100)
  })
  document.addEventListener("planbar:updated", () => {
    destroySortable()
    setTimeout(initSortable, 100)
  })
}