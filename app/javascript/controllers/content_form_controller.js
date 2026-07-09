import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  toggle(event) {
    event.preventDefault()
    event.stopPropagation()

    const targetId = event.currentTarget.getAttribute('data-collapse-target')

    if (!targetId) {
      console.error("Atributo data-collapse-target não encontrado no botão")
      return
    }

    const targetForm = document.querySelector(targetId)

    if (!targetForm) {
      console.error(`Elemento com seletor ${targetId} não encontrado`)
      return
    }

    // Comportamento de acordeão: fecha os outros formulários primeiro
    this.formTargets.forEach(form => {
      if (form !== targetForm) form.classList.add('hidden')
    })

    targetForm.classList.toggle('hidden')

    // Inicializa Quill quando o formulário fica visível
    if (!targetForm.classList.contains('hidden')) {
      setTimeout(() => {
        this._initQuillInForm(targetForm)
      }, 50)
    }
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
