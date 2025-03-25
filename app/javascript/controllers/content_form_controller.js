import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

// Adiciona log de depuração
console.log("Content Form Controller carregado")

export default class extends Controller {
  static targets = ["form"]

  connect() {
    console.log("Content Form Controller conectado", this.element)
    console.log("Formulários encontrados:", this.formTargets.length)
    
    // Inicializa o Bootstrap Collapse para cada formulário
    this.collapses = this.formTargets.map(form => {
      console.log("Inicializando collapse para", form.id)
      return new bootstrap.Collapse(form, { toggle: false })
    })
  }

  toggle(event) {
    event.preventDefault()
    const clickedButton = event.currentTarget
    const targetId = clickedButton.getAttribute("data-bs-target")
    const targetForm = document.querySelector(targetId)
    
    console.log("Toggle clicado para", targetId)
    
    // Fecha todos os outros formulários
    this.formTargets.forEach(form => {
      if (form !== targetForm && form.classList.contains("show")) {
        const collapse = bootstrap.Collapse.getInstance(form)
        if (collapse) {
          console.log("Fechando formulário", form.id)
          collapse.hide()
        } else {
          console.log("Não encontrou instância para", form.id)
          new bootstrap.Collapse(form).hide()
        }
      }
    })
    
    // Abre o formulário clicado
    const targetCollapse = bootstrap.Collapse.getInstance(targetForm)
    if (targetCollapse) {
      console.log("Alternando formulário", targetForm.id)
      targetCollapse.toggle()
    } else {
      console.log("Criando nova instância para", targetForm.id)
      new bootstrap.Collapse(targetForm).toggle()
    }
  }
} 