import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    console.log("ContentFormController connected")
    
    // Inicializa todos os collapses
    this.formTargets.forEach(form => {
      new bootstrap.Collapse(form, {
        toggle: false
      })
    })
  }

  toggle(event) {
    event.preventDefault()
    const targetId = event.currentTarget.getAttribute('data-target')
    const targetForm = document.querySelector(targetId)
    
    // Fecha todos os outros formulários primeiro
    this.formTargets.forEach(form => {
      if (form !== targetForm && form.classList.contains('show')) {
        bootstrap.Collapse.getInstance(form)?.hide()
      }
    })
    
    // Toggle do formulário atual
    bootstrap.Collapse.getOrCreateInstance(targetForm).toggle()
  }
} 