// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@hotwired/stimulus"
import "@hotwired/stimulus-loading"
import "@rails/ujs"
import "bootstrap"

// Não importamos jQuery via importmap, pois já está no layout como tag script
console.log('Importmap: Verificando jQuery...');

// Garante que o jQuery está carregado
document.addEventListener('DOMContentLoaded', function() {
  // Verifica se o jQuery já está disponível (carregado via script tag)
  if (typeof window.jQuery === 'undefined') {
    console.error('jQuery não foi carregado pela tag script');
    // Não tentamos carregá-lo aqui novamente, já que há um fallback no layout
  } else {
    console.log('jQuery já está disponível via tag script');
    
    // NÃO carregamos jquery_ujs aqui, para evitar duplicação
    console.log('Não importando jquery_ujs para evitar carregamento duplo');
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
  
  console.log("Application initialized");
  console.log("jQuery disponível:", typeof jQuery !== 'undefined');
})

// Adiciona um listener para depuração
document.addEventListener("turbo:before-visit", () => {
  console.log("Navegando com Turbo - fazendo cleanup");
});
