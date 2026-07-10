import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="quiz-loading"
export default class extends Controller {
  static targets = ["submit", "indicator"]
  static classes = ["loading"]

  connect() {
  }

  submit(event) {
    this.showLoading()
    this.disableForm()
  }

  showLoading() {
    if (this.hasSubmitTarget) {
      this.originalText = this.submitTarget.innerHTML
      this.submitTarget.innerHTML = `
        <span style="display:inline-block;width:14px;height:14px;border:2px solid rgba(255,255,255,0.4);border-top-color:var(--surface);border-radius:50%;animation:spin 0.7s linear infinite;margin-right:8px;vertical-align:middle;"></span>
        Enviando respostas...
      `
      if (this.hasLoadingClass) {
        this.submitTarget.classList.add(this.loadingClass)
      }
    }

    if (this.hasIndicatorTarget) {
      this.indicatorTarget.style.display = 'block'
    }
  }

  disableForm() {
    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = true
    }
  }

  restore() {
    if (this.hasSubmitTarget && this.originalText) {
      this.submitTarget.innerHTML = this.originalText
      this.submitTarget.disabled = false
      if (this.hasLoadingClass) {
        this.submitTarget.classList.remove(this.loadingClass)
      }
    }

    if (this.hasIndicatorTarget) {
      this.indicatorTarget.style.display = 'none'
    }

    const inputs = this.element.querySelectorAll('button')
    inputs.forEach(input => { input.disabled = false })
  }

  disconnect() {
  }
}
