import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="generation-status"
// Página de espera da geração por IA: consulta o status e, quando a
// atividade fica pronta, leva a professora direto para a revisão do rascunho.
// Enquanto espera, reveza as frasesinhas fofas no target message.
export default class extends Controller {
  static targets = ["message"]
  static values = {
    url: String,
    interval: { type: Number, default: 3000 },
    phrases: { type: Array, default: [] },
    phraseInterval: { type: Number, default: 3800 }
  }

  connect() {
    this.timer = setInterval(() => this.check(), this.intervalValue)
    this.startPhrases()
  }

  disconnect() {
    clearInterval(this.timer)
    clearInterval(this.phraseTimer)
  }

  startPhrases() {
    if (!this.hasMessageTarget || this.phrasesValue.length === 0) return

    // herda a frase que o modal do formulário estava mostrando (sem piscar);
    // se a professora chegou direto pela URL, sorteia uma
    const stored = parseInt(sessionStorage.getItem("ai-fun-phrase-idx"), 10)
    let idx = Number.isInteger(stored) && stored >= 0 && stored < this.phrasesValue.length
      ? stored
      : Math.floor(Math.random() * this.phrasesValue.length)
    this.messageTarget.textContent = this.phrasesValue[idx]

    this.phraseTimer = setInterval(() => {
      this.messageTarget.style.opacity = "0"
      setTimeout(() => {
        idx = (idx + 1) % this.phrasesValue.length
        this.messageTarget.textContent = this.phrasesValue[idx]
        this.messageTarget.style.opacity = "1"
        sessionStorage.setItem("ai-fun-phrase-idx", String(idx))
      }, 350)
    }, this.phraseIntervalValue)
  }

  async check() {
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "application/json" } })
      if (!response.ok) return

      const data = await response.json()
      if (data.status === "done" && data.redirect_url) {
        clearInterval(this.timer)
        sessionStorage.removeItem("ai-fun-phrase-idx")
        window.location.assign(data.redirect_url)
      } else if (data.status === "failed") {
        clearInterval(this.timer)
        sessionStorage.removeItem("ai-fun-phrase-idx")
        window.location.reload() // a página renderiza o erro e o "tentar de novo"
      }
    } catch {
      // erro de rede passageiro: tenta no próximo tick
    }
  }
}
