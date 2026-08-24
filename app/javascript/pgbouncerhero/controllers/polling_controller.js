import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { interval: { type: Number, default: 60000 } }
  static targets = ["status"]

  connect() {
    this.visibilityChanged = this.visibilityChanged.bind(this)
    document.addEventListener("visibilitychange", this.visibilityChanged)
    this.startPolling()
  }

  disconnect() {
    document.removeEventListener("visibilitychange", this.visibilityChanged)
    this.stopPolling()
  }

  startPolling() {
    this.stopPolling()
    if (document.hidden) return

    this.timer = setInterval(() => this.refresh(), this.intervalValue)
  }

  stopPolling() {
    if (this.timer) {
      clearInterval(this.timer)
      this.timer = null
    }
  }

  refresh() {
    if (document.hidden) return

    let refreshing = false

    this.element.querySelectorAll("turbo-frame").forEach(frame => {
      if (frame.hasAttribute("busy")) return

      if (frame.src) {
        frame.reload()
        refreshing = true
      } else if (frame.dataset.pollingRefreshUrl) {
        frame.src = frame.dataset.pollingRefreshUrl
        refreshing = true
      }
    })

    if (refreshing) this.updateStatus("Refreshing…")
  }

  refreshed() {
    const time = new Intl.DateTimeFormat([], { timeStyle: "medium" }).format(new Date())
    this.updateStatus(`Updated ${time}`)
  }

  visibilityChanged() {
    if (document.hidden) {
      this.stopPolling()
    } else {
      this.refresh()
      this.startPolling()
    }
  }

  updateStatus(message) {
    this.statusTargets.forEach(status => {
      status.textContent = message
    })
  }
}
