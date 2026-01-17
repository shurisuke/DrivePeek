// ================================================================
// spot:add / spot:delete イベントを受けて Rails API へ送信
// 用途: InfoWindow のボタン押下時の処理
// ================================================================

import { postTurboStream } from "services/api_client"
import { closeInfoWindow } from "map/infowindow"
import { getPlanSpotMarkers, clearPlanSpotMarkers, clearRoutePolylines } from "map/state"

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

  // ✅ マーカー再描画完了を待ってからInfoWindowを開く
  // navibar:updated → plan_map_sync.js でマーカー再描画 → 次のフレームでInfoWindow表示
  const targetLat = detail.lat
  const targetLng = detail.lng

  const onMarkersReady = () => {
    document.removeEventListener("navibar:updated", onMarkersReady)
    // plan_map_sync.js のマーカー再描画を待つ（2フレーム後）
    requestAnimationFrame(() => {
      requestAnimationFrame(() => {
        const spots = document.querySelectorAll(".spot-block")
        const lastSpot = spots[spots.length - 1]
        if (lastSpot) {
          lastSpot.scrollIntoView({ behavior: "smooth", block: "center" })
        }

        // 追加したスポットの位置に一致するマーカーを探す
        const markers = getPlanSpotMarkers()
        const targetMarker = markers.find((m) => {
          const pos = m.getPosition()
          if (!pos) return false
          return Math.abs(pos.lat() - targetLat) < 0.0001 &&
                 Math.abs(pos.lng() - targetLng) < 0.0001
        })

        if (targetMarker) {
          google.maps.event.trigger(targetMarker, "click")
        }
      })
    })
  }
  document.addEventListener("navibar:updated", onMarkersReady)

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
  } catch (err) {
    document.removeEventListener("navibar:updated", onMarkersReady)
    alert(err.message)
    if (btn) {
      btn.classList.remove("dp-infowindow__btn--loading")
      btn.disabled = false
    }
  }
}

// 削除ハンドラ（楽観的更新 + Turbo Stream）
const handleSpotDelete = async (event) => {
  const { buttonId, planSpotId } = event.detail
  const planId = getPlanId()

  if (!planId || !planSpotId) return

  // ✅ 即座にUIを更新（楽観的更新）
  closeInfoWindow()

  // スポットブロックをDOMから削除
  const spotBlock = document.querySelector(`.spot-block[data-plan-spot-id="${planSpotId}"]`)
  if (spotBlock) {
    spotBlock.remove()
  }

  // マーカーと経路線を即座にクリア
  clearPlanSpotMarkers()
  clearRoutePolylines()

  // ✅ APIを呼び出し、Turbo Streamで全体を再描画
  try {
    const res = await fetch(`/plans/${planId}/plan_spots/${planSpotId}`, {
      method: "DELETE",
      headers: { "X-CSRF-Token": getCsrfToken(), "Accept": "text/vnd.turbo-stream.html" },
    })

    if (res.ok) {
      // Turbo Streamでスポットブロック・距離・時間を更新
      Turbo.renderStreamMessage(await res.text())
      // マーカーと経路線を再描画
      document.dispatchEvent(new CustomEvent("plan:spot-deleted", { detail: { planId, planSpotId } }))
      document.dispatchEvent(new CustomEvent("navibar:updated"))
    } else {
      alert("削除に失敗しました。ページを再読み込みします。")
      location.reload()
    }
  } catch (err) {
    alert("削除に失敗しました。ページを再読み込みします。")
    location.reload()
  }
}

export const bindSpotAddHandler = () => {
  document.removeEventListener("spot:add", handleSpotAdd)
  document.addEventListener("spot:add", handleSpotAdd)
  document.removeEventListener("spot:delete", handleSpotDelete)
  document.addEventListener("spot:delete", handleSpotDelete)
}