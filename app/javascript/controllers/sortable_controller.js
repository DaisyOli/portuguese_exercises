import { Controller } from "@hotwired/stimulus"
// Importando Sortable como um módulo global, não como um export padrão
import "sortablejs"

export default class extends Controller {
  static targets = ["list", "input"]
  
  connect() {
    try {
      console.log("SortableController conectado para", this.listTarget.id)
      console.log("Input target disponível:", this.hasInputTarget)
      
      if (!this.hasInputTarget) {
        console.error("Target input não encontrado para o controller Sortable")
        console.log("Elementos filhos:", Array.from(this.element.children).map(el => el.outerHTML.slice(0, 50)))
        return
      }
      
      // Marca o elemento como inicializado para evitar duplicação
      this.listTarget.classList.add('sortable-initialized')
      
      // Usa a versão global do Sortable
      if (typeof window.Sortable === 'undefined') {
        console.error('Sortable não está definido. Verifique se a biblioteca foi carregada corretamente.')
        return
      }
      
      console.log(`Inicializando Sortable em ${this.listTarget.id} com input ${this.inputTarget.id}`)
      
      // Inicializa o Sortable na lista
      this.sortable = window.Sortable.create(this.listTarget, {
        animation: 150,
        handle: '.drag-handle',
        ghostClass: 'sortable-ghost',
        chosenClass: 'sortable-chosen',
        dragClass: 'sortable-drag',
        onEnd: this.updateOrder.bind(this)
      })
      
      // Inicializa o valor do campo de resposta
      this.updateOrder()
      console.log("Sortable inicializado com sucesso para", this.listTarget.id)
    } catch (error) {
      console.error("Erro ao inicializar Sortable:", error)
    }
  }
  
  disconnect() {
    if (this.sortable) {
      this.sortable.destroy()
    }
  }
  
  updateOrder() {
    try {
      if (!this.hasInputTarget) {
        console.error("Target input não disponível ao atualizar ordem")
        return
      }
      
      const items = this.listTarget.querySelectorAll('.sortable-item')
      if (items.length === 0) {
        console.warn("Não foram encontrados itens para ordenar em", this.listTarget.id)
        return
      }
      
      const values = Array.from(items).map(item => {
        const value = item.dataset.value || ''
        if (!value) {
          console.warn("Item sem valor encontrado:", item.outerHTML.slice(0, 100))
        }
        return value
      })
      
      this.inputTarget.value = values.join('|')
      console.log(`Valor atualizado: ${this.inputTarget.value}`)
    } catch (error) {
      console.error("Erro ao atualizar ordem:", error)
    }
  }
} 