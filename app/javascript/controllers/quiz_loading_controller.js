import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="quiz-loading"
export default class extends Controller {
  static targets = ["submit", "form", "indicator"]
  static classes = ["loading"]

  connect() {
    console.log("Quiz Loading controller connected")
  }

  // Método chamado quando o formulário é submetido
  submit(event) {
    console.log("Quiz form submission started")
    
    this.showLoading()
    this.disableForm()
    
    // Simular um pequeno delay para melhor UX visual
    setTimeout(() => {
      // O formulário continua sendo submetido normalmente
      // Só adicionamos feedback visual
    }, 100)
  }

  // Mostra o indicador de loading
  showLoading() {
    if (this.hasSubmitTarget) {
      // Salva o texto original do botão
      this.originalText = this.submitTarget.innerHTML
      
      // Atualiza o botão com spinner
      this.submitTarget.innerHTML = `
        <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
        Enviando respostas...
      `
      
      // Adiciona classe de loading se definida
      if (this.hasLoadingClass) {
        this.submitTarget.classList.add(this.loadingClass)
      }
    }

    // Mostra indicador personalizado se existir
    if (this.hasIndicatorTarget) {
      this.indicatorTarget.classList.remove('d-none')
    }
  }

  // Desabilita o formulário durante o envio
  disableForm() {
    if (this.hasFormTarget) {
      // Desabilita todos os inputs do formulário
      const inputs = this.formTarget.querySelectorAll('input, button, select, textarea')
      inputs.forEach(input => {
        input.disabled = true
      })
    }

    // Desabilita especificamente o botão de submit
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
    }
  }

  // Método para restaurar o estado original (se necessário)
  restore() {
    if (this.hasSubmitTarget && this.originalText) {
      this.submitTarget.innerHTML = this.originalText
      this.submitTarget.disabled = false
      
      if (this.hasLoadingClass) {
        this.submitTarget.classList.remove(this.loadingClass)
      }
    }

    if (this.hasIndicatorTarget) {
      this.indicatorTarget.classList.add('d-none')
    }

    if (this.hasFormTarget) {
      const inputs = this.formTarget.querySelectorAll('input, button, select, textarea')
      inputs.forEach(input => {
        input.disabled = false
      })
    }
  }

  // Cleanup quando o controller é desconectado
  disconnect() {
    console.log("Quiz Loading controller disconnected")
  }
} 