import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["radio", "pill"]

  connect() {
    this.sync()
  }

  select(event) {
    const radio = this.radioTargets.find(r => event.currentTarget.contains(r))
    if (radio) radio.checked = true
    this.sync()
  }

  sync() {
    this.pillTargets.forEach(pill => {
      const radio = this.radioTargets.find(r => pill.contains(r))
      const active = radio?.checked
      pill.style.borderColor = active ? pill.dataset.border : "var(--line)"
      pill.style.boxShadow   = active ? `0 0 0 3px ${pill.dataset.ring}` : "none"
    })
  }
}
