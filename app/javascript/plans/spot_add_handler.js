// ================================================================
// spot:add イベントを受けて Rails API へ POST する
// 用途: InfoWindow の「プランに追加」ボタン押下時の処理
// ================================================================

const getCsrfToken = () => {
  const meta = document.querySelector('meta[name="csrf-token"]')
  return meta?.getAttribute("content") || ""
}

const getPlanId = () => {
  // #map に限定して誤爆を防ぐ
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
  // 除外後3件、足りなければ元の先頭3件
  return filtered.length > 0
    ? filtered.slice(0, 3)
    : (types || []).slice(0, 3)
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
    console.error("❌ プランIDが見つかりません")
    alert("プランIDが見つかりません")
    return
  }

  if (!detail?.place_id) {
    console.error("❌ スポット情報が不足しています", detail)
    alert("スポット情報が不足しています")
    return
  }

  try {
    const result = await postSpotToRails(planId, detail)
    console.log("✅ スポット追加成功:", result)

    // 検索マーカーをクリアするイベントを発火
    document.dispatchEvent(new CustomEvent("plan:spot-added", { detail: result }))

    // TODO: UIへの反映（別Issue）
  } catch (err) {
    console.error("❌ スポット追加失敗:", err)
    alert(err.message)
  }
}

export const bindSpotAddHandler = () => {
  // 二重バインド防止: 一度外してから付け直す（冪等化）
  document.removeEventListener("spot:add", handleSpotAdd)
  document.addEventListener("spot:add", handleSpotAdd)
}
