// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@hotwired/stimulus"
import "@hotwired/stimulus-loading"
import "@rails/ujs"
import "bootstrap"

// Não importamos jQuery via importmap, pois já está no layout como tag script

// Garante que o jQuery está carregado
document.addEventListener('DOMContentLoaded', function() {
  if (typeof window.jQuery === 'undefined') {
    console.error('jQuery não foi carregado pela tag script');
  }
});

// Não importamos o Sortable aqui pois já está sendo carregado via script tag no head
// O Sortable já está disponível como window.Sortable

import "controllers"
import "@popperjs/core"
import "./quiz_results"
import "./student_dashboard"

// Desabilita o Turbo para formulários específicos
document.addEventListener("turbo:load", () => {
  // Desabilita Turbo para formulários de upload e drag-and-drop
  document.querySelectorAll('form[data-turbo="false"]').forEach(form => {
    form.setAttribute("data-turbo", "false");
  });
})
