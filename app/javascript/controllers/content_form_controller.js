import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    console.log("ContentFormController connected")
    
    // Não inicializa os collapses automaticamente, deixa o Bootstrap fazer isso
    console.log(`Encontrados ${this.formTargets.length} alvos de formulário`)
  }

  toggle(event) {
    event.preventDefault()
    console.log("Toggle chamado", event.currentTarget)
    
    // Usa data-bs-target no padrão Bootstrap 5
    const targetId = event.currentTarget.getAttribute('data-bs-target')
    console.log("Target ID:", targetId)
    
    if (!targetId) {
      console.error("Atributo data-bs-target não encontrado no botão")
      return
    }
    
    const targetForm = document.querySelector(targetId)
    
    if (!targetForm) {
      console.error(`Elemento com seletor ${targetId} não encontrado`)
      return
    }
    
    // Fecha todos os outros formulários primeiro
    this.formTargets.forEach(form => {
      if (form !== targetForm && form.classList.contains('show')) {
        const instance = bootstrap.Collapse.getInstance(form)
        if (instance) {
          instance.hide()
        }
      }
    })
    
    // Toggle do formulário atual usando getOrCreateInstance
    try {
      const collapse = bootstrap.Collapse.getOrCreateInstance(targetForm)
      collapse.toggle()
    } catch (error) {
      console.error("Erro ao alternar collapse:", error)
    }
  }
} 