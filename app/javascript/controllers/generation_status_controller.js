import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="generation-status"
// Página de espera da geração por IA: consulta o status e, quando a
// atividade fica pronta, leva a professora direto para a revisão do rascunho.
export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 3000 }
  }

  connect() {
    this.timer = setInterval(() => this.check(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  async check() {
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) return

      const data = await response.json()
      if (data.status === "done" && data.redirect_url) {
        clearInterval(this.timer)
        window.location.assign(data.redirect_url)
      } else if (data.status === "failed") {
        clearInterval(this.timer)
        window.location.reload() // a página renderiza o erro e o "tentar de novo"
      }
    } catch {
      // erro de rede passageiro: tenta no próximo tick
    }
  }
}
