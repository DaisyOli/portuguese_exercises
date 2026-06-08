import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sentence", "zone", "input", "status"]

  connect() {
    this.selectedSentence = null
    this.setupTapToSwap()
    this.setupKeyboardSupport()
    this.setStatus("Toque em uma frase e depois em outra para trocá-las de lugar.")
  }

  setupTapToSwap() {
    this.sentenceTargets.forEach(sentence => {
      sentence.addEventListener("click", this.onSentenceClick.bind(this))
    })
  }

  setupKeyboardSupport() {
    this.sentenceTargets.forEach(sentence => {
      sentence.setAttribute("role", "button")
      sentence.setAttribute("tabindex", "0")
      sentence.addEventListener("keydown", this.onSentenceKeydown.bind(this))
    })
  }

  onSentenceKeydown(e) {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault()
      this.onSentenceClick(e)
    }
  }

  onSentenceClick(e) {
    e.stopPropagation()
    e.currentTarget.blur()
    const clickedSentence = e.currentTarget

    if (!this.selectedSentence) {
      this.selectSentence(clickedSentence)
      this.setStatus("Agora toque em outra frase para trocá-la de lugar.")
      return
    }

    if (this.selectedSentence === clickedSentence) {
      this.clearSelection()
      this.setStatus("Selecione uma frase para começar.")
      return
    }

    this.swapSentences(this.selectedSentence, clickedSentence)
    this.updateHiddenInput()
    this.clearSelection()
    setTimeout(() => document.activeElement?.blur(), 0)
    this.setStatus("Frase posicionada! Toque em outra frase para continuar.")
  }

  selectSentence(sentence) {
    this.selectedSentence = sentence
    sentence.classList.add("selected")
  }

  clearSelection() {
    this.sentenceTargets.forEach(s => s.classList.remove("selected"))
    this.selectedSentence = null
  }

  swapSentences(sentA, sentB) {
    const zoneA = sentA.parentElement
    const zoneB = sentB.parentElement
    if (!zoneA || !zoneB || zoneA === zoneB) return
    zoneA.appendChild(sentB)
    zoneB.appendChild(sentA)
  }

  setStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
  }

  updateHiddenInput() {
    const orderedIds = this.zoneTargets.map(zone => {
      const sentence = zone.querySelector("[data-paragraph-ordering-target='sentence']")
      return sentence ? sentence.dataset.sentenceId : ""
    })
    this.inputTarget.value = orderedIds.join(",")
  }
}
