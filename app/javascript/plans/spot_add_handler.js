// ================================================================
// spot:add / spot:delete イベントを受けて Rails API へ送信
// 用途: InfoWindow のボタン押下時の処理
// ================================================================

import { postTurboStream } from "services/api_client"

const getPlanId = () => {
  const el = document.getElementById("map")
  return el?.dataset.planId || null
}

const getCsrfToken = () => document.querySelector('meta[name="csrf-token"]')?.content

// Google types から不要なものを除外して最大3件を返す
const filterTopTypes = (types) => {
  const excludeList = [
    "establishment",
    "point_of_interest",
    "premise",
    "plus_code",
    "political",
    "geocode",
  ]
  const filtered = (types || []).filter((t) => !excludeList.includes(t))
  return filtered.length > 0 ? filtered.slice(0, 3) : (types || []).slice(0, 3)
}

const handleSpotAdd = async (event) => {
  const detail = event.detail
  const planId = getPlanId()

  if (!planId) {
    alert("プランIDが見つかりません")
    return
  }

  if (!detail?.place_id) {
    alert("スポット情報が不足しています")
    return
  }

  // ボタンにローディング状態を追加
  const btn = detail.buttonId ? document.getElementById(detail.buttonId) : null
  if (btn) {
    btn.classList.add("dp-infowindow__btn--loading")
    btn.disabled = true
  }

  try {
    const url = `/api/plans/${planId}/plan_spots`
    const body = {
      spot: {
        place_id: detail.place_id,
        name: detail.name,
        address: detail.address,
        lat: detail.lat,
        lng: detail.lng,
        top_types: filterTopTypes(detail.types),
      },
    }

    await postTurboStream(url, body)

    // スポット追加後はプランタブをアクティブにし、地図ルートを更新
    document.dispatchEvent(new CustomEvent("navibar:activate-tab", { detail: { tab: "plan" } }))
    document.dispatchEvent(new CustomEvent("map:route-updated"))

    // 新しいスポットまでスクロール & ボタンを削除モードに切り替え
    requestAnimationFrame(() => {
      const spots = document.querySelectorAll(".spot-block")
      const lastSpot = spots[spots.length - 1]
      if (lastSpot) {
        lastSpot.scrollIntoView({ behavior: "smooth", block: "center" })

        // ボタンを削除モードに切り替え
        if (btn) {
          btn.dataset.planSpotId = lastSpot.dataset.planSpotId
          btn.textContent = "プランから削除"
          btn.classList.remove("dp-infowindow__btn--loading")
          btn.classList.add("dp-infowindow__btn--delete")
          btn.disabled = false
        }
      }
    })
  } catch (err) {
    alert(err.message)
    if (btn) {
      btn.classList.remove("dp-infowindow__btn--loading")
      btn.disabled = false
    }
  }
}

// 削除ハンドラ
const handleSpotDelete = async (event) => {
  const { buttonId, planSpotId } = event.detail
  const planId = getPlanId()

  if (!planId || !planSpotId) return

  const btn = buttonId ? document.getElementById(buttonId) : null
  if (btn) {
    btn.classList.add("dp-infowindow__btn--loading")
    btn.disabled = true
  }

  try {
    const res = await fetch(`/plans/${planId}/plan_spots/${planSpotId}`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": getCsrfToken(), "Accept": "text/vnd.turbo-stream.html" },
    })

    if (res.ok) {
      Turbo.renderStreamMessage(await res.text())
      document.dispatchEvent(new CustomEvent("plan:spot-deleted", { detail: { planId, planSpotId } }))
      document.dispatchEvent(new CustomEvent("navibar:updated"))
    }
  } catch (err) {
    alert("削除に失敗しました")
  } finally {
    if (btn) {
      btn.classList.remove("dp-infowindow__btn--loading")
      btn.disabled = false
    }
  }
}

export const bindSpotAddHandler = () => {
  document.removeEventListener("spot:add", handleSpotAdd)
  document.addEventListener("spot:add", handleSpotAdd)
  document.removeEventListener("spot:delete", handleSpotDelete)
  document.addEventListener("spot:delete", handleSpotDelete)
}