import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["headline", "offline", "waiting", "utilization", "group", "item"]
  static values = { total: Number }

  connect() {
    this.refresh()
  }

  refresh() {
    const healthChecks = this.itemTargets.map(item => item.querySelector("[data-fleet-health]")).filter(Boolean)
    const pending = this.totalValue - healthChecks.length
    const offline = healthChecks.filter(health => health.dataset.status === "offline").length
    const waiting = healthChecks.reduce((total, health) => total + Number(health.dataset.waitingClients), 0)
    const highUtilization = healthChecks.filter(health => health.dataset.highUtilization === "true").length
    const affected = healthChecks.filter(health => health.dataset.status !== "healthy").length

    this.offlineTarget.textContent = offline
    this.waitingTarget.textContent = waiting
    this.utilizationTarget.textContent = highUtilization

    if (pending > 0) {
      this.headlineTarget.textContent = `Checking ${healthChecks.length} of ${this.totalValue} ${this.instances()}…`
      return
    }

    this.headlineTarget.textContent = affected === 0
      ? `All ${this.totalValue} ${this.instances()} healthy`
      : `${affected} of ${this.totalValue} ${this.instances()} ${affected === 1 ? "needs" : "need"} attention`
    this.sortGroups()
  }

  instances() {
    return this.totalValue === 1 ? "instance" : "instances"
  }

  sortGroups() {
    this.groupTargets.forEach(group => {
      const items = Array.from(group.querySelectorAll(":scope > [data-fleet-target~='item']"))
      items.sort((left, right) => {
        const severityDifference = this.severity(right) - this.severity(left)
        return severityDifference || Number(left.dataset.fleetOriginalIndex) - Number(right.dataset.fleetOriginalIndex)
      })
      items.forEach(item => group.appendChild(item))
    })
  }

  severity(item) {
    return Number(item.querySelector("[data-fleet-health]")?.dataset.severity || 0)
  }
}
