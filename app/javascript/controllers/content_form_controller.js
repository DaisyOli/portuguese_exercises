import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static targets = ["form"]

  connect() {
  }

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    // Usa data-bs-target no padrão Bootstrap 5
    const targetId = event.currentTarget.getAttribute('data-bs-target')

    if (!targetId) {
      console.error("Atributo data-bs-target não encontrado no botão")
      return
    }

    const targetForm = document.querySelector(targetId)

    if (!targetForm) {
      console.error(`Elemento com seletor ${targetId} não encontrado`)
      return
    }

    // Fecha todos os outros formulários primeiro
    this.formTargets.forEach(form => {
      if (form !== targetForm && form.classList.contains('show')) {
        const instance = bootstrap.Collapse.getInstance(form)
        if (instance) {
          instance.hide()
        }
      }
    })

    // Toggle do formulário atual — { toggle: false } evita toggle duplo no constructor
    try {
      const collapse = bootstrap.Collapse.getOrCreateInstance(targetForm, { toggle: false })
      collapse.toggle()
    } catch (error) {
      console.error("Erro ao alternar collapse:", error)
    }

    // Inicializa Quill após a animação do collapse (350ms Bootstrap + margem)
    setTimeout(() => {
      this._initQuillInForm(targetForm)
    }, 400)
  }

  _initQuillInForm(form) {
    if (!form || form.offsetParent === null) return
    if (typeof Quill === 'undefined') return

    form.querySelectorAll('[id^="quill-editor-"]').forEach(el => {
      if (el.dataset.quillInit) return
      el.dataset.quillInit = '1'

      const quill = new Quill(el, {
        theme: 'snow',
        modules: { toolbar: [['bold', 'italic', 'underline']] }
      })

      // O hidden input é sempre o próximo irmão do div do editor
      const hiddenInput = el.nextElementSibling
      if (!hiddenInput || hiddenInput.type !== 'hidden') return

      const existing = hiddenInput.value
      if (existing && existing.trim()) {
        quill.clipboard.dangerouslyPasteHTML(
          existing.charAt(0) === '<' ? existing : existing.replace(/\n/g, '<br>')
        )
      }

      quill.on('text-change', () => { hiddenInput.value = quill.root.innerHTML })

      const formEl = el.closest('form')
      if (formEl) {
        formEl.addEventListener('submit', () => { hiddenInput.value = quill.root.innerHTML })
      }
    })
  }
}
