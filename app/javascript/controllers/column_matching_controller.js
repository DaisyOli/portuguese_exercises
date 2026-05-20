import { Controller } from "@hotwired/stimulus"

const PAIR_COLORS = [
  { bg: '#e3f2fd', border: '#1976d2' },
  { bg: '#f3e5f5', border: '#7b1fa2' },
  { bg: '#e8f5e9', border: '#2e7d32' },
  { bg: '#fff3e0', border: '#f57c00' },
  { bg: '#fce4ec', border: '#c2185b' },
  { bg: '#e0f7fa', border: '#00838f' },
  { bg: '#fff9c4', border: '#f9a825' },
  { bg: '#ede7f6', border: '#512da8' },
]

export default class extends Controller {
  static targets = ["leftItem", "rightItem", "input"]

  connect() {
    this.selectedLeftId = null
    this.connections = {}   // { leftPairId: rightPairId }
    this.colorMap = {}      // { leftPairId: colorIndex }
    this.nextColorIndex = 0
  }

  selectLeft(event) {
    const el = event.currentTarget
    const id = el.dataset.pairId

    // Tap already-selected left → deselect
    if (this.selectedLeftId === id) {
      el.classList.remove('matching-selected')
      this.selectedLeftId = null
      return
    }

    // Deselect any previous left highlight
    this.leftItemTargets.forEach(l => l.classList.remove('matching-selected'))

    this.selectedLeftId = id
    el.classList.add('matching-selected')
  }

  selectRight(event) {
    if (!this.selectedLeftId) return

    const el = event.currentTarget
    const rightId = el.dataset.pairId

    // If this right is already connected to another left, remove that connection first
    const existingLeftId = Object.keys(this.connections).find(k => this.connections[k] === rightId)
    if (existingLeftId && existingLeftId !== this.selectedLeftId) {
      this._clearLeftConnection(existingLeftId)
    }

    // If selected left already had a connection, clear its old right partner
    if (this.connections[this.selectedLeftId]) {
      this._clearRightStyle(this.connections[this.selectedLeftId])
    }

    // Assign a color slot if this left doesn't have one yet
    if (this.colorMap[this.selectedLeftId] === undefined) {
      this.colorMap[this.selectedLeftId] = this.nextColorIndex % PAIR_COLORS.length
      this.nextColorIndex++
    }

    const color = PAIR_COLORS[this.colorMap[this.selectedLeftId]]
    this.connections[this.selectedLeftId] = rightId

    // Style left item
    const leftEl = this.leftItemTargets.find(l => l.dataset.pairId === this.selectedLeftId)
    if (leftEl) {
      leftEl.classList.remove('matching-selected')
      leftEl.classList.add('matching-connected')
      leftEl.style.backgroundColor = color.bg
      leftEl.style.borderColor = color.border
    }

    // Style right item
    el.classList.add('matching-connected')
    el.style.backgroundColor = color.bg
    el.style.borderColor = color.border

    this.selectedLeftId = null
    this._updateInput()
  }

  reset() {
    this.leftItemTargets.forEach(el => {
      el.classList.remove('matching-selected', 'matching-connected')
      el.style.backgroundColor = ''
      el.style.borderColor = ''
    })
    this.rightItemTargets.forEach(el => {
      el.classList.remove('matching-connected')
      el.style.backgroundColor = ''
      el.style.borderColor = ''
    })
    this.connections = {}
    this.colorMap = {}
    this.nextColorIndex = 0
    this.selectedLeftId = null
    this._updateInput()
  }

  _clearLeftConnection(leftId) {
    const leftEl = this.leftItemTargets.find(l => l.dataset.pairId === leftId)
    if (leftEl) {
      leftEl.classList.remove('matching-connected', 'matching-selected')
      leftEl.style.backgroundColor = ''
      leftEl.style.borderColor = ''
    }
    if (this.connections[leftId]) {
      this._clearRightStyle(this.connections[leftId])
    }
    delete this.connections[leftId]
    delete this.colorMap[leftId]
  }

  _clearRightStyle(rightId) {
    const rightEl = this.rightItemTargets.find(r => r.dataset.pairId === rightId)
    if (rightEl) {
      rightEl.classList.remove('matching-connected')
      rightEl.style.backgroundColor = ''
      rightEl.style.borderColor = ''
    }
  }

  _updateInput() {
    this.inputTarget.value = Object.entries(this.connections)
      .map(([l, r]) => `${l}:${r}`)
      .join(',')
  }
}
