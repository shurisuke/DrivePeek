import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "dropdown", "checkbox", "hiddenField", "label", "prefectureGroup", "prefectureCheckbox"]
  static values = {
    placeholder: { type: String, default: "選択してください" }
  }

  connect() {
    // DOMが完全に準備できてからラベルを更新
    requestAnimationFrame(() => {
      this.updateLabel()
      this.updateAllPrefectureCheckboxes()
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
    event.stopPropagation()
    const isOpening = !this.dropdownTarget.classList.contains("is-open")

    if (isOpening) {
      // 他のドロップダウンを閉じるイベントを発火
      document.dispatchEvent(new CustomEvent("multi-select:open", { detail: { source: this.element } }))
    }

    this.dropdownTarget.classList.toggle("is-open")
  }

  close(event) {
    event.stopPropagation()
    this.dropdownTarget.classList.remove("is-open")
  }

  closeOnClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.dropdownTarget.classList.remove("is-open")
    }
  }

  // 他のドロップダウンが開いたときに自分を閉じる
  closeOtherDropdowns(event) {
    if (event.detail.source !== this.element) {
      this.dropdownTarget.classList.remove("is-open")
    }
  }

  // 都道府県グループを展開/折りたたみ
  togglePrefecture(event) {
    event.stopPropagation()
    const group = event.currentTarget.closest("[data-multi-select-target='prefectureGroup']")
    if (group) {
      group.classList.toggle("is-expanded")
    }
  }

  // 都道府県チェックボックス選択時（配下の市区町村を全選択/全解除）
  selectPrefecture(event) {
    event.stopPropagation()
    const prefCheckbox = event.currentTarget
    const group = prefCheckbox.closest("[data-multi-select-target='prefectureGroup']")
    if (!group) return

    const cityCheckboxes = group.querySelectorAll("[data-multi-select-target='checkbox']")
    cityCheckboxes.forEach(cb => {
      cb.checked = prefCheckbox.checked
    })

    this.updateHiddenFields()
    this.updateLabel()
  }

  // ラベルクリック時のイベント伝播を止める（展開トグルを防ぐ）
  stopPropagation(event) {
    event.stopPropagation()
  }

  // 市区町村チェックボックス選択時
  select(event) {
    event.stopPropagation()

    // 親の都道府県チェックボックスの状態を更新
    const group = event.currentTarget.closest("[data-multi-select-target='prefectureGroup']")
    if (group) {
      this.updatePrefectureCheckbox(group)
    }

    this.updateHiddenFields()
    this.updateLabel()
  }

  // 都道府県チェックボックスの状態を更新（全選択/一部選択/未選択）
  updatePrefectureCheckbox(group) {
    const prefCheckbox = group.querySelector("[data-multi-select-target='prefectureCheckbox']")
    if (!prefCheckbox) return

    const cityCheckboxes = group.querySelectorAll("[data-multi-select-target='checkbox']")
    const checkedCount = Array.from(cityCheckboxes).filter(cb => cb.checked).length
    const totalCount = cityCheckboxes.length

    if (checkedCount === 0) {
      prefCheckbox.checked = false
      prefCheckbox.indeterminate = false
    } else if (checkedCount === totalCount) {
      prefCheckbox.checked = true
      prefCheckbox.indeterminate = false
    } else {
      prefCheckbox.checked = false
      prefCheckbox.indeterminate = true
    }
  }

  // すべての都道府県チェックボックスの状態を更新
  updateAllPrefectureCheckboxes() {
    this.prefectureGroupTargets.forEach(group => {
      this.updatePrefectureCheckbox(group)
    })
  }

  updateHiddenFields() {
    this.hiddenFieldTargets.forEach(field => field.remove())

    const selected = this.checkboxTargets.filter(cb => cb.checked)
    selected.forEach(cb => {
      const hidden = document.createElement("input")
      hidden.type = "hidden"
      hidden.name = this.element.dataset.multiSelectName
      hidden.value = cb.value
      hidden.dataset.multiSelectTarget = "hiddenField"
      this.element.appendChild(hidden)
    })
  }

  updateLabel() {
    const selected = this.checkboxTargets.filter(cb => cb.checked)
    if (selected.length === 0) {
      this.labelTarget.textContent = this.placeholderValue
      this.labelTarget.classList.add("is-placeholder")
    } else {
      // 「都道府県/city, city」形式でグループ化して表示
      const labelText = this.formatSelectedLabel(selected)
      this.labelTarget.textContent = labelText
      this.labelTarget.classList.remove("is-placeholder")
    }
  }

  // 選択されたアイテムを「都道府県(city, city)」形式でフォーマット
  formatSelectedLabel(selected) {
    // valueが "都道府県/市区町村" 形式かチェック
    const hasSlash = selected.some(cb => cb.value.includes("/"))

    if (!hasSlash) {
      // ジャンルなど単純なリストの場合
      return selected.map(cb => cb.dataset.label).join(", ")
    }

    // 都道府県ごとの全市区町村数を取得
    const totalCitiesByPref = this.getTotalCitiesByPrefecture()

    // 都道府県ごとにグループ化
    const grouped = {}
    selected.forEach(cb => {
      const [prefecture, city] = cb.value.split("/", 2)
      if (!grouped[prefecture]) {
        grouped[prefecture] = []
      }
      grouped[prefecture].push(city)
    })

    // 「都道府県(city, city)」形式に変換（全選択時は都道府県名のみ）
    return Object.entries(grouped).map(([pref, cities]) => {
      const totalCities = totalCitiesByPref[pref] || 0
      if (cities.length === totalCities) {
        // 全市区町村が選択されている場合は都道府県名のみ
        return pref
      }
      return `${pref}(${cities.join(", ")})`
    }).join(", ")
  }

  // 都道府県ごとの全市区町村数を取得
  getTotalCitiesByPrefecture() {
    const result = {}
    this.prefectureGroupTargets.forEach(group => {
      const prefCheckbox = group.querySelector("[data-multi-select-target='prefectureCheckbox']")
      if (!prefCheckbox) return

      // 都道府県名を取得（ラベルのspanから）
      const label = group.querySelector(".multi-select__prefecture-label span:first-of-type")
      if (!label) return
      const prefName = label.textContent.trim()

      // 市区町村数を取得
      const cityCheckboxes = group.querySelectorAll("[data-multi-select-target='checkbox']")
      result[prefName] = cityCheckboxes.length
    })
    return result
  }
}
