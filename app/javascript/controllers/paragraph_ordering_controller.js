import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sentence", "zone", "input"]

  connect() {
    this.draggedSentence = null
    this.setupDragDrop()
  }

  setupDragDrop() {
    this.sentenceTargets.forEach(sentence => {
      sentence.setAttribute("draggable", true)
      sentence.addEventListener("dragstart", this.onDragStart.bind(this))
      sentence.addEventListener("dragend", this.onDragEnd.bind(this))
    })

    this.zoneTargets.forEach(zone => {
      zone.addEventListener("dragover", this.onDragOver.bind(this))
      zone.addEventListener("dragleave", this.onDragLeave.bind(this))
      zone.addEventListener("drop", this.onDrop.bind(this))
    })
  }

  onDragStart(e) {
    this.draggedSentence = e.currentTarget
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

    if (!this.draggedSentence) return

    const sourceZone = this.draggedSentence.closest("[data-paragraph-ordering-target='zone']")
    if (sourceZone === targetZone) return

    const existingSentence = targetZone.querySelector("[data-paragraph-ordering-target='sentence']")
    if (existingSentence && sourceZone) {
      sourceZone.appendChild(existingSentence)
    }

    targetZone.appendChild(this.draggedSentence)
    this.updateHiddenInput()
  }

  updateHiddenInput() {
    const orderedIds = this.zoneTargets.map(zone => {
      const sentence = zone.querySelector("[data-paragraph-ordering-target='sentence']")
      return sentence ? sentence.dataset.sentenceId : ""
    })
    this.inputTarget.value = orderedIds.join(",")
  }
}
