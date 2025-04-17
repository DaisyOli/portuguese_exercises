import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "input"]
  
  connect() {
    console.log("SortableController conectando...");
    
    // Inicialização simplificada após 100ms para garantir que DOM está pronto
    setTimeout(() => {
      this.initSortable();
    }, 100);
  }
  
  initSortable() {
    try {
      console.log(`Inicializando Sortable para ${this.listTarget?.id || "lista sem ID"}`);
      
      // Verificação básica para os targets
      if (!this.hasListTarget || !this.hasInputTarget) {
        console.error("Targets necessários não encontrados para Sortable");
        return;
      }
      
      // Usar o objeto Sortable global diretamente
      if (typeof window.Sortable !== 'function') {
        console.error("Sortable não disponível como função global. Valor atual:", window.Sortable);
        return;
      }
      
      // Inicializar Sortable diretamente
      const listEl = this.listTarget;
      
      // Destruir instância existente se houver
      try {
        const existingInstance = window.Sortable.get(listEl);
        if (existingInstance) {
          existingInstance.destroy();
          console.log("Instância anterior do Sortable destruída");
        }
      } catch (e) {
        console.log("Nenhuma instância prévia para destruir");
      }
      
      // Criar nova instância
      this.sortable = window.Sortable.create(listEl, {
        animation: 150,
        handle: '.drag-handle',
        ghostClass: 'sortable-ghost',
        chosenClass: 'sortable-chosen',
        dragClass: 'sortable-drag',
        onEnd: this.updateOrder.bind(this)
      });
      
      // Marcar como inicializado
      listEl.classList.add('sortable-initialized');
      
      // Atualizar ordem inicial
      this.updateOrder();
      console.log("Sortable inicializado com sucesso para", listEl.id);
    } catch (error) {
      console.error("Erro ao inicializar Sortable:", error);
      
      if (this.hasListTarget) {
        // Mostrar botão de reinicialização
        const btn = this.element.querySelector('.reinit-sortable-btn');
        if (btn) btn.style.display = 'block';
        
        // Remover classe para indicar erro
        this.listTarget.classList.remove('sortable-initialized');
      }
    }
  }
  
  disconnect() {
    try {
      if (this.sortable) {
        this.sortable.destroy();
        this.sortable = null;
        console.log("Instância do Sortable destruída");
      }
    } catch (error) {
      console.error("Erro ao destruir Sortable:", error);
    }
  }
  
  updateOrder() {
    try {
      if (!this.hasInputTarget || !this.hasListTarget) return;
      
      const items = this.listTarget.querySelectorAll('.sortable-item');
      if (items.length === 0) return;
      
      const values = Array.from(items).map(item => item.dataset.value || '').filter(Boolean);
      
      if (values.length > 0) {
        this.inputTarget.value = values.join('|');
        console.log("Ordem atualizada:", this.inputTarget.value);
      }
    } catch (error) {
      console.error("Erro ao atualizar ordem:", error);
    }
  }
} 