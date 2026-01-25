import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "dropdown", "checkbox", "label", "parentGroup", "parentCheckbox", "searchInput", "region"]
  static values = {
    placeholder: { type: String, default: "選択してください" }
  }

  connect() {
    // DOMが完全に準備できてからラベルを更新
    requestAnimationFrame(() => {
      this.updateLabel()
      this.updateAllParentCheckboxes()
    })
    this.boundCloseOnClickOutside = this.closeOnClickOutside.bind(this)
    this.boundCloseOtherDropdowns = this.closeOtherDropdowns.bind(this)
    document.addEventListener("click", this.boundCloseOnClickOutside)
    document.addEventListener("multi-select:open", this.boundCloseOtherDropdowns)
  }

  disconnect() {
    document.removeEventListener("click", this.boundCloseOnClickOutside)
    document.removeEventListener("multi-select:open", this.boundCloseOtherDropdowns)
  }

  toggle(event) {
    // input内のクリックは無視（フィルタ入力のため）
    if (event.target.classList.contains("multi-select__input")) return

    event.stopPropagation()
    const isOpening = !this.dropdownTarget.classList.contains("is-open")

    if (isOpening) {
      document.dispatchEvent(new CustomEvent("multi-select:open", { detail: { source: this.element } }))
    }

    this.dropdownTarget.classList.toggle("is-open")
  }

  open(event) {
    event.stopPropagation()
    if (!this.dropdownTarget.classList.contains("is-open")) {
      document.dispatchEvent(new CustomEvent("multi-select:open", { detail: { source: this.element } }))
      this.dropdownTarget.classList.add("is-open")
    }
  }

  close(event) {
    event.stopPropagation()
    this.dropdownTarget.classList.remove("is-open")
    this.clearSearch()
  }

  // 検索フィルタ
  filter(event) {
    const query = event.target.value.toLowerCase().trim()

    if (query === "") {
      this.resetFilter()
      return
    }

    // 親グループごとに処理
    this.parentGroupTargets.forEach(group => {
      const parentLabel = group.querySelector(".multi-select__parent-label span")
      const parentName = parentLabel ? parentLabel.textContent.toLowerCase() : ""
      const parentMatches = parentName.includes(query)

      // 子要素をフィルタ
      const children = group.querySelectorAll(".multi-select__option")
      let hasVisibleChild = false

      children.forEach(option => {
        const cb = option.querySelector("[data-multi-select-target='checkbox']")
        const childLabel = (cb?.dataset.label || "").toLowerCase()
        const childMatches = childLabel.includes(query)

        // 親または子がマッチすれば表示
        if (parentMatches || childMatches) {
          option.style.display = ""
          hasVisibleChild = true
        } else {
          option.style.display = "none"
        }
      })

      // グループの表示/非表示
      if (hasVisibleChild || parentMatches) {
        group.style.display = ""
        group.classList.add("is-expanded")
      } else {
        group.style.display = "none"
      }
    })

    // 親グループに属さない独立オプションもフィルタ
    this.checkboxTargets.forEach(cb => {
      const option = cb.closest(".multi-select__option")
      if (!option) return

      // 親グループ内の場合は既に処理済み
      if (option.closest(".multi-select__parent-group")) return

      const label = (cb.dataset.label || "").toLowerCase()
      option.style.display = label.includes(query) ? "" : "none"
    })

    // 地方/カテゴリ: 表示中の要素がなければ非表示
    if (this.hasRegionTarget) {
      this.regionTargets.forEach(region => {
        const visibleItems = region.querySelectorAll(".multi-select__option:not([style*='display: none']), .multi-select__parent-group:not([style*='display: none'])")
        region.style.display = visibleItems.length > 0 ? "" : "none"
      })
    }
  }

  // フィルタをリセット
  resetFilter() {
    this.checkboxTargets.forEach(cb => {
      const option = cb.closest(".multi-select__option")
      if (option) option.style.display = ""
    })

    this.parentGroupTargets.forEach(group => {
      group.style.display = ""
      group.classList.remove("is-expanded")
    })

    if (this.hasRegionTarget) {
      this.regionTargets.forEach(region => {
        region.style.display = ""
      })
    }
  }

  // 検索入力をクリア
  clearSearch() {
    if (this.hasSearchInputTarget) {
      this.resetFilter()
      // ラベルを復元（選択状態を反映）
      this.updateLabel()
    }
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.remove("is-open")
      this.clearSearch()
    }
  }

  // 他のドロップダウンが開いたときに自分を閉じる
  closeOtherDropdowns(event) {
    if (event.detail.source !== this.element) {
      this.dropdownTarget.classList.remove("is-open")
    }
  }

  // 親グループを展開/折りたたみ
  toggleParent(event) {
    event.stopPropagation()
    const group = event.currentTarget.closest("[data-multi-select-target='parentGroup']")
    if (group) {
      group.classList.toggle("is-expanded")
    }
  }

  // 親チェックボックス選択時（配下の子を全選択/全解除）
  selectParent(event) {
    event.stopPropagation()
    const parentCheckbox = event.currentTarget
    const group = parentCheckbox.closest("[data-multi-select-target='parentGroup']")
    if (!group) return

    const childCheckboxes = group.querySelectorAll("[data-multi-select-target='checkbox']")
    childCheckboxes.forEach(cb => {
      cb.checked = parentCheckbox.checked
    })

    this.updateLabel()
    this.dispatchSelectionChange()
  }

  // ラベルクリック時のイベント伝播を止める（展開トグルを防ぐ）
  stopPropagation(event) {
    event.stopPropagation()
  }

  // 子チェックボックス選択時
  select(event) {
    event.stopPropagation()

    // 親チェックボックスの状態を更新
    const group = event.currentTarget.closest("[data-multi-select-target='parentGroup']")
    if (group) {
      this.updateParentCheckbox(group)
    }

    this.updateLabel()
    this.dispatchSelectionChange()
  }

  // 選択変更イベントを発火（親コントローラーに通知）
  dispatchSelectionChange() {
    this.element.dispatchEvent(new CustomEvent("multi-select:change", { bubbles: true }))
  }

  // 親チェックボックスの状態を更新（全選択/一部選択/未選択）
  updateParentCheckbox(group) {
    const parentCheckbox = group.querySelector("[data-multi-select-target='parentCheckbox']")
    if (!parentCheckbox) return

    const childCheckboxes = group.querySelectorAll("[data-multi-select-target='checkbox']")
    const checkedCount = Array.from(childCheckboxes).filter(cb => cb.checked).length
    const totalCount = childCheckboxes.length

    if (checkedCount === 0) {
      parentCheckbox.checked = false
      parentCheckbox.indeterminate = false
    } else if (checkedCount === totalCount) {
      parentCheckbox.checked = true
      parentCheckbox.indeterminate = false
    } else {
      parentCheckbox.checked = false
      parentCheckbox.indeterminate = true
    }
  }

  // すべての親チェックボックスの状態を更新
  updateAllParentCheckboxes() {
    this.parentGroupTargets.forEach(group => {
      this.updateParentCheckbox(group)
    })
  }

  updateLabel() {
    const selected = this.checkboxTargets.filter(cb => cb.checked)
    const isInput = this.labelTarget.tagName === "INPUT"

    if (selected.length === 0) {
      if (isInput) {
        this.labelTarget.value = ""
        this.labelTarget.placeholder = this.placeholderValue
      } else {
        this.labelTarget.textContent = this.placeholderValue
        this.labelTarget.classList.add("is-placeholder")
      }
    } else {
      const labelText = this.formatSelectedLabel(selected)
      if (isInput) {
        this.labelTarget.value = labelText
      } else {
        this.labelTarget.textContent = labelText
        this.labelTarget.classList.remove("is-placeholder")
      }
    }
  }

  // 選択されたアイテムを「親(子, 子)」形式でフォーマット
  formatSelectedLabel(selected) {
    // valueが "親/子" 形式かチェック（エリアの場合）
    const hasSlash = selected.some(cb => cb.value.includes("/"))

    if (!hasSlash) {
      // ジャンルなど単純なリストの場合
      return selected.map(cb => cb.dataset.label).join(", ")
    }

    // 親グループごとの子要素数を取得
    const childCountByParent = this.getChildCountByParent()

    // 親ごとにグループ化
    const grouped = {}
    selected.forEach(cb => {
      const [parent, child] = cb.value.split("/", 2)
      if (!grouped[parent]) {
        grouped[parent] = []
      }
      grouped[parent].push(child)
    })

    // 「親(子, 子)」形式に変換（全選択時は親名のみ）
    return Object.entries(grouped).map(([parent, children]) => {
      const totalChildren = childCountByParent[parent] || 0
      if (children.length === totalChildren) {
        // 全子要素が選択されている場合は親名のみ
        return parent
      }
      return `${parent}(${children.join(", ")})`
    }).join(", ")
  }

  // 親グループごとの子要素数を取得
  getChildCountByParent() {
    const result = {}
    this.parentGroupTargets.forEach(group => {
      const parentCheckbox = group.querySelector("[data-multi-select-target='parentCheckbox']")
      if (!parentCheckbox) return

      // 親名を取得（ラベルのspanから）
      const label = group.querySelector(".multi-select__parent-label span:first-of-type")
      if (!label) return
      const parentName = label.textContent.trim()

      // 子要素数を取得
      const childCheckboxes = group.querySelectorAll("[data-multi-select-target='checkbox']")
      result[parentName] = childCheckboxes.length
    })
    return result
  }
}
