// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "@hotwired/stimulus"
import "@hotwired/stimulus-loading"
import "@rails/ujs"
import "bootstrap"
import "jquery"
import "jquery_ujs"

// Não importamos o Sortable aqui pois já está sendo carregado via script tag no head
// O Sortable já está disponível como window.Sortable

import "controllers"
import "@popperjs/core"

// Desabilita o Turbo para formulários específicos
document.addEventListener("turbo:load", () => {
  // Desabilita Turbo para formulários de upload e drag-and-drop
  document.querySelectorAll('form[data-turbo="false"]').forEach(form => {
    form.setAttribute("data-turbo", "false");
  });
  
  // Inicializar sortables após o carregamento da página
  if (window.Sortable) {
    console.log("Sortable disponível, inicializando listas ordenáveis...");
    document.querySelectorAll('.sortable-list').forEach(list => {
      try {
        const sortableId = list.id;
        new Sortable(list, {
          animation: 150,
          ghostClass: 'bg-light'
        });
        console.log(`Lista ${sortableId} inicializada com sucesso`);
      } catch (e) {
        console.error(`Erro ao inicializar lista sortable ${list.id}:`, e);
      }
    });
  } else {
    console.error("Sortable não está disponível globalmente!");
  }
  
  console.log("Application initialized");
})

// Adiciona um listener para depuração
document.addEventListener("turbo:before-visit", () => {
  console.log("Navegando com Turbo - fazendo cleanup");
});
