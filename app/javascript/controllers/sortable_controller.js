import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "input"]
  
  connect() {
    console.log("SortableController conectando...");
    // Usar um mecanismo de debounce para evitar múltiplas inicializações
    if (this.element.dataset.sortableInitialized === "true") {
      console.log("Sortable já inicializado para este elemento, ignorando");
      return;
    }
    
    this.element.dataset.sortableInitialized = "true";
    
    try {
      console.log("SortableController conectado para", this.listTarget?.id || "lista sem ID");
      
      // Verificação mais robusta para os targets necessários
      if (!this.hasListTarget) {
        console.error("Target list não encontrado para o controller Sortable");
        return;
      }

      if (!this.hasInputTarget) {
        console.error("Target input não encontrado para o controller Sortable");
        return;
      }
      
      // Verifica se o Sortable.js está disponível, com múltiplas tentativas
      this.initSortable();
    } catch (error) {
      console.error("Erro ao inicializar SortableController:", error);
      // Permite uma nova tentativa se houver erro
      this.element.dataset.sortableInitialized = "false";
    }
  }
  
  initSortable() {
    console.log("Verificando disponibilidade do Sortable...", typeof Sortable, typeof window.Sortable);
    
    if (typeof Sortable !== 'undefined' || typeof window.Sortable !== 'undefined') {
      this.createSortableInstance();
    } else {
      console.error("Sortable não está disponível. Tentando importar novamente...");
      
      // Fazer uma última tentativa de importação dinâmica
      import("/vendor/sortable.min.js").then(module => {
        console.log("Importação dinâmica bem-sucedida:", module);
        window.Sortable = module.default || module;
        this.createSortableInstance();
      }).catch(err => {
        console.error("Erro na importação dinâmica do Sortable:", err);
        // Forçar uma nova tentativa mais tarde
        this.element.dataset.sortableInitialized = "false";
      });
    }
  }
  
  // Cria a instância do Sortable
  createSortableInstance() {
    try {
      if (!this.hasListTarget || !this.hasInputTarget || this.sortable) return;
      
      const listEl = this.listTarget;
      console.log(`Inicializando Sortable em ${listEl.id || "lista sem ID"}`);
      
      // Certifique-se de que estamos usando o objeto Sortable correto
      const SortableObj = window.Sortable || Sortable;
      
      if (!SortableObj || typeof SortableObj.create !== 'function') {
        console.error("Objeto Sortable inválido:", SortableObj);
        return;
      }
      
      // Adicionar classe para compatibilidade com o verificador no template
      listEl.classList.add('sortable-initialized');
      
      // Inicializa o Sortable com opções otimizadas para desempenho
      this.sortable = SortableObj.create(listEl, {
        animation: 150,
        handle: '.drag-handle',
        ghostClass: 'sortable-ghost',
        chosenClass: 'sortable-chosen',
        dragClass: 'sortable-drag',
        onEnd: this.updateOrder.bind(this),
        // Melhorias de desempenho
        forceFallback: false,
        fallbackTolerance: 3,
        supportPointer: true,
        delay: 100
      });
      
      // Atualizar a ordem inicial
      this.updateOrder();
      console.log("Sortable inicializado com sucesso para", listEl.id || "lista sem ID");
    } catch (error) {
      console.error("Erro ao criar instância do Sortable:", error);
      
      // Permitir uma nova tentativa
      this.element.dataset.sortableInitialized = "false";
      
      // Remover a classe para que os indicadores visuais sejam precisos
      if (this.hasListTarget) {
        this.listTarget.classList.remove('sortable-initialized');
      }
    }
  }
  
  disconnect() {
    try {
      if (this.sortable) {
        this.sortable.destroy();
        this.sortable = null;
        if (this.hasListTarget) {
          this.listTarget.classList.remove('sortable-initialized');
        }
        console.log("Instância do Sortable destruída");
      }
    } catch (error) {
      console.error("Erro ao destruir instância do Sortable:", error);
    }
  }
  
  updateOrder() {
    try {
      if (!this.hasInputTarget || !this.hasListTarget) {
        return;
      }
      
      const items = this.listTarget.querySelectorAll('.sortable-item');
      if (items.length === 0) {
        return;
      }
      
      // Otimização: usar map com verificação de valores vazios
      const values = [];
      
      items.forEach(item => {
        const value = item.dataset.value || '';
        if (value) {
          values.push(value);
        }
      });
      
      // Atualizar o campo de input apenas se tiver valores válidos
      if (values.length > 0) {
        this.inputTarget.value = values.join('|');
      }
    } catch (error) {
      console.error("Erro ao atualizar ordem:", error);
    }
  }
} 