import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["columnMenu", "empty", "query", "row", "status"]
  static values = { defaultHidden: Array }

  connect() {
    this.columns = Array.from(this.element.querySelectorAll("thead th"))
    this.buildColumnMenu()
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
    const visible = event.currentTarget.checked

    this.element.querySelectorAll("tr").forEach(row => {
      const cell = row.children[index]
      if (cell) cell.hidden = !visible
    })
  }

  buildColumnMenu() {
    this.columns.forEach((column, index) => {
      if (column.dataset.columnLocked === "true") return

      const key = column.dataset.columnKey
      const checked = !this.defaultHiddenValue.includes(key)
      const label = document.createElement("label")
      label.className = "flex items-center gap-2 whitespace-nowrap"

      const checkbox = document.createElement("input")
      checkbox.type = "checkbox"
      checkbox.checked = checked
      checkbox.dataset.columnIndex = index
      checkbox.dataset.action = "data-table#toggleColumn"

      const text = document.createElement("span")
      text.textContent = column.textContent.trim()

      label.append(checkbox, text)
      this.columnMenuTarget.append(label)

      if (!checked) {
        this.element.querySelectorAll("tr").forEach(row => {
          const cell = row.children[index]
          if (cell) cell.hidden = true
        })
      }
    })
  }
}
