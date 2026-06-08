import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["word", "zone", "input", "status"]

  connect() {
    this.selectedWord = null
    this.setupTapToSwap()
    this.setupKeyboardSupport()
    this.setStatus("Toque em uma palavra e depois clique em outra para trocá-la.")
  }

  setupTapToSwap() {
    this.wordTargets.forEach(word => {
      word.addEventListener("click", this.onWordClick.bind(this))
    })
  }

  setupKeyboardSupport() {
    this.wordTargets.forEach(word => {
      word.setAttribute("role", "button")
      word.setAttribute("tabindex", "0")
      word.addEventListener("keydown", this.onWordKeydown.bind(this))
    })
  }

  onWordKeydown(e) {
    if (e.key === "Enter" || e.key === " ") {
      e.preventDefault()
      this.onWordClick(e)
    }
  }

  onWordClick(e) {
    e.stopPropagation()
    e.currentTarget.blur()
    const clickedWord = e.currentTarget
    const clickedZone = clickedWord.closest("[data-sentence-ordering-target='zone']")
    if (!clickedZone) return

    if (!this.selectedWord) {
      this.selectWord(clickedWord)
      this.setStatus("Agora clique em outra palavra para trocar de lugar.")
      return
    }

    if (this.selectedWord === clickedWord) {
      this.clearSelection()
      this.setStatus("Selecione uma palavra para começar.")
      return
    }

    this.swapWords(this.selectedWord, clickedWord)
    this.updateHiddenInput()
    this.clearSelection()
    setTimeout(() => document.activeElement?.blur(), 0)
    this.setStatus("Palavra posicionada! Toque em outra palavra para continuar.")
  }

  selectWord(word) {
    this.selectedWord = word
    this.selectedWord.classList.add("selected")
  }

  clearSelection() {
    this.wordTargets.forEach(word => word.classList.remove("selected"))
    this.selectedWord = null
  }

  swapWords(wordA, wordB) {
    const zoneA = wordA.parentElement
    const zoneB = wordB.parentElement
    if (!zoneA || !zoneB || zoneA === zoneB) return
    zoneA.appendChild(wordB)
    zoneB.appendChild(wordA)
  }

  setStatus(message) {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message
    }
  }

  updateHiddenInput() {
    const orderedIds = this.zoneTargets.map(zone => {
      const word = zone.querySelector("[data-sentence-ordering-target='word']")
      return word ? word.dataset.wordId : ""
    })
    this.inputTarget.value = orderedIds.join(",")
  }
}
