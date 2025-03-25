// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "./application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Logs para debug
console.log("Registrando controladores Stimulus...")

// Carregamento explícito dos controladores
import ContentFormController from "./content_form_controller"
import QuestionFormController from "./question_form_controller"
import HelloController from "./hello_controller"

// Registro manual dos controladores
application.register("content-form", ContentFormController)
application.register("question-form", QuestionFormController)
application.register("hello", HelloController)

// Carregamento extra para garantir que todos os controladores sejam encontrados
eagerLoadControllersFrom("controllers", application)

// Logs para debug final
console.log("Controllers registrados:", application.controllers.map(c => c.identifier))
