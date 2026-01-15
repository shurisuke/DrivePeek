// ================================================================
// spot:add イベントを受けて Rails API へ POST する
// 用途: InfoWindow の「プランに追加」ボタン押下時の処理
// ================================================================

import { postTurboStream } from "services/api_client"

const getPlanId = () => {
  const el = document.getElementById("map")
  return el?.dataset.planId || null
}

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

  try {
    const url = `/api/plans/${planId}/plan_spots`
    const body = {
      spot: {
        place_id: detail.place_id,
        name: detail.name,
        address: detail.address,
        lat: detail.lat,
        lng: detail.lng,
        photo_reference: detail.photo_reference,
        top_types: filterTopTypes(detail.types),
      },
    }

    await postTurboStream(url, body)

    // スポット追加後はプランタブをアクティブにし、地図ルートを更新
    document.dispatchEvent(new CustomEvent("navibar:activate-tab", { detail: { tab: "plan" } }))
    document.dispatchEvent(new CustomEvent("map:route-updated"))

    // 新しいスポットまでスクロール
    requestAnimationFrame(() => {
      const spots = document.querySelectorAll(".spot-block")
      const lastSpot = spots[spots.length - 1]
      if (lastSpot) lastSpot.scrollIntoView({ behavior: "smooth", block: "center" })
    })
  } catch (err) {
    alert(err.message)
  }
}

export const bindSpotAddHandler = () => {
  // 二重バインド防止
  document.removeEventListener("spot:add", handleSpotAdd)
  document.addEventListener("spot:add", handleSpotAdd)
}