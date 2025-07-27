import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="quiz-progress"
export default class extends Controller {
  static targets = ["bar", "counter", "question", "nextBtn", "prevBtn"]
  static values = { 
    total: Number,
    current: { type: Number, default: 1 }
  }

  connect() {
    console.log("Quiz Progress controller connected")
    this.updateProgress()
    this.updateNavigation()
  }

  // Atualiza a barra de progresso
  updateProgress() {
    if (this.hasBarTarget) {
      const percentage = (this.currentValue / this.totalValue) * 100
      this.barTarget.style.width = `${percentage}%`
      this.barTarget.setAttribute('aria-valuenow', this.currentValue)
      this.barTarget.setAttribute('aria-valuemax', this.totalValue)
    }

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${this.currentValue} de ${this.totalValue}`
    }
  }

  // Atualiza a visibilidade das questões
  updateQuestionsVisibility() {
    if (this.hasQuestionTarget) {
      this.questionTargets.forEach((question, index) => {
        if (index === this.currentValue - 1) {
          question.classList.remove('d-none')
          question.classList.add('question-active')
        } else {
          question.classList.add('d-none')
          question.classList.remove('question-active')
        }
      })
    }
  }

  // Atualiza estado dos botões de navegação
  updateNavigation() {
    if (this.hasPrevBtnTarget) {
      this.prevBtnTarget.disabled = this.currentValue <= 1
    }

    if (this.hasNextBtnTarget) {
      this.nextBtnTarget.disabled = this.currentValue >= this.totalValue
      
      // Muda texto do botão na última questão
      if (this.currentValue >= this.totalValue) {
        this.nextBtnTarget.innerHTML = '<i class="fas fa-check me-2"></i>Finalizar Quiz'
        this.nextBtnTarget.classList.remove('btn-primary')
        this.nextBtnTarget.classList.add('btn-success')
      } else {
        this.nextBtnTarget.innerHTML = '<i class="fas fa-arrow-right me-2"></i>Próxima'
        this.nextBtnTarget.classList.remove('btn-success')
        this.nextBtnTarget.classList.add('btn-primary')
      }
    }
  }

  // Navega para próxima questão
  next() {
    if (this.currentValue < this.totalValue) {
      this.currentValue++
      this.updateAll()
      this.scrollToTop()
    }
  }

  // Navega para questão anterior
  previous() {
    if (this.currentValue > 1) {
      this.currentValue--
      this.updateAll()
      this.scrollToTop()
    }
  }

  // Vai para uma questão específica
  goToQuestion(event) {
    const questionNumber = parseInt(event.target.dataset.questionNumber)
    if (questionNumber >= 1 && questionNumber <= this.totalValue) {
      this.currentValue = questionNumber
      this.updateAll()
      this.scrollToTop()
    }
  }

  // Atualiza todos os elementos visuais
  updateAll() {
    this.updateProgress()
    this.updateQuestionsVisibility()
    this.updateNavigation()
    this.animateProgress()
  }

  // Animação suave da barra de progresso
  animateProgress() {
    if (this.hasBarTarget) {
      this.barTarget.style.transition = 'width 0.3s ease-in-out'
    }
  }

  // Scroll suave para o topo
  scrollToTop() {
    window.scrollTo({
      top: 0,
      behavior: 'smooth'
    })
  }

  // Valida se a questão atual foi respondida
  isCurrentQuestionAnswered() {
    const currentQuestion = this.questionTargets[this.currentValue - 1]
    if (!currentQuestion) return false

    // Verifica inputs de texto
    const textInputs = currentQuestion.querySelectorAll('input[type="text"]')
    for (let input of textInputs) {
      if (input.value.trim() === '') return false
    }

    // Verifica radio buttons
    const radioGroups = currentQuestion.querySelectorAll('input[type="radio"]')
    if (radioGroups.length > 0) {
      const radioGroupNames = [...new Set(Array.from(radioGroups).map(r => r.name))]
      for (let groupName of radioGroupNames) {
        const checked = currentQuestion.querySelector(`input[name="${groupName}"]:checked`)
        if (!checked) return false
      }
    }

    return true
  }

  // Navegação com validação
  nextWithValidation() {
    if (!this.isCurrentQuestionAnswered()) {
      // Dispara evento para mostrar toast de validação
      const event = new CustomEvent('quiz:validation-error', {
        detail: { message: 'Por favor, responda a questão atual antes de continuar.' }
      })
      document.dispatchEvent(event)
      return
    }

    this.next()
  }

  // Métodos para eventos de teclado
  handleKeydown(event) {
    if (event.key === 'ArrowRight' && !event.ctrlKey) {
      event.preventDefault()
      this.nextWithValidation()
    } else if (event.key === 'ArrowLeft' && !event.ctrlKey) {
      event.preventDefault()
      this.previous()
    }
  }

  // Calcula estatísticas de progresso
  getProgressStats() {
    const answered = this.getAnsweredQuestionsCount()
    const percentage = Math.round((answered / this.totalValue) * 100)
    
    return {
      total: this.totalValue,
      current: this.currentValue,
      answered: answered,
      remaining: this.totalValue - answered,
      percentage: percentage
    }
  }

  // Conta quantas questões foram respondidas
  getAnsweredQuestionsCount() {
    let answered = 0
    this.questionTargets.forEach((question, index) => {
      const textInputs = question.querySelectorAll('input[type="text"]')
      const radioButtons = question.querySelectorAll('input[type="radio"]:checked')
      
      if (textInputs.length > 0) {
        const allFilled = Array.from(textInputs).every(input => input.value.trim() !== '')
        if (allFilled) answered++
      } else if (radioButtons.length > 0) {
        answered++
      }
    })
    return answered
  }

  disconnect() {
    console.log("Quiz Progress controller disconnected")
  }
} 