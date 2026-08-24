import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["columnMenu", "empty", "query", "row", "status"]
  static values = { defaultHidden: Array }

  connect() {
    this.columns = Array.from(this.element.querySelectorAll("thead th"))
    this.columns.forEach(column => { column.dataset.columnLabel ||= column.textContent.trim() })
    this.collator = new Intl.Collator(undefined, { numeric: true, sensitivity: "base" })
    this.columnPreferences = this.loadColumnPreferences()
    this.buildColumnMenu()
    this.buildSortControls()
    this.filter()
  }

  filter() {
    const query = this.queryTarget.value.trim().toLowerCase()
    let visible = 0

    this.rowTargets.forEach(row => {
      const matches = query.length === 0 || row.textContent.toLowerCase().includes(query)
      row.hidden = !matches
      if (matches) visible += 1
    })

    this.emptyTarget.hidden = visible !== 0
    this.statusTarget.textContent = query.length === 0 ? `${visible} rows` : `${visible} of ${this.rowTargets.length} rows`
  }

  toggleColumn(event) {
    const index = Number(event.currentTarget.dataset.columnIndex)
    const key = event.currentTarget.dataset.columnKey
    const visible = event.currentTarget.checked

    this.setColumnVisibility(index, visible)
    this.columnPreferences[key] = visible
    this.saveColumnPreferences()
  }

  resetColumns() {
    this.columnPreferences = {}

    this.columnMenuTarget.querySelectorAll("input[type='checkbox']").forEach(checkbox => {
      const index = Number(checkbox.dataset.columnIndex)
      const visible = !this.defaultHiddenValue.includes(checkbox.dataset.columnKey)

      checkbox.checked = visible
      this.setColumnVisibility(index, visible)
    })

    try {
      window.localStorage.removeItem(this.storageKey)
    } catch {
      // The table remains usable when storage is disabled.
    }
  }

  sort(event) {
    const index = Number(event.currentTarget.dataset.columnIndex)
    const direction = this.sortIndex === index && this.sortDirection === "ascending" ? "descending" : "ascending"
    const rows = this.rowTargets.map((row, originalIndex) => ({ row, originalIndex }))

    rows.sort((left, right) => {
      const leftValue = left.row.children[index]?.textContent.trim() || ""
      const rightValue = right.row.children[index]?.textContent.trim() || ""
      const comparison = this.compareValues(leftValue, rightValue, direction)

      return comparison || left.originalIndex - right.originalIndex
    })

    const body = this.element.querySelector("tbody")
    rows.forEach(({ row }) => body.append(row))
    this.sortIndex = index
    this.sortDirection = direction
    this.updateSortControls(index, direction)
  }

  buildColumnMenu() {
    this.columnMenuTarget.replaceChildren()

    this.columns.forEach((column, index) => {
      if (column.dataset.columnLocked === "true") return

      const key = column.dataset.columnKey
      const savedVisibility = this.columnPreferences[key]
      const checked = savedVisibility === undefined ? !this.defaultHiddenValue.includes(key) : savedVisibility
      const label = document.createElement("label")
      label.className = "flex items-center gap-2 whitespace-nowrap"

      const checkbox = document.createElement("input")
      checkbox.type = "checkbox"
      checkbox.checked = checked
      checkbox.dataset.columnIndex = index
      checkbox.dataset.columnKey = key
      checkbox.dataset.action = "data-table#toggleColumn"

      const text = document.createElement("span")
      text.textContent = column.dataset.columnLabel

      label.append(checkbox, text)
      this.columnMenuTarget.append(label)

      this.setColumnVisibility(index, checked)
    })
  }

  buildSortControls() {
    this.sortIndicators = new Map()

    this.columns.forEach((column, index) => {
      if (column.dataset.columnLocked === "true") return

      const label = column.dataset.columnLabel
      const button = document.createElement("button")
      button.type = "button"
      button.className = "inline-flex items-center gap-1 text-left text-inherit hover:text-gray-900"
      button.dataset.columnIndex = index
      button.dataset.action = "data-table#sort"
      button.setAttribute("aria-label", `Sort by ${label} ascending`)

      const text = document.createElement("span")
      text.textContent = label

      const indicator = document.createElement("span")
      indicator.className = "text-gray-400"
      indicator.setAttribute("aria-hidden", "true")
      indicator.textContent = "↕"

      button.append(text, indicator)
      column.replaceChildren(button)
      column.setAttribute("aria-sort", "none")
      this.sortIndicators.set(index, { button, column, indicator, label })
    })
  }

  updateSortControls(activeIndex, direction) {
    this.sortIndicators.forEach(({ button, column, indicator, label }, index) => {
      const active = index === activeIndex
      const nextDirection = active && direction === "ascending" ? "descending" : "ascending"

      column.setAttribute("aria-sort", active ? direction : "none")
      indicator.textContent = active ? (direction === "ascending" ? "↑" : "↓") : "↕"
      button.setAttribute("aria-label", `Sort by ${label} ${nextDirection}`)
    })
  }

  compareValues(left, right, direction) {
    if (left.length === 0 && right.length > 0) return 1
    if (right.length === 0 && left.length > 0) return -1

    const comparison = this.collator.compare(left, right)
    return direction === "ascending" ? comparison : -comparison
  }

  setColumnVisibility(index, visible) {
    this.element.querySelectorAll("tr").forEach(row => {
      const cell = row.children[index]
      if (cell) cell.hidden = !visible
    })
  }

  loadColumnPreferences() {
    try {
      const preferences = JSON.parse(window.localStorage.getItem(this.storageKey))
      return preferences && typeof preferences === "object" && !Array.isArray(preferences) ? preferences : {}
    } catch {
      return {}
    }
  }

  saveColumnPreferences() {
    try {
      window.localStorage.setItem(this.storageKey, JSON.stringify(this.columnPreferences))
    } catch {
      // The table remains usable when storage is disabled or full.
    }
  }

  get storageKey() {
    return `pgbouncerhero:data-table:${this.queryTarget.id}`
  }
}
