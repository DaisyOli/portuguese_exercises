import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="quiz-progress"
export default class extends Controller {
  static targets = ["bar", "counter", "question", "nextBtn", "prevBtn", "backBtn", "submitBtn", "materialPanel", "materialToggle"]
  static values = {
    total: Number,
    current: { type: Number, default: 1 }
  }

  connect() {
    this.sizeStack()
    this.boundSizeStack = this.sizeStack.bind(this)
    window.addEventListener('resize', this.boundSizeStack)
    this.updateQuestionsVisibility()
    this.updateProgress()
    this.updateNavigation()
  }

  sizeStack() {
    const outer = document.querySelector('.quiz-outer')
    const stack = this.element.querySelector('.quiz-questions-stack')
    if (!outer || !stack) return

    const navRow = this.element.querySelector('.quiz-nav-row')
    const navH = navRow
      ? navRow.offsetHeight + (parseFloat(window.getComputedStyle(navRow).marginTop) || 0)
      : 54

    const maxH = outer.getBoundingClientRect().bottom - stack.getBoundingClientRect().top - navH - 30
    if (maxH > 80) stack.style.maxHeight = maxH + 'px'
  }

  updateProgress() {
    if (this.hasBarTarget) {
      const percentage = (this.currentValue / this.totalValue) * 100
      this.barTarget.style.width = `${percentage}%`
    }

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.currentValue} de ${this.totalValue}`
    }
  }

  updateQuestionsVisibility() {
    if (this.hasQuestionTarget) {
      this.questionTargets.forEach((question, index) => {
        question.style.display = index === this.currentValue - 1 ? 'block' : 'none'
      })
    }
  }

  updateNavigation() {
    const isFirst = this.currentValue <= 1
    const isLast = this.currentValue >= this.totalValue

    if (this.hasBackBtnTarget) {
      this.backBtnTarget.style.display = isFirst ? 'flex' : 'none'
    }

    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.style.display = isFirst ? 'none' : 'flex'
    }

    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.style.display = isLast ? 'none' : 'flex'
    }

    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.style.display = isLast ? 'block' : 'none'
    }
  }

  next() {
    if (this.currentValue < this.totalValue) {
      this.currentValue++
      this.updateAll()
      this.scrollToTop()
    }
  }

  previous() {
    if (this.currentValue > 1) {
      this.currentValue--
      this.updateAll()
      this.scrollToTop()
    }
  }

  goToQuestion(event) {
    const questionNumber = parseInt(event.target.dataset.questionNumber)
    if (questionNumber >= 1 && questionNumber <= this.totalValue) {
      this.currentValue = questionNumber
      this.updateAll()
      this.scrollToTop()
    }
  }

  updateAll() {
    this.updateProgress()
    this.updateQuestionsVisibility()
    this.updateNavigation()
  }

  scrollToTop() {
    const stack = this.element.querySelector('.quiz-questions-stack')
    if (stack) stack.scrollTo({ top: 0, behavior: 'smooth' })
    else window.scrollTo({ top: 0, behavior: 'smooth' })
  }

  toggleMaterial() {
    if (this.hasMaterialPanelTarget) {
      const collapsed = this.materialPanelTarget.classList.toggle('collapsed')
      if (this.hasMaterialToggleTarget) {
        this.materialToggleTarget.textContent = collapsed
          ? '📖 Ver material ▼'
          : '📖 Ocultar material ▲'
      }
    }
  }

  handleKeydown(event) {
    if (event.key === 'ArrowRight' && !event.ctrlKey) {
      event.preventDefault()
      this.next()
    } else if (event.key === 'ArrowLeft' && !event.ctrlKey) {
      event.preventDefault()
      this.previous()
    }
  }

  disconnect() {
    window.removeEventListener('resize', this.boundSizeStack)
  }
}
