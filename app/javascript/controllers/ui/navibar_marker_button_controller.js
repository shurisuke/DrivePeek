// app/javascript/controllers/ui/navibar_marker_button_controller.js
//
// ================================================================
// プランバー内マーカーボタン
// 用途: プランバー内のボタンクリックで地図をパン＋InfoWindowを表示
// ================================================================

import { Controller } from "@hotwired/stimulus"
import {
  getMapInstance,
  getPlanSpotMarkers,
  getStartPointMarker,
  getEndPointMarker,
} from "map/state"
import { showInfoWindowWithFrame } from "map/infowindow"

export default class extends Controller {
  // スポットのボタンクリック
  spot(e) {
    const spotBlock = e.currentTarget.closest(".spot-block")
    if (!spotBlock) return

    const lat = parseFloat(spotBlock.dataset.lat)
    const lng = parseFloat(spotBlock.dataset.lng)
    if (isNaN(lat) || isNaN(lng)) return

    const marker = this.#findMarkerByPosition(getPlanSpotMarkers(), lat, lng)
    if (!marker) return

    const map = getMapInstance()
    if (!map) return

    map.panTo(marker.getPosition())

    // DOMからスポット情報を取得
    const spotId = spotBlock.dataset.spotId
    const placeId = spotBlock.dataset.placeId
    const planId = spotBlock.dataset["plan-SpotDeletePlanIdValue"]
    const planSpotId = spotBlock.dataset.planSpotId
    const nameEl = spotBlock.querySelector(".spot-name")
    const addressEl = spotBlock.querySelector(".spot-address")
    const genreEls = spotBlock.querySelectorAll(".genre-chip:not(.genre-chip--skeleton)")

    showInfoWindowWithFrame({
      anchor: marker,
      spotId,
      placeId,
      name: nameEl?.textContent?.trim() || null,
      address: addressEl?.textContent?.trim() || null,
      genres: Array.from(genreEls).map(el => el.textContent?.trim()).filter(Boolean),
      showButton: true,
      planId,
      planSpotId,
    })
  }

  // 出発・帰宅のボタンクリック
  point(e) {
    const type = e.currentTarget.dataset.pointType
    const goalMarker = getEndPointMarker()
    const startMarker = getStartPointMarker()
    const map = getMapInstance()
    if (!map) return

    const planId = document.getElementById("map")?.dataset?.planId

    // ✅ 出発アイコンクリック
    if (type === "start" && startMarker) {
      map.panTo(startMarker.getPosition())
      showInfoWindowWithFrame({
        anchor: startMarker,
        name: "出発",
        editMode: "start_point",
        planId,
      })
      return
    }

    // ✅ 帰宅アイコンクリック（帰宅マーカーが存在する場合）
    if (type === "goal" && goalMarker) {
      map.panTo(goalMarker.getPosition())
      showInfoWindowWithFrame({
        anchor: goalMarker,
        name: "帰宅",
        editMode: "goal_point",
        planId,
      })
      return
    }

    // ✅ 帰宅マーカーが存在しない場合（出発地点と近すぎて省略された場合）
    if (type === "goal" && !goalMarker && startMarker) {
      map.panTo(startMarker.getPosition())
      showInfoWindowWithFrame({
        anchor: startMarker,
        name: "帰宅",
        editMode: "goal_point",
        planId,
      })
      return
    }
  }

  // 座標でマーカーを検索（誤差許容）
  #findMarkerByPosition(markers, lat, lng) {
    const threshold = 0.00001 // 約1m以内の誤差を許容
    return markers.find((m) => {
      const pos = m.getPosition()
      return (
        Math.abs(pos.lat() - lat) < threshold &&
        Math.abs(pos.lng() - lng) < threshold
      )
    })
  }
}
