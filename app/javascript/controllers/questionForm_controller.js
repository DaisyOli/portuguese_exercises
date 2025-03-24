// app/javascript/controllers/questionForm_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "questionType",
    "multipleChoiceFields",
    "fillInBlankHelp",
    "orderSentencesHelp",
    "orderSentencesFields",
    "correctAnswerField",
    "contentField"
  ];

  initialize() {
    console.log("QuestionFormController initialized");
    this.toggleFields();
  }

  connect() {
    console.log("QuestionFormController connected");
    this.toggleFields();
  }

  toggleFields() {
    console.log("toggleFields called");
    const selectedType = this.questionTypeTarget.value;
    console.log("Selected type:", selectedType);

    // Primeiro esconde todos os campos
    this.hideAllFields();

    // Depois mostra os campos específicos do tipo selecionado
    switch (selectedType) {
      case 'multiple_choice':
        this.contentFieldTarget.style.display = 'block';
        this.multipleChoiceFieldsTarget.style.display = 'block';
        this.correctAnswerFieldTarget.style.display = 'block';
        break;
      case 'fill_in_blank':
        this.contentFieldTarget.style.display = 'block';
        this.fillInBlankHelpTarget.style.display = 'block';
        this.correctAnswerFieldTarget.style.display = 'block';
        break;
      case 'order_sentences':
        this.contentFieldTarget.style.display = 'none'; // Esconde o campo de conteúdo
        this.orderSentencesHelpTarget.style.display = 'block';
        this.orderSentencesFieldsTarget.style.display = 'block';
        this.correctAnswerFieldTarget.style.display = 'none';
        break;
    }
  }

  hideAllFields() {
    // Esconde todos os campos especiais
    this.contentFieldTarget.style.display = 'none';
    this.multipleChoiceFieldsTarget.style.display = 'none';
    this.fillInBlankHelpTarget.style.display = 'none';
    this.orderSentencesHelpTarget.style.display = 'none';
    this.orderSentencesFieldsTarget.style.display = 'none';

    // Limpa os campos quando são escondidos
    if (this.multipleChoiceFieldsTarget.style.display === 'none') {
      const optionsTextarea = this.multipleChoiceFieldsTarget.querySelector('textarea');
      if (optionsTextarea) optionsTextarea.value = '';
    }

    if (this.orderSentencesFieldsTarget.style.display === 'none') {
      const contentTextarea = this.orderSentencesFieldsTarget.querySelector('textarea');
      if (contentTextarea) contentTextarea.value = '';
    }
  }

  toggleForm(event) {
    event.preventDefault();
    console.log("Toggling form visibility...");
    
    if (this.hasFormTarget) {
      this.formTarget.classList.toggle("d-none");
    }
  }
}
