import { Controller } from "@hotwired/stimulus"

// 検索ボックスのモード切替（通常 / エリア選択 / ジャンル選択）
export default class extends Controller {
  static targets = ["main", "area", "genre", "areaLabel", "genreLabel"]

  connect() {
    this.syncAllParents()
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
}
