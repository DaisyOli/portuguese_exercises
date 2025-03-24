// app/javascript/controllers/question_form_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "questionType",
    "contentField",
    "multipleChoiceFields",
    "fillInBlankHelp",
    "orderSentencesHelp",
    "orderSentencesFields"
  ];

  connect() {
    console.log("QuestionFormController connected!");
    console.log("Targets available:", this.targets);
    console.log("Question type target exists?", this.hasQuestionTypeTarget);
    if (this.hasQuestionTypeTarget) {
      console.log("Current question type:", this.questionTypeTarget.value);
      this.toggleFields();
    }
  }

  toggleFields() {
    console.log("toggleFields called");
    const questionType = this.questionTypeTarget.value;
    console.log("Current question type:", questionType);

    // Esconde todos os campos primeiro
    this.hideAllFields();

    // O campo de conteúdo é sempre visível
    this.contentFieldTarget.style.display = 'block';

    // Mostra os campos relevantes baseado no tipo de questão
    switch (questionType) {
      case 'multiple_choice':
        this.multipleChoiceFieldsTarget.style.display = 'block';
        break;
      case 'fill_in_blank':
        this.fillInBlankHelpTarget.style.display = 'block';
        break;
      case 'order_sentences':
        this.orderSentencesHelpTarget.style.display = 'block';
        this.orderSentencesFieldsTarget.style.display = 'block';
        break;
    }
  }

  hideAllFields() {
    // Esconde todos os campos especiais
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
