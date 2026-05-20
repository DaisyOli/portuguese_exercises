import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["word", "zone", "input"]

  connect() {
    this.draggedWord = null
    this.setupDragDrop()
  }

  setupDragDrop() {
    this.wordTargets.forEach(word => {
      word.setAttribute("draggable", true)
      word.addEventListener("dragstart", this.onDragStart.bind(this))
      word.addEventListener("dragend", this.onDragEnd.bind(this))
    })

    this.zoneTargets.forEach(zone => {
      zone.addEventListener("dragover", this.onDragOver.bind(this))
      zone.addEventListener("dragleave", this.onDragLeave.bind(this))
      zone.addEventListener("drop", this.onDrop.bind(this))
    })
  }

  onDragStart(e) {
    this.draggedWord = e.currentTarget
    e.currentTarget.classList.add("dragging")
    e.dataTransfer.effectAllowed = "move"
  }

  onDragEnd(e) {
    e.currentTarget.classList.remove("dragging")
    this.zoneTargets.forEach(z => z.classList.remove("drop-hover"))
  }

  onDragOver(e) {
    e.preventDefault()
    e.dataTransfer.dropEffect = "move"
    e.currentTarget.classList.add("drop-hover")
  }

  onDragLeave(e) {
    e.currentTarget.classList.remove("drop-hover")
  }

  onDrop(e) {
    e.preventDefault()
    const targetZone = e.currentTarget
    targetZone.classList.remove("drop-hover")

    if (!this.draggedWord || targetZone === this.draggedWord.closest("[data-sentence-ordering-target='zone']")) return

    const sourceZone = this.draggedWord.closest("[data-sentence-ordering-target='zone']")
    const existingWord = targetZone.querySelector("[data-sentence-ordering-target='word']")

    // Swap if target zone already has a word
    if (existingWord && sourceZone) {
      sourceZone.appendChild(existingWord)
    }

    targetZone.appendChild(this.draggedWord)
    this.updateHiddenInput()
  }

  updateHiddenInput() {
    const orderedIds = this.zoneTargets.map(zone => {
      const word = zone.querySelector("[data-sentence-ordering-target='word']")
      return word ? word.dataset.wordId : ""
    })
    this.inputTarget.value = orderedIds.join(",")
  }
}
