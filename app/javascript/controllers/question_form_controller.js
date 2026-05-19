// app/javascript/controllers/question_form_controller.js
import { Controller } from "@hotwired/stimulus";

// Controlador para gerenciar formulários de questões
export default class extends Controller {
  // Definir os targets que vamos usar
  static targets = [
    "questionType",
    "multipleChoiceFields",
    "fillInBlankHelp",
    "correctAnswerField"
  ];

  // Inicialização do controlador
  connect() {
    this.refreshFields();
  }

  // Método chamado quando o tipo de questão muda
  changeQuestionType() {
    this.refreshFields();
  }

  // Método para atualizar a visibilidade dos campos
  refreshFields() {
    if (!this.hasQuestionTypeTarget) {
      console.error("Alvo questionType não encontrado");
      return;
    }

    const type = this.questionTypeTarget.value;

    // Esconder todos os campos
    this.hideAllFields();

    // Mostrar campos específicos para o tipo selecionado
    if (type === "multiple_choice") {
      this.showMultipleChoiceFields();
    } else if (type === "fill_in_blank") {
      this.showFillInBlankFields();
    }
  }

  // Esconde todos os campos específicos
  hideAllFields() {
    if (this.hasMultipleChoiceFieldsTarget) {
      this.multipleChoiceFieldsTarget.style.display = "none";
    }
    
    if (this.hasFillInBlankHelpTarget) {
      this.fillInBlankHelpTarget.style.display = "none";
    }
    
    // Mostrar campo de resposta correta por padrão
    if (this.hasCorrectAnswerFieldTarget) {
      this.correctAnswerFieldTarget.style.display = "block";
    }
  }

  
  // Método para mostrar campos baseados no tipo
  showFieldsForType(type) {
    switch (type) {
      case 'multiple_choice':
        this.showMultipleChoiceFields();
        break;
        
      case 'fill_in_blank':
        this.showFillInBlankFields();
        break;
        
      default:
        console.warn("Tipo de questão desconhecido:", type);
        break;
    }
  }
  
  // Métodos auxiliares para cada tipo de questão
  showMultipleChoiceFields() {
    if (this.hasMultipleChoiceFieldsTarget) {
      this.multipleChoiceFieldsTarget.style.display = 'block';
    }
  }

  showFillInBlankFields() {
    if (this.hasFillInBlankHelpTarget) {
      this.fillInBlankHelpTarget.style.display = 'block';
    }
  }
  
  // Método para verificar e logar status dos targets
  logTargetsStatus() {
    const targets = [
      { name: "questionType", has: this.hasQuestionTypeTarget },
      { name: "contentField", has: this.hasContentFieldTarget },
      { name: "multipleChoiceFields", has: this.hasMultipleChoiceFieldsTarget },
      { name: "fillInBlankHelp", has: this.hasFillInBlankHelpTarget },
      { name: "correctAnswerField", has: this.hasCorrectAnswerFieldTarget }
    ];
    
    targets.forEach(target => {
    });
  }
  
  // Manter updateFields como alias para compatibilidade
  updateFields() {
    this.changeQuestionType();
  }
}
