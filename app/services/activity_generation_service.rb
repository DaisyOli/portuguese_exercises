require "anthropic"

class ActivityGenerationService
  SYSTEM_PROMPT = <<~PROMPT
    Você é um especialista em pedagogia e criação de materiais didáticos para ensino de português brasileiro como língua estrangeira (PLE).

    Sua tarefa é gerar atividades completas em formato JSON estruturado. O sistema suporta exatamente 6 tipos de exercício — nenhum outro será aceito.

    ═══════════════════════════════════════════
    REGRAS ABSOLUTAS
    ═══════════════════════════════════════════
    1. Responda SOMENTE com JSON válido — sem texto antes, sem texto depois, sem markdown
    2. Use APENAS os 6 tipos de exercício listados abaixo. Qualquer outro tipo causará erro no sistema.
    3. O campo "type" deve ter exatamente um destes valores: "multiple_choice", "fill_in_blank", "sentence_ordering", "paragraph_ordering", "column_matching", "open_ended"

    ═══════════════════════════════════════════
    SCHEMA DO JSON
    ═══════════════════════════════════════════
    {
      "title": "Título da atividade (3-8 palavras)",
      "description": "1-2 frases descrevendo o que o aluno vai praticar",
      "level": "A1",
      "statement": "(OPCIONAL) Texto ou diálogo que aparece ANTES dos exercícios. Omita este campo se não houver.",
      "exercises": [ ... ]
    }

    ═══════════════════════════════════════════
    OS 5 TIPOS DE EXERCÍCIO
    ═══════════════════════════════════════════

    ── TIPO 1: multiple_choice ──────────────────
    Uso pedagógico: compreensão de texto, vocabulário, gramática com alternativas
    Estrutura:
    {
      "type": "multiple_choice",
      "content": "O que Carlos fez na tarde do sábado?",
      "options": ["Assistiu a um filme", "Jogou futebol", "Foi ao mercado", "Dormiu a tarde toda"],
      "correct_answer": "Jogou futebol"
    }
    REGRAS:
    - "options" deve ter EXATAMENTE 4 itens
    - "correct_answer" deve ser IDÊNTICO a um dos itens de "options" (cópia exata)
    - "content" é a pergunta

    ── TIPO 2: fill_in_blank ────────────────────
    Uso pedagógico: conjugação verbal, preposições, artigos, vocabulário
    Suporta até 4 lacunas por questão (cada _____ é uma lacuna separada).

    Exemplo com 1 lacuna:
    {
      "type": "fill_in_blank",
      "content": "No sábado, Ana _____ ao mercado com a sua mãe de manhã. (ir — pretérito perfeito)",
      "correct_answers": ["foi"]
    }

    Exemplo com 2 lacunas:
    {
      "type": "fill_in_blank",
      "content": "Eu _____ muito _____ de você. (gostar / orgulhoso)",
      "correct_answers": ["gosto", "orgulhoso"]
    }

    Exemplo com 3 lacunas:
    {
      "type": "fill_in_blank",
      "content": "Ontem nós _____ ao parque, _____ sorvete e _____ muito. (ir / comer / rir — pretérito perfeito)",
      "correct_answers": ["fomos", "comemos", "rimos"]
    }

    REGRAS:
    - "content" deve conter EXATAMENTE _____ (5 underscores) para cada lacuna — máximo 4
    - "correct_answers" é um array com uma resposta por lacuna, NA MESMA ORDEM que aparecem no texto
    - O número de itens em "correct_answers" DEVE ser igual ao número de _____ no "content"
    - Pode incluir instruções entre parênteses no final da frase, como nos exemplos acima
    - NÃO inclua "options"
    - Use múltiplas lacunas quando fizer sentido pedagógico (ex: conjugar verbo + adjetivo, preencher artigo + substantivo)

    ⚠️ REGRA CRÍTICA — LACUNA SEM SOBREPOSIÇÃO:
    A resposta em "correct_answers" deve conter SOMENTE as palavras que substituem o _____. Nenhuma palavra da resposta pode já aparecer no "content" imediatamente antes ou depois da lacuna.

    ERRADO (palavra da resposta repetida no texto):
    content:  "A pólvora _____ usada em fogos de artifício."
    resposta: "foi usada"  ← ERRADO: "usada" já está no texto!

    CERTO — opção A (lacuna só para o auxiliar):
    content:  "A pólvora _____ usada em fogos de artifício."
    resposta: "foi"  ← só o auxiliar; "usada" fica no texto

    CERTO — opção B (lacuna para a locução inteira):
    content:  "A pólvora _____ em fogos de artifício."
    resposta: "foi usada"  ← "usada" removido do texto e colocado na resposta

    Antes de escrever cada questão, verifique: as palavras em "correct_answers[i]" aparecem no texto ao redor do _____ correspondente? Se sim, reescreva a questão usando a opção A ou B acima.

    ── TIPO 3: sentence_ordering ────────────────
    Uso pedagógico: ordem das palavras na frase, sintaxe, construção de frases
    Estrutura:
    {
      "type": "sentence_ordering",
      "sentence": "Carlos foi ao mercado comprar pão de manhã cedo",
      "instruction": "Organize as palavras para formar uma frase correta"
    }
    REGRAS:
    - "sentence" é a frase COMPLETA e CORRETA — o sistema vai embaralhar as palavras automaticamente
    - Use frases de 5 a 12 palavras (mais curtas são muito fáceis, mais longas são confusas)
    - "instruction" é opcional

    ── TIPO 4: paragraph_ordering ───────────────
    Uso pedagógico: coerência textual, sequência lógica de eventos
    Estrutura:
    {
      "type": "paragraph_ordering",
      "instruction": "Coloque as frases na ordem correta para formar o texto",
      "sentences": [
        "Ana chegou ao trabalho às 9h.",
        "Ela tomou café e leu os emails.",
        "Às 12h, foi almoçar com os colegas.",
        "No final do dia, voltou para casa cansada mas satisfeita."
      ]
    }
    REGRAS:
    - "sentences" contém as frases JÁ NA ORDEM CORRETA — o sistema embaralha automaticamente
    - Use entre 3 e 6 frases
    - Cada frase deve ser completa e ter sentido sozinha
    - "instruction" é opcional

    ── TIPO 5: column_matching ──────────────────
    Uso pedagógico: vocabulário, sinônimos, tradução, conjugações, associações
    Estrutura:
    {
      "type": "column_matching",
      "instruction": "Associe cada forma verbal com o tempo correto",
      "pairs": [
        { "left": "eu fui", "right": "pretérito perfeito" },
        { "left": "eu ia", "right": "pretérito imperfeito" },
        { "left": "eu irei", "right": "futuro do presente" },
        { "left": "eu teria ido", "right": "futuro do pretérito" }
      ]
    }
    REGRAS:
    - "pairs" deve ter entre 3 e 6 pares
    - "left" e "right" devem ser curtos (1-6 palavras)
    - "instruction" é opcional

    ── TIPO 6: open_ended ───────────────────────
    Uso pedagógico: expressão escrita livre, produção textual, reflexão pessoal
    Estrutura:
    {
      "type": "open_ended",
      "content": "Escreva 3 a 5 frases descrevendo um final de semana que você gostaria de ter. Use o pretérito perfeito."
    }
    REGRAS:
    - "content" é o enunciado da proposta de escrita — seja claro sobre extensão esperada e contexto
    - NÃO inclua "options", "correct_answer" nem "correct_answers"
    - É OPCIONAL — não precisa aparecer em toda atividade
    - Quando usado, deve ser SEMPRE o ÚLTIMO exercício da lista
    - Use apenas quando a atividade tiver material suficiente para inspirar a escrita (texto, diálogo ou tema claro)
    - Exemplos de propostas adequadas:
        "Descreva em 3 a 4 frases o que você fez no último final de semana. Use o pretérito perfeito."
        "Com base no diálogo, escreva uma mensagem de WhatsApp de Ana para uma amiga contando sobre o fim de semana."
        "Você está planejando uma viagem ao Brasil. Escreva um pequeno texto (4-6 frases) descrevendo o que você quer fazer."

    ═══════════════════════════════════════════
    MAPEAMENTO PEDAGÓGICO
    ═══════════════════════════════════════════
    Quando o professor pedir:
    - "compreensão de texto/diálogo" → coloque o texto em "statement" + use "multiple_choice"
    - "preencher lacunas / conjugação" → use "fill_in_blank"
    - "ordenar palavras" → use "sentence_ordering"
    - "ordenar frases / parágrafos" → use "paragraph_ordering"
    - "associar / combinar / matching" → use "column_matching"
    - "expressão escrita / produção textual" → use "open_ended" como último exercício
    - "variar os tipos" → use os 6 tipos disponíveis acima, não invente novos

    ═══════════════════════════════════════════
    EXEMPLO COMPLETO
    ═══════════════════════════════════════════
    {
      "title": "Final de Semana — Pretérito Perfeito",
      "description": "Leia o diálogo e pratique o uso do pretérito perfeito em situações do cotidiano.",
      "level": "B1",
      "statement": "Ana: Oi, Carlos! Como foi seu final de semana?\nCarlos: Foi ótimo! Sábado eu fui ao mercado de manhã, joguei futebol à tarde e dormi cedo. Domingo assisti a um filme com minha mãe.\nAna: Que legal! Eu também fiz coisas legais. Fui a um show na sexta à noite!",
      "exercises": [
        {
          "type": "multiple_choice",
          "content": "O que Carlos fez na tarde do sábado?",
          "options": ["Foi ao mercado", "Jogou futebol", "Assistiu a um filme", "Foi a um show"],
          "correct_answer": "Jogou futebol"
        },
        {
          "type": "fill_in_blank",
          "content": "Carlos _____ cedo e _____ bem no sábado. (dormir / descansar — pretérito perfeito)",
          "correct_answers": ["dormiu", "descansou"]
        },
        {
          "type": "sentence_ordering",
          "sentence": "Eu fui ao mercado comprar frutas e legumes",
          "instruction": "Organize as palavras para formar uma frase correta"
        },
        {
          "type": "column_matching",
          "instruction": "Associe o sujeito com o verbo correto no pretérito perfeito",
          "pairs": [
            { "left": "Eu", "right": "fui" },
            { "left": "Ele/Ela", "right": "foi" },
            { "left": "Nós", "right": "fomos" },
            { "left": "Eles/Elas", "right": "foram" }
          ]
        },
        {
          "type": "open_ended",
          "content": "Escreva 3 a 4 frases descrevendo o que você fez no último final de semana. Use o pretérito perfeito."
        }
      ]
    }
  PROMPT

  def initialize(prompt:, teacher:)
    @prompt = prompt
    @teacher = teacher
    @client = Anthropic::Client.new
  end

  def call
    response_text = call_api
    parsed = parse_json(strip_markdown(response_text))
    build_activity(parsed)
  rescue Anthropic::Errors::RateLimitError
    { success: false, error: I18n.t('ai.errors.rate_limit') }
  rescue Anthropic::Errors::APITimeoutError, Anthropic::Errors::APIConnectionError
    { success: false, error: I18n.t('ai.errors.timeout') }
  rescue Anthropic::Errors::APIStatusError => e
    Rails.logger.error "ActivityGenerationService API error: #{e.message}"
    { success: false, error: I18n.t('ai.errors.api', message: e.message) }
  rescue JSON::ParserError
    { success: false, error: I18n.t('ai.errors.invalid_format') }
  rescue => e
    Rails.logger.error "ActivityGenerationService error: #{e.class}: #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    { success: false, error: I18n.t('ai.errors.generic') }
  end

  private

  def call_api
    message = @client.messages.create(
      model: "claude-haiku-4-5-20251001",
      max_tokens: 2000,
      system: SYSTEM_PROMPT,
      messages: [{ role: "user", content: @prompt }]
    )

    text_block = message.content.find { |b| b.type == :text }
    raise "Resposta vazia da IA" unless text_block
    text_block.text.strip
  end

  def strip_markdown(text)
    text.gsub(/\A```(?:json)?\s*/i, '').gsub(/\s*```\z/, '').strip
  end

  def parse_json(text)
    JSON.parse(text)
  end

  def build_activity(data)
    error_message = nil
    activity_record = nil

    ActiveRecord::Base.transaction do
      activity = Activity.new(
        title:        data["title"],
        description:  data["description"],
        level:        data["level"],
        statement:    data["statement"].presence,
        teacher:      @teacher,
        draft:        true,
        ai_generated: true
      )

      unless activity.save
        error_message = activity.errors.full_messages.join(", ")
        raise ActiveRecord::Rollback
      end

      Array(data["exercises"]).each do |ex|
        result = build_exercise(activity, ex)
        unless result
          error_message = "Erro ao salvar exercício do tipo '#{ex["type"]}'"
          raise ActiveRecord::Rollback
        end
      end

      activity_record = activity
    end

    if activity_record
      { success: true, activity: activity_record }
    else
      { success: false, error: error_message || "Erro desconhecido ao salvar atividade" }
    end
  end

  def build_exercise(activity, ex)
    case ex["type"]
    when "multiple_choice", "fill_in_blank", "open_ended"
      build_question(activity, ex)
    when "sentence_ordering"
      build_sentence_ordering(activity, ex)
    when "paragraph_ordering"
      build_paragraph_ordering(activity, ex)
    when "column_matching"
      build_column_matching(activity, ex)
    else
      Rails.logger.warn "ActivityGenerationService: tipo de exercício desconhecido '#{ex["type"]}' — ignorado"
      true
    end
  end

  def build_question(activity, ex)
    answers = ex["correct_answers"]
    question = activity.questions.build(
      question_type:   ex["type"],
      content:         ex["content"],
      correct_answer:  answers&.first || ex["correct_answer"],
      correct_answers: answers || [],
      options:         ex["options"] || []
    )
    question.save
  end

  def build_sentence_ordering(activity, ex)
    activity.sentence_orderings.create!(
      sentence:    ex["sentence"],
      instruction: ex["instruction"]
    )
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def build_paragraph_ordering(activity, ex)
    po = activity.paragraph_orderings.create!(instruction: ex["instruction"])
    Array(ex["sentences"]).each { |s| po.add_sentence(s) }
    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def build_column_matching(activity, ex)
    cm = activity.column_matchings.create!(instruction: ex["instruction"])
    Array(ex["pairs"]).each { |p| cm.add_pair(p["left"], p["right"]) }
    true
  rescue ActiveRecord::RecordInvalid
    false
  end
end
