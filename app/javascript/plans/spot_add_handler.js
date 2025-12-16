// ================================================================
// spot:add イベントを受けて Rails API へ POST する
// 用途: InfoWindow の「プランに追加」ボタン押下時の処理
// ================================================================

const getCsrfToken = () => {
  const meta = document.querySelector('meta[name="csrf-token"]')
  return meta?.getAttribute("content") || ""
}

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

const postSpotToRails = async (planId, detail) => {
  const url = `/plans/${planId}/plan_spots`
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

  const res = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "X-CSRF-Token": getCsrfToken(),
      Accept: "application/json",
    },
    credentials: "same-origin",
    body: JSON.stringify(body),
  })

  if (!res.ok) {
    const err = await res.json().catch(() => ({}))
    throw new Error(err.message || "保存に失敗しました")
  }

  return res.json()
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
    const result = await postSpotToRails(planId, detail)
    document.dispatchEvent(new CustomEvent("plan:spot-added", { detail: result }))
  } catch (err) {
    alert(err.message)
  }
}

export const bindSpotAddHandler = () => {
  // 二重バインド防止
  document.removeEventListener("spot:add", handleSpotAdd)
  document.addEventListener("spot:add", handleSpotAdd)
}