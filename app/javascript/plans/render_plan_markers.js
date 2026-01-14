// ================================================================
// プランのマーカー描画
// 用途: planData をもとに 出発・スポット・帰宅 の各マーカーを描画する
// ================================================================

import {
  getMapInstance,
  clearStartPointMarker,
  setStartPointMarker,
  clearEndPointMarker,
  setEndPointMarker,
  clearPlanSpotMarkers,
  setPlanSpotMarkers,
} from "map/state"
import { showInfoWindowForPin } from "map/infowindow"
import { COLORS } from "map/constants"
import { getPhotoUrl } from "map/photo_cache"

// ================================================================
// SVG番号ピン生成
// - 丸型ピンに番号を表示
// - 色は map/constants.js で管理
// ================================================================

const createNumberedPinSvg = (number, color = COLORS.MY_PLAN) => {
  // 丸型SVG（36x36）+ 中央に白い番号
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="36" height="36" viewBox="0 0 36 36">
      <circle cx="18" cy="18" r="17" fill="${color}"/>
      <text x="18" y="24" text-anchor="middle" font-size="16" font-weight="700" fill="white">${number}</text>
    </svg>
  `.trim()

  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`
}

const normalizeLatLng = (p) => {
  if (!p) return null
  return { lat: Number(p.lat), lng: Number(p.lng) }
}

// ✅ navibar内のDOMを正として「スポット件数」を判定する（必要なら他用途で使える）
const getSpotCountFromDom = () => {
  return document.querySelectorAll(".spot-block[data-plan-spot-id]").length
}

// ✅ 2点間距離（メートル）: Haversine
const distanceMeters = (a, b) => {
  const R = 6371000
  const toRad = (deg) => (deg * Math.PI) / 180

  const dLat = toRad(b.lat - a.lat)
  const dLng = toRad(b.lng - a.lng)

  const lat1 = toRad(a.lat)
  const lat2 = toRad(b.lat)

  const sinDLat = Math.sin(dLat / 2)
  const sinDLng = Math.sin(dLng / 2)

  const h =
    sinDLat * sinDLat +
    Math.cos(lat1) * Math.cos(lat2) * sinDLng * sinDLng

  return 2 * R * Math.asin(Math.sqrt(h))
}

const isNear = (a, b, thresholdMeters = 30) => {
  if (!a || !b) return false
  return distanceMeters(a, b) <= thresholdMeters
}

// ✅ スポットをプランから削除
const deleteSpotFromPlan = async (planId, planSpotId) => {
  if (!planId || !planSpotId) return

  const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content
  if (!csrfToken) return

  try {
    const response = await fetch(`/plans/${planId}/plan_spots/${planSpotId}`, {
      method: "DELETE",
      headers: {
        "X-CSRF-Token": csrfToken,
        "Accept": "text/vnd.turbo-stream.html",
      },
    })

    if (response.ok) {
      // Turbo Streamレスポンスを処理
      const html = await response.text()
      Turbo.renderStreamMessage(html)

      // イベントを発火してマーカーを再描画
      requestAnimationFrame(() => {
        document.dispatchEvent(
          new CustomEvent("plan:spot-deleted", {
            detail: { planId, planSpotId },
          })
        )
        document.dispatchEvent(new CustomEvent("navibar:updated"))
      })
    }
  } catch (error) {
    console.error("スポット削除エラー:", error)
  }
}

const buildHouseMarker = ({ map, position, title }) => {
  return new google.maps.Marker({
    map,
    position,
    title,
    icon: {
      url: "/icons/house-pin.png",
      scaledSize: new google.maps.Size(50, 55),
    },
  })
}

const getEndPointFromPlanData = (planData) => {
  // 環境によって end_point / goal_point の揺れがあり得るので両対応
  return planData?.end_point || planData?.goal_point
}

// ✅ UIのトグル状態（#map.dataset.goalPointVisible）を正として扱う
const isGoalPointVisible = () => {
  const mapEl = document.getElementById("map")
  return mapEl?.dataset?.goalPointVisible === "true"
}

// ✅ DOMから出発地点の住所を取得
const getStartPointAddressFromDom = () => {
  const el = document.querySelector(".start-point-block .address")
  return el?.textContent?.trim() || null
}

// ✅ DOMから帰宅地点の住所を取得
const getGoalPointAddressFromDom = () => {
  const el = document.querySelector(".goal-point-block .address")
  return el?.textContent?.trim() || null
}

// ✅ DOMから出発地点の位置を取得
const getStartPointPositionFromDom = () => {
  const el = document.querySelector(".start-point-block")
  if (!el) return null

  const lat = parseFloat(el.dataset.lat)
  const lng = parseFloat(el.dataset.lng)
  if (isNaN(lat) || isNaN(lng)) return null
  return { lat, lng }
}

// ✅ DOMから帰宅地点の位置を取得
const getGoalPointPositionFromDom = () => {
  const el = document.querySelector(".goal-point-block")
  if (!el) return null

  const lat = parseFloat(el.dataset.lat)
  const lng = parseFloat(el.dataset.lng)
  if (isNaN(lat) || isNaN(lng)) return null
  return { lat, lng }
}

// ✅ DOMからスポット情報を取得（position順）
const getSpotInfoFromDom = () => {
  const blocks = document.querySelectorAll(".spot-block[data-plan-spot-id]")
  const spots = []

  blocks.forEach((block) => {
    const nameEl = block.querySelector(".spot-name")
    const addressEl = block.querySelector(".spot-address")

    spots.push({
      name: nameEl?.textContent?.trim() || null,
      address: addressEl?.textContent?.trim() || null,
      lat: Number(block.dataset.lat),
      lng: Number(block.dataset.lng),
      placeId: block.dataset.placeId || null,
      planId: block.dataset.planSpotDeletePlanIdValue || null,
      planSpotId: block.dataset.planSpotId || null,
    })
  })

  return spots
}

// ✅ 「帰宅マーカーだけ」最新条件で描画し直す（トグル状態で判断）
export const refreshGoalMarker = (planData) => {
  const map = getMapInstance()
  if (!map) {
    console.warn("[render_plan_markers] refreshGoalMarker: map instance missing")
    return
  }

  const visible = isGoalPointVisible()
  // ✅ DOMから位置を取得（turbo_stream更新後は最新データ）
  const start = getStartPointPositionFromDom() || normalizeLatLng(planData?.start_point)
  const end = getGoalPointPositionFromDom() || normalizeLatLng(getEndPointFromPlanData(planData))

  // いったん消してから、条件を満たすなら作り直す
  clearEndPointMarker()

  // ✅ トグルOFFなら、ここで終了（=消えた状態になる）
  if (!visible) return

  // start と goal がほぼ同じなら goal は作らない（start を兼用）
  if (start && end && isNear(start, end, 30)) return

  if (!end) return

  const marker = buildHouseMarker({ map, position: end, title: "帰宅地点" })

  // ✅ クリックでInfoWindow表示（編集ボタン付き）
  marker.addListener("click", () => {
    const address = getGoalPointAddressFromDom()
    showInfoWindowForPin({
      marker,
      name: "帰宅",
      address,
      editButtons: [
        {
          id: "goal-point-infowindow-edit-btn",
          label: "帰宅地点を変更",
          onClick: () => {
            const editArea = document.querySelector(".goal-point-block [data-goal-point-editor-target='editArea']")
            if (editArea) {
              editArea.hidden = !editArea.hidden
              if (!editArea.hidden) {
                const input = editArea.querySelector("input")
                if (input) input.focus()
              }
            }
          },
        },
      ],
    })
  })

  setEndPointMarker(marker)
}

export const renderPlanMarkers = (planData, { pinColor = COLORS.MY_PLAN } = {}) => {
  const map = getMapInstance()
  if (!map) {
    console.error("マップインスタンスが存在しません")
    return
  }

  // 既存マーカーを用途別にクリア
  clearStartPointMarker()
  clearPlanSpotMarkers()
  clearEndPointMarker()

  // 出発地点（DOMから位置を取得、なければplanDataを使用）
  const start = getStartPointPositionFromDom() || normalizeLatLng(planData?.start_point)
  const end = getGoalPointPositionFromDom() || normalizeLatLng(getEndPointFromPlanData(planData))

  if (start) {
    const marker = buildHouseMarker({ map, position: start, title: "出発地点" })

    // ✅ クリックでInfoWindow表示（出発地点の編集ボタンのみ）
    marker.addListener("click", () => {
      const address = getStartPointAddressFromDom()
      showInfoWindowForPin({
        marker,
        name: "出発",
        address,
        editButtons: [
          {
            id: "start-point-infowindow-edit-btn",
            label: "出発地点を変更",
            onClick: () => {
              const editArea = document.querySelector(".start-point-block [data-start-point-editor-target='editArea']")
              if (editArea) {
                editArea.hidden = !editArea.hidden
                if (!editArea.hidden) {
                  const input = editArea.querySelector("input")
                  if (input) input.focus()
                }
              }
            },
          },
        ],
      })
    })

    setStartPointMarker(marker)
  }

  // スポット（DOMから情報・位置を取得）
  // ✅ position順の番号付きSVGピンで表示
  const spotInfoList = getSpotInfoFromDom()

  const spotMarkers = spotInfoList
    .filter((info) => info.lat && info.lng)
    .map((spotInfo, index) => {
      const spotNumber = index + 1

      const marker = new google.maps.Marker({
        map,
        position: { lat: spotInfo.lat, lng: spotInfo.lng },
        title: spotInfo.name || `スポット ${spotNumber}`,
        icon: {
          url: createNumberedPinSvg(spotNumber, pinColor),
          scaledSize: new google.maps.Size(36, 36),
          anchor: new google.maps.Point(18, 18),
        },
      })

      // ✅ クリックでInfoWindow表示（削除ボタン付き）
      marker.addListener("click", () => {
        const editButtons = spotInfo.planId && spotInfo.planSpotId
          ? [
              {
                id: `spot-infowindow-delete-btn-${spotInfo.planSpotId}`,
                label: "プランから削除",
                variant: "orange",
                onClick: () => deleteSpotFromPlan(spotInfo.planId, spotInfo.planSpotId),
              },
            ]
          : []

        // placeIdがあれば写真を取得（キャッシュ優先）
        if (spotInfo.placeId) {
          getPhotoUrl({ placeId: spotInfo.placeId, map }).then((photoUrl) => {
            showInfoWindowForPin({
              marker,
              name: spotInfo.name || `スポット ${spotNumber}`,
              address: spotInfo.address,
              photoUrl,
              editButtons,
            })
          })
        } else {
          showInfoWindowForPin({
            marker,
            name: spotInfo.name || `スポット ${spotNumber}`,
            address: spotInfo.address,
            photoUrl: null,
            editButtons,
          })
        }
      })

      return marker
    })
  setPlanSpotMarkers(spotMarkers)

  // 帰宅地点（トグルONの時だけ描画）
  refreshGoalMarker(planData)
}
