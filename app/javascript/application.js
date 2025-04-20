// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@hotwired/stimulus"
import "@hotwired/stimulus-loading"
import "@rails/ujs"
import "bootstrap"
import * as jQuery from "jquery"
import "jquery_ujs"

// Define jQuery globalmente
window.jQuery = jQuery;
window.$ = jQuery;

// Não importamos o Sortable aqui pois já está sendo carregado via script tag no head
// O Sortable já está disponível como window.Sortable

import "controllers"
import "@popperjs/core"
import "./quiz_results"

// Desabilita o Turbo para formulários específicos
document.addEventListener("turbo:load", () => {
  // Desabilita Turbo para formulários de upload e drag-and-drop
  document.querySelectorAll('form[data-turbo="false"]').forEach(form => {
    form.setAttribute("data-turbo", "false");
  });
  
  console.log("Application initialized");
  console.log("jQuery disponível:", typeof jQuery !== 'undefined');
})

// Adiciona um listener para depuração
document.addEventListener("turbo:before-visit", () => {
  console.log("Navegando com Turbo - fazendo cleanup");
});
