// app/javascript/controllers/question_form_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form"]; // Certifique-se de que "statement" está correto

  connect() {
    console.log("Connected to question-form controller");
    console.log("Form target:", this.formTarget);
  }

  toggleForm(event) {
    event.preventDefault(); // Evita a navegação padrão do link ou botão
    console.log("Toggling form visibility...");

    // Adiciona ou remove a classe d-none do formulário
    this.formTarget.classList.toggle("d-none");
  }
}
