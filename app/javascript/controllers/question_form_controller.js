// app/javascript/controllers/question_form_controller.js
import { Controller } from "@hotwired/stimulus";

// Adiciona log de depuração
console.log("Question Form Controller carregado");

export default class extends Controller {
  static targets = [
    "questionType",
    "contentField",
    "multipleChoiceFields",
    "fillInBlankHelp",
    "orderSentencesHelp",
    "orderSentencesFields",
    "correctAnswerField"
  ];

  connect() {
    console.log("QuestionFormController conectado", this.element);
    if (this.hasQuestionTypeTarget) {
      console.log("Tipo de questão encontrado:", this.questionTypeTarget.value);
    } else {
      console.log("Alvo 'questionType' não encontrado");
    }
    
    this.updateFields();
  }

  updateFields() {
    if (!this.hasQuestionTypeTarget) {
      console.log("Não há alvo questionType, retornando");
      return;
    }
    
    const type = this.questionTypeTarget.value;
    console.log("Atualizando campos para tipo:", type);
    
    // Esconder todos os campos específicos
    this.hideAllFields();
    
    // Mostrar campos baseados no tipo selecionado
    switch (type) {
      case 'multiple_choice':
        if (this.hasMultipleChoiceFieldsTarget) {
          console.log("Mostrando campos de múltipla escolha");
          this.multipleChoiceFieldsTarget.style.display = 'block';
        } else {
          console.log("Alvo multipleChoiceFields não encontrado");
        }
        break;
        
      case 'fill_in_blank':
        if (this.hasFillInBlankHelpTarget) {
          console.log("Mostrando ajuda para lacunas");
          this.fillInBlankHelpTarget.style.display = 'block';
        } else {
          console.log("Alvo fillInBlankHelp não encontrado");
        }
        break;
        
      case 'order_sentences':
        if (this.hasOrderSentencesHelpTarget) {
          console.log("Mostrando ajuda para ordenar frases");
          this.orderSentencesHelpTarget.style.display = 'block';
        } else {
          console.log("Alvo orderSentencesHelp não encontrado");
        }
        
        if (this.hasOrderSentencesFieldsTarget) {
          console.log("Mostrando campos para ordenar frases");
          this.orderSentencesFieldsTarget.style.display = 'block';
        } else {
          console.log("Alvo orderSentencesFields não encontrado");
        }
        
        if (this.hasCorrectAnswerFieldTarget) {
          console.log("Escondendo campo de resposta correta para ordenar frases");
          this.correctAnswerFieldTarget.style.display = 'none';
        } else {
          console.log("Alvo correctAnswerField não encontrado");
        }
        break;
    }
  }
  
  hideAllFields() {
    console.log("Escondendo todos os campos específicos");
    
    if (this.hasMultipleChoiceFieldsTarget) {
      this.multipleChoiceFieldsTarget.style.display = 'none';
    }
    
    if (this.hasFillInBlankHelpTarget) {
      this.fillInBlankHelpTarget.style.display = 'none';
    }
    
    if (this.hasOrderSentencesHelpTarget) {
      this.orderSentencesHelpTarget.style.display = 'none';
    }
    
    if (this.hasOrderSentencesFieldsTarget) {
      this.orderSentencesFieldsTarget.style.display = 'none';
    }
    
    // Mostrar campo de resposta correta por padrão
    if (this.hasCorrectAnswerFieldTarget) {
      this.correctAnswerFieldTarget.style.display = 'block';
    }
  }

  toggleForm(event) {
    event.preventDefault();
    console.log("Alternando visibilidade do formulário");
    
    if (this.hasFormTarget) {
      this.formTarget.classList.toggle("d-none");
      console.log("Formulário alternado");
    } else {
      console.log("Alvo form não encontrado");
    }
  }
}
