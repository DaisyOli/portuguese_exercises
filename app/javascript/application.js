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

// Desabilita o Turbo para formulários específicos
document.addEventListener("turbo:load", () => {
  // Desabilita Turbo para formulários de upload e drag-and-drop
  document.querySelectorAll('form[data-turbo="false"]').forEach(form => {
    form.setAttribute("data-turbo", "false");
  });
  console.log("Application initialized")
})

// Adiciona um listener para depuração
document.addEventListener("turbo:before-visit", () => {
  console.log("Navegando com Turbo - fazendo cleanup");
});
