import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="collapse"
// Substitui o Collapse do Bootstrap: alterna a classe `hidden` (Tailwind) no
// elemento apontado por data-collapse-target-value. Ao revelar o alvo, dispara
// `collapse:shown` nele — substitui o antigo evento shown.bs.collapse do
// Bootstrap, do qual os editores Quill dependem para inicializar.
export default class extends Controller {
  static values = { target: String }

  toggle(event) {
    event.preventDefault()
    const target = document.querySelector(this.targetValue)
    if (!target) return
    target.classList.toggle("hidden")
    if (!target.classList.contains("hidden")) {
      target.dispatchEvent(new CustomEvent("collapse:shown"))
    }
  }
}
