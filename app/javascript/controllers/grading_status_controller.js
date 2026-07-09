import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="grading-status"
// Consulta o servidor a cada poucos segundos enquanto a correção por IA
// está em andamento; quando termina, recarrega a página de resultados.
export default class extends Controller {
  static values = {
    url: String,
    interval: { type: Number, default: 4000 },
    maxChecks: { type: Number, default: 45 }
  }

  connect() {
    this.checks = 0
    this.timer = setInterval(() => this.check(), this.intervalValue)
  }

  disconnect() {
    clearInterval(this.timer)
  }

  async check() {
    this.checks++
    if (this.checks > this.maxChecksValue) {
      clearInterval(this.timer)
      return
    }

    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) return

      const data = await response.json()
      if (!data.pending) {
        clearInterval(this.timer)
        window.location.reload()
      }
    } catch {
      // erro de rede passageiro: tenta de novo no próximo tick
    }
  }
}
