import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "template"]

  addField(e) {
    e.preventDefault()
    const index = Date.now()
    const html = this.templateTarget.innerHTML.replace(/FIELD_INDEX/g, index)
    this.listTarget.insertAdjacentHTML("beforeend", html)
    this.listTarget.lastElementChild.querySelector("input, textarea")?.focus()
  }

  removeField(e) {
    e.preventDefault()
    e.currentTarget.closest("[data-field]").remove()
  }
}
