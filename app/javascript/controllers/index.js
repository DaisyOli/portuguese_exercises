// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "./application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// Logs antes do carregamento
console.log("Iniciando carregamento dos controladores Stimulus")

// Carregar todos os controladores
eagerLoadControllersFrom("controllers", application)

// Logs após o carregamento
console.log("Controladores Stimulus carregados com sucesso!")
console.log("Controladores registrados:", application.controllers.map(c => c.identifier))

// Verificar explicitamente o controlador question-form
setTimeout(() => {
  const controllers = application.controllers
  const hasQuestionForm = controllers.some(c => c.identifier === 'question-form')
  
  console.log(`Controlador 'question-form' ${hasQuestionForm ? 'encontrado' : 'NÃO encontrado'}!`)
  
  if (hasQuestionForm) {
    console.log("Métodos disponíveis:", 
      Object.getOwnPropertyNames(
        Object.getPrototypeOf(
          controllers.find(c => c.identifier === 'question-form').context.controller
        )
      ).filter(m => m !== 'constructor')
    )
  }
}, 1000)
