import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapse"
// Substitui o Collapse do Bootstrap: alterna a classe `hidden` (Tailwind)
// no elemento apontado por data-collapse-target-value.
export default class extends Controller {
  static values = { target: String }

  toggle(event) {
    event.preventDefault()
    const target = document.querySelector(this.targetValue)
    if (target) target.classList.toggle("hidden")
  }
}
