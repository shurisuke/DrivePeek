import { Controller } from "@hotwired/stimulus"
import { clearSuggestionMarkers } from "map/state"
import { fitBoundsWithPadding } from "map/visual_center"

// ================================================================
// CommunitySearchFiltersController
// 用途: コミュニティタブの検索フォーム制御
// - 通常モード / エリア選択 / ジャンル選択の切り替え
// - 円エリア検索（地図で囲んで選択）
// - 選択完了時のモバイルUX（ボトムシート展開 + ビジュアルセンター）
// ================================================================

export default class extends Controller {
  static targets = [
    "main", "area", "genre", "areaLabel", "genreLabel",
    "circleDrawButton", "circleClearButton",
    "centerLat", "centerLng", "radiusKm"
  ]

  connect() {
    this.syncAllParents()

    // 円エリア選択完了イベントを監視
    this.handleAreaSelected = this.handleAreaSelected.bind(this)
    document.addEventListener("community:areaSelected", this.handleAreaSelected)

    // 円エリアクリアイベントを監視（plan_preview_controller から）
    this.handleCircleCleared = this.handleCircleCleared.bind(this)
    document.addEventListener("community:circleCleared", this.handleCircleCleared)
  }

  disconnect() {
    document.removeEventListener("community:areaSelected", this.handleAreaSelected)
    document.removeEventListener("community:circleCleared", this.handleCircleCleared)
  }

  // 全親チェックボックスを子の状態から同期
  syncAllParents() {
    this.element.querySelectorAll("[data-parent-group]").forEach(group => {
      this.syncParent(group)
    })
  }

  // 親チェックボックスを子の状態に同期
  syncParent(group) {
    const parent = group.querySelector("[data-parent-checkbox]")
    if (!parent) return

    const children = group.querySelectorAll("input[type='checkbox'][name]")
    const checked = Array.from(children).filter(c => c.checked).length

    parent.checked = checked === children.length
    parent.indeterminate = checked > 0 && checked < children.length
  }

  showArea() {
    this.mainTarget.hidden = true
    this.areaTarget.hidden = false
    this.genreTarget.hidden = true
  }

  showGenre() {
    this.mainTarget.hidden = true
    this.areaTarget.hidden = true
    this.genreTarget.hidden = false
  }

  back() {
    this.mainTarget.hidden = false
    this.areaTarget.hidden = true
    this.genreTarget.hidden = true
    this.updateLabels()
    this.submitForm()
  }

  // ラベルを選択内容で更新
  updateLabels() {
    if (this.hasAreaLabelTarget) {
      this.areaLabelTarget.textContent = this.buildLabel(this.areaTarget, "エリア")
    }
    if (this.hasGenreLabelTarget) {
      this.genreLabelTarget.textContent = this.buildLabel(this.genreTarget, "ジャンル")
    }
  }

  // 選択内容からラベルを構築（親が全選択なら親名、それ以外は子名）
  buildLabel(container, placeholder) {
    const names = []

    container.querySelectorAll("[data-parent-group]").forEach(group => {
      const parent = group.querySelector("[data-parent-checkbox]")
      const parentName = group.querySelector(".selection-list__parent span")?.textContent

      if (parent?.checked && parentName) {
        names.push(parentName)
      } else if (parent?.indeterminate) {
        group.querySelectorAll("input[name]:checked").forEach(cb => {
          const label = cb.closest("label")?.querySelector("span")?.textContent
          if (label) names.push(label)
        })
      }
    })

    // 親グループに属さない単独項目
    container.querySelectorAll(".selection-list__region > .selection-list__item input[name]:checked").forEach(cb => {
      const label = cb.closest("label")?.querySelector("span")?.textContent
      if (label) names.push(label)
    })

    return names.length > 0 ? names.join(", ") : placeholder
  }

  // グループ展開/折りたたみ
  toggleGroup(event) {
    const group = event.currentTarget.closest("[data-parent-group]")
    if (group) {
      group.classList.toggle("is-expanded")
    }
  }

  // 親行クリック時（チェックボックスをトグル）
  toggleParent(event) {
    // アイコンクリック時は何もしない（toggleGroupが処理）
    if (event.target.closest(".selection-list__toggle")) return

    const group = event.currentTarget.closest("[data-parent-group]")
    if (!group) return

    const parentCheckbox = group.querySelector("[data-parent-checkbox]")
    if (!parentCheckbox) return

    parentCheckbox.checked = !parentCheckbox.checked
    this.applyParentSelection(parentCheckbox, group)
  }

  // 親チェックボックス直接クリック時
  selectParent(event) {
    event.stopPropagation()
    const parentCheckbox = event.currentTarget
    const group = parentCheckbox.closest("[data-parent-group]")
    if (!group) return

    this.applyParentSelection(parentCheckbox, group)
  }

  // 親チェックボックスの状態を子に反映
  applyParentSelection(parentCheckbox, group) {
    const childCheckboxes = group.querySelectorAll("input[type='checkbox'][name]")
    childCheckboxes.forEach(cb => {
      cb.checked = parentCheckbox.checked
    })
  }

  // 子チェックボックス変更時（親の状態を更新）
  updateParent(event) {
    const group = event.currentTarget.closest("[data-parent-group]")
    if (group) this.syncParent(group)
  }

  // ============================================
  // 円エリア検索
  // ============================================

  // 「地図で囲んで検索」ボタンクリック
  startCircleDraw() {
    document.dispatchEvent(new CustomEvent("ui:startAreaDraw", {
      detail: { mode: "community" }
    }))
  }

  // 円エリア選択完了時のハンドラ
  handleAreaSelected(event) {
    // Turbo Frameモード（ナビバー）でのみ処理する
    // 静的ページのコントローラでは処理しない
    const form = this.element.querySelector("form")
    if (!form || !form.dataset.turboFrame) return

    const { center_lat, center_lng, radius_km } = event.detail

    // hidden fieldsに値をセット
    if (this.hasCenterLatTarget) this.centerLatTarget.value = center_lat
    if (this.hasCenterLngTarget) this.centerLngTarget.value = center_lng
    if (this.hasRadiusKmTarget) this.radiusKmTarget.value = radius_km

    // UI更新：ボタン切り替え、ステータス表示
    this.updateCircleUI(true, radius_km)

    // 地図上の削除ボタンを表示
    const clearBtn = document.getElementById("community-preview-close")
    if (clearBtn) clearBtn.hidden = false

    // モバイル: ボトムシートを半分展開 → 円全体が見えるようにフィット
    const navibar = document.querySelector("[data-controller~='ui--bottom-sheet']")
    const bottomSheet = this.application.getControllerForElementAndIdentifier(navibar, "ui--bottom-sheet")
    if (bottomSheet?.isMobile) {
      bottomSheet.setState({ params: { state: "mid" } })
      setTimeout(() => {
        // 円の bounds を計算して fitBounds（ボトムシート展開後の正しいパディングで）
        const center = new google.maps.LatLng(center_lat, center_lng)
        const circle = new google.maps.Circle({ center, radius: radius_km * 1000 })
        fitBoundsWithPadding(circle.getBounds())
      }, 350) // ボトムシートアニメーション完了後
    }

    // フォーム送信
    this.submitForm()
  }

  // 「エリア選択を解除」ボタンクリック
  clearCircle() {
    // 地図上の円をクリア
    clearSuggestionMarkers()

    // 地図上の削除ボタンを非表示
    const clearBtn = document.getElementById("community-preview-close")
    if (clearBtn) clearBtn.hidden = true

    this.resetCircleState()
    this.submitForm()
  }

  // 円エリアクリアイベント（plan_preview_controller から）
  handleCircleCleared() {
    const form = this.element.querySelector("form")
    if (!form?.dataset.turboFrame) return

    this.resetCircleState()
    this.submitForm()
  }

  // 円エリア状態をリセット（hidden fields + UI）
  resetCircleState() {
    // hidden fieldsをクリア
    if (this.hasCenterLatTarget) this.centerLatTarget.value = ""
    if (this.hasCenterLngTarget) this.centerLngTarget.value = ""
    if (this.hasRadiusKmTarget) this.radiusKmTarget.value = ""

    // UI更新
    this.updateCircleUI(false)
  }

  // 円エリアUIの更新
  updateCircleUI(hasCircle, radiusKm = null) {
    if (this.hasCircleDrawButtonTarget) {
      this.circleDrawButtonTarget.hidden = hasCircle
    }
    if (this.hasCircleClearButtonTarget) {
      this.circleClearButtonTarget.hidden = !hasCircle
      if (hasCircle && radiusKm) {
        const span = this.circleClearButtonTarget.querySelector("span")
        if (span) span.textContent = `エリア選択中（半径 ${radiusKm.toFixed(1)} km）`
      }
    }
  }

  // フォーム送信
  submitForm() {
    this.element.querySelector("form")?.requestSubmit()
  }
}
