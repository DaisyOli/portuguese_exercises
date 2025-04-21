import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = true
window.Stimulus = application

// Debugging
console.log("Stimulus inicializado com sucesso!")
console.log("Modo debug:", application.debug)

// Registrar o Stimulus na janela para fácil acesso no console
window.Stimulus = application

export { application }
