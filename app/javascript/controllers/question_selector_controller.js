import { Controller } from "@hotwired/stimulus"

// Controlador para gerenciar a seleção de tipos de questão
export default class extends Controller {
  // Definir os targets
  static targets = ["selector", "multipleChoice", "fillInBlank", "orderSentencesHelp", "orderSentencesFields", "correctAnswer"]

  // Conectar o controlador
  connect() {
    console.log("QuestionSelectorController conectado")
    
    // Configurar a visualização inicial com base no valor atual do seletor
    this.refreshFields()
    
    // Adicionar um listener de evento como backup para o Stimulus
    if (this.hasSelectorTarget) {
      this.selectorTarget.addEventListener("change", this.handleChange.bind(this))
    }
  }
  
  // Método chamado quando o seletor muda (via Stimulus)
  change() {
    console.log("Método change chamado via Stimulus")
    this.refreshFields()
  }
  
  // Método para lidar com mudanças via event listener padrão
  handleChange(event) {
    console.log("Método handleChange chamado via listener")
    this.refreshFields()
  }
  
  // Atualiza os campos com base no tipo selecionado
  refreshFields() {
    if (!this.hasSelectorTarget) {
      console.error("Target selector não encontrado")
      return
    }
    
    const type = this.selectorTarget.value
    console.log("Tipo selecionado:", type)
    
    // Esconder todos os campos
    this.hideAllFields()
    
    // Mostrar os campos apropriados
    switch (type) {
      case "multiple_choice":
        this.showMultipleChoiceFields()
        break
      case "fill_in_blank":
        this.showFillInBlankFields()
        break
      case "order_sentences":
        this.showOrderSentencesFields()
        break
    }
  }
  
  // Esconde todos os campos específicos
  hideAllFields() {
    if (this.hasMultipleChoiceTarget) this.multipleChoiceTarget.style.display = "none"
    if (this.hasFillInBlankTarget) this.fillInBlankTarget.style.display = "none"
    if (this.hasOrderSentencesHelpTarget) this.orderSentencesHelpTarget.style.display = "none"
    if (this.hasOrderSentencesFieldsTarget) this.orderSentencesFieldsTarget.style.display = "none"
    
    // Mostrar campo de resposta por padrão
    if (this.hasCorrectAnswerTarget) this.correctAnswerTarget.style.display = "block"
  }
  
  // Mostra campos para múltipla escolha
  showMultipleChoiceFields() {
    if (this.hasMultipleChoiceTarget) this.multipleChoiceTarget.style.display = "block"
  }
  
  // Mostra campos para preencher lacunas
  showFillInBlankFields() {
    if (this.hasFillInBlankTarget) this.fillInBlankTarget.style.display = "block"
  }
  
  // Mostra campos para ordenar frases
  showOrderSentencesFields() {
    if (this.hasOrderSentencesHelpTarget) this.orderSentencesHelpTarget.style.display = "block"
    if (this.hasOrderSentencesFieldsTarget) this.orderSentencesFieldsTarget.style.display = "block"
    if (this.hasCorrectAnswerTarget) this.correctAnswerTarget.style.display = "none"
  }
} 