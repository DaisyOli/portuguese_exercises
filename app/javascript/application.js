// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@hotwired/stimulus"
import "@hotwired/stimulus-loading"
import "@rails/ujs"
import "bootstrap"
import "jquery"
import "jquery_ujs"
import "controllers"
import "@popperjs/core"
import "sortablejs"

// Log para debug
console.log("Biblioteca importadas com sucesso")

// Função principal para inicializar a aplicação
function initializeApp() {
  console.log("Iniciando a aplicação...")
  
  // Inicializa o seletor de idioma
  initLanguageSelector()
  
  // Desabilita o Turbo para formulários específicos
  document.querySelectorAll('form[data-turbo="false"]').forEach(form => {
    form.setAttribute("data-turbo", "false")
    console.log("Form com Turbo desativado:", form)
  })
  
  // Inicializa os dropdowns do Bootstrap manualmente
  initBootstrapComponents()
  
  console.log("Inicialização completa!")
}

// Inicializa os componentes do Bootstrap
function initBootstrapComponents() {
  // Inicializa todos os dropdowns
  try {
    const dropdownElementList = document.querySelectorAll('.dropdown-toggle')
    dropdownElementList.forEach(function(dropdownToggleEl) {
      new bootstrap.Dropdown(dropdownToggleEl)
      console.log("Dropdown inicializado:", dropdownToggleEl)
    })
    
    // Inicializa todos os collapses
    const collapseElementList = document.querySelectorAll('.collapse')
    collapseElementList.forEach(function(collapseEl) {
      new bootstrap.Collapse(collapseEl, {toggle: false})
      console.log("Collapse inicializado:", collapseEl)
    })
  } catch (error) {
    console.error("Erro ao inicializar componentes Bootstrap:", error)
  }
}

// Inicializa o seletor de idioma
function initLanguageSelector() {
  try {
    const languageForms = document.querySelectorAll('form[action="/update_language"]')
    languageForms.forEach(form => {
      // Garantir que os formulários de idioma não usem Turbo
      form.setAttribute("data-turbo", "false")
      console.log("Formulário de idioma configurado:", form)
    })
  } catch (error) {
    console.error("Erro ao inicializar seletor de idioma:", error)
  }
}

// Registro de eventos para garantir que a aplicação seja inicializada em todos os cenários
document.addEventListener("DOMContentLoaded", initializeApp)
document.addEventListener("turbo:load", initializeApp)
document.addEventListener("turbo:render", initializeApp)

// Inicialização imediata para casos onde os eventos já foram disparados
if (document.readyState === "complete" || document.readyState === "interactive") {
  console.log("Documento já carregado, inicializando imediatamente")
  initializeApp()
}
