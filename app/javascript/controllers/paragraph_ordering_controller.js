import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sentence", "zone", "input", "status"]

  connect() {
    this.selectedSentence = null
    this.selectedZone = null
    this.setupTapToSwap()
    this.setupKeyboardSupport()
    this.setStatus("Toque em uma frase e depois no número do lugar para posicioná-la.")
  }

  setupTapToSwap() {
    this.zoneTargets.forEach(zone => {
      zone.addEventListener("click", this.onZoneClick.bind(this))
    })
  }

  setupKeyboardSupport() {
    this.zoneTargets.forEach(zone => {
      zone.setAttribute("role", "button")
      zone.setAttribute("tabindex", "0")
      zone.addEventListener("keydown", this.onZoneKeydown.bind(this))
    })
  }

  onZoneKeydown(e) {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault()
      this.onZoneClick({ currentTarget: e.currentTarget })
    }
  }

  onZoneClick(e) {
    const clickedZone = e.currentTarget
    const clickedSentence = clickedZone.querySelector("[data-paragraph-ordering-target='sentence']")
    if (!clickedSentence) return

    if (!this.selectedSentence) {
      this.selectSentence(clickedSentence, clickedZone)
      this.setStatus("Agora toque no número do lugar para posicionar a frase.")
      return
    }

    if (this.selectedSentence === clickedSentence) {
      this.clearSelection()
      this.setStatus("Selecione uma frase para começar.")
      return
    }

    this.swapSentences(this.selectedSentence, clickedSentence)
    this.clearSelection()
    this.updateHiddenInput()
    this.setStatus("Frase posicionada! Toque em outra frase para continuar.")
  }

  selectSentence(sentence, zone) {
    this.selectedSentence = sentence
    this.selectedZone = zone
    sentence.classList.add("selected")
    zone.classList.add("selected-zone")
  }

  clearSelection() {
    if (this.selectedSentence) {
      this.selectedSentence.classList.remove("selected")
    }
    if (this.selectedZone) {
      this.selectedZone.classList.remove("selected-zone")
    }
    this.selectedSentence = null
    this.selectedZone = null
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
