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

// ================================================================
// SVG番号ピン生成
// - しずく型のオレンジピンに番号を表示
// - 色はspot-order-pinと同じ #ef813d
// ================================================================
const SPOT_PIN_COLOR = "#ef813d"

const createNumberedPinSvg = (number) => {
  // しずく型SVG（30x40）+ 中央に白い番号
  const svg = `
    <svg xmlns="http://www.w3.org/2000/svg" width="30" height="40" viewBox="0 0 30 40">
      <path d="M15 0C6.7 0 0 6.7 0 15c0 10.6 15 25 15 25s15-14.4 15-25C30 6.7 23.3 0 15 0z" fill="${SPOT_PIN_COLOR}"/>
      <text x="15" y="19" text-anchor="middle" font-size="14" font-weight="700" fill="white">${number}</text>
    </svg>
  `.trim()

  return `data:image/svg+xml;charset=UTF-8,${encodeURIComponent(svg)}`
}

const normalizeLatLng = (p) => {
  if (!p) return null
  return { lat: Number(p.lat), lng: Number(p.lng) }
}

// ✅ planbar内のDOMを正として「スポット件数」を判定する（必要なら他用途で使える）
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
      photoUrl: block.dataset.photoUrl || null,
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
  const start = normalizeLatLng(planData?.start_point)
  const end = normalizeLatLng(getEndPointFromPlanData(planData))

  console.log("[render_plan_markers] refreshGoalMarker", {
    visible,
    spotCount: getSpotCountFromDom(),
    start,
    end,
  })

  // いったん消してから、条件を満たすなら作り直す
  clearEndPointMarker()

  // ✅ トグルOFFなら、ここで終了（=消えた状態になる）
  if (!visible) return

  // start と goal がほぼ同じなら goal は作らない（start を兼用）
  if (start && end && isNear(start, end, 30)) return

  if (!end) return

  const marker = buildHouseMarker({ map, position: end, title: "帰宅地点" })

  // ✅ クリックでInfoWindow表示（ボタンなし）
  marker.addListener("click", () => {
    const address = getGoalPointAddressFromDom()
    showInfoWindowForPin({
      marker,
      name: "帰宅",
      address,
    })
  })

  setEndPointMarker(marker)
}

export const renderPlanMarkers = (planData) => {
  const map = getMapInstance()
  if (!map) {
    console.error("マップインスタンスが存在しません")
    return
  }

  console.log("[render_plan_markers] renderPlanMarkers", planData)

  // 既存マーカーを用途別にクリア
  clearStartPointMarker()
  clearPlanSpotMarkers()
  clearEndPointMarker()

  // 出発地点
  const start = normalizeLatLng(planData?.start_point)
  if (start) {
    const marker = buildHouseMarker({ map, position: start, title: "出発地点" })

    // ✅ クリックでInfoWindow表示（ボタンなし）
    marker.addListener("click", () => {
      const address = getStartPointAddressFromDom()
      showInfoWindowForPin({
        marker,
        name: "出発",
        address,
      })
    })

    setStartPointMarker(marker)
  }

  // スポット（DOMから情報を取得してマーカーに紐付け）
  // ✅ position順の番号付きSVGピンで表示
  const spotInfoList = getSpotInfoFromDom()
  const spots = Array.isArray(planData?.spots) ? planData.spots : []

  const spotMarkers = spots
    .map(normalizeLatLng)
    .filter(Boolean)
    .map((spot, index) => {
      const spotInfo = spotInfoList[index] || {}
      const spotNumber = index + 1

      const marker = new google.maps.Marker({
        map,
        position: spot,
        title: spotInfo.name || `スポット ${spotNumber}`,
        icon: {
          url: createNumberedPinSvg(spotNumber),
          scaledSize: new google.maps.Size(30, 40),
          anchor: new google.maps.Point(15, 40),
        },
      })

      // ✅ クリックでInfoWindow表示（ボタンなし）
      marker.addListener("click", () => {
        showInfoWindowForPin({
          marker,
          name: spotInfo.name || `スポット ${spotNumber}`,
          address: spotInfo.address,
          photoUrl: spotInfo.photoUrl,
        })
      })

      return marker
    })
  setPlanSpotMarkers(spotMarkers)

  // 帰宅地点（トグルONの時だけ描画）
  refreshGoalMarker(planData)
}
