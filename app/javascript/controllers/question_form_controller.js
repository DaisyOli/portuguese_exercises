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
    console.log("QuestionFormController conectado");
    this.refreshFields();
  }

  // Método chamado quando o tipo de questão muda
  changeQuestionType() {
    console.log("Método changeQuestionType chamado");
    this.refreshFields();
  }

  // Método para atualizar a visibilidade dos campos
  refreshFields() {
    if (!this.hasQuestionTypeTarget) {
      console.error("Alvo questionType não encontrado");
      return;
    }

    const type = this.questionTypeTarget.value;
    console.log("Tipo de questão:", type);

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
    console.log("Mostrando campos para tipo:", type);
    
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
      console.log("Mostrando campos de múltipla escolha");
      this.multipleChoiceFieldsTarget.style.display = 'block';
    } else {
      console.error("Alvo multipleChoiceFields não encontrado");
    }
  }
  
  showFillInBlankFields() {
    if (this.hasFillInBlankHelpTarget) {
      console.log("Mostrando ajuda para lacunas");
      this.fillInBlankHelpTarget.style.display = 'block';
    } else {
      console.error("Alvo fillInBlankHelp não encontrado");
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
    
    console.log("Status dos targets:", targets);
    
    // Debug adicional - verificar elementos no DOM
    targets.forEach(target => {
      if (!target.has) {
        const elements = document.querySelectorAll(`[data-question-form-target="${target.name}"]`);
        console.log(`Elementos para target ${target.name} no DOM:`, elements.length);
      }
    });
  }
  
  // Manter updateFields como alias para compatibilidade
  updateFields() {
    console.log("Método updateFields chamado (alias)");
    this.changeQuestionType();
  }
}
