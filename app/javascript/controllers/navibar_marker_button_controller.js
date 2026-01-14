// app/javascript/controllers/navibar_marker_button_controller.js
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
import { showInfoWindowForPin } from "map/infowindow"
import { getPhotoUrl } from "map/photo_cache"

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

    // スポット情報を取得
    const name = spotBlock.querySelector(".spot-name")?.textContent?.trim() || "スポット"
    const address = spotBlock.querySelector(".spot-address")?.textContent?.trim() || null
    const placeId = spotBlock.dataset.placeId
    const planId = spotBlock.dataset.planSpotDeletePlanIdValue
    const planSpotId = spotBlock.dataset.planSpotId

    // 削除ボタンの設定
    const editButtons = [
      {
        id: `spot-infowindow-delete-btn-${planSpotId}`,
        label: "プランから削除",
        variant: "orange",
        onClick: () => this.#deleteSpot(planId, planSpotId),
      },
    ]

    // placeIdがあれば写真を取得してから表示（キャッシュ優先）
    if (placeId) {
      getPhotoUrl({ placeId, map }).then((photoUrl) => {
        showInfoWindowForPin({ marker, name, address, photoUrl, editButtons })
      })
    } else {
      showInfoWindowForPin({ marker, name, address, editButtons })
    }
  }

  // 出発・帰宅のボタンクリック
  point(e) {
    const type = e.currentTarget.dataset.pointType
    const goalMarker = getEndPointMarker()
    const startMarker = getStartPointMarker()
    const map = getMapInstance()
    if (!map) return

    // ✅ 出発アイコンクリック
    if (type === "start" && startMarker) {
      map.panTo(startMarker.getPosition())
      const address = this.#getStartAddressFromDom()
      showInfoWindowForPin({
        marker: startMarker,
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
      return
    }

    // ✅ 帰宅アイコンクリック（帰宅マーカーが存在する場合）
    if (type === "goal" && goalMarker) {
      map.panTo(goalMarker.getPosition())
      const address = this.#getGoalAddressFromDom()
      showInfoWindowForPin({
        marker: goalMarker,
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
      return
    }

    // ✅ 帰宅マーカーが存在しない場合（出発地点と近すぎて省略された場合）
    // 出発マーカーの位置にパンし、帰宅用のInfoWindowを表示
    if (type === "goal" && !goalMarker && startMarker) {
      map.panTo(startMarker.getPosition())
      const address = this.#getGoalAddressFromDom()
      showInfoWindowForPin({
        marker: startMarker,
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

  // DOMから出発地点の住所を取得
  #getStartAddressFromDom() {
    const el = document.querySelector(".start-point-block .address")
    return el?.textContent?.trim() || null
  }

  // DOMから帰宅地点の住所を取得
  #getGoalAddressFromDom() {
    const el = document.querySelector(".goal-point-block .address")
    return el?.textContent?.trim() || null
  }

  // スポットを削除
  async #deleteSpot(planId, planSpotId) {
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
}
