require "anthropic"

class ActivityGenerationService
  SYSTEM_PROMPT = <<~PROMPT
    Você é um especialista em pedagogia e criação de materiais didáticos para ensino de português brasileiro como língua estrangeira (PLE).

    Sua tarefa é gerar atividades completas em formato JSON estruturado. O sistema suporta exatamente 5 tipos de exercício — nenhum outro será aceito.

    ═══════════════════════════════════════════
    REGRAS ABSOLUTAS
    ═══════════════════════════════════════════
    1. Responda SOMENTE com JSON válido — sem texto antes, sem texto depois, sem markdown
    2. Use APENAS os 5 tipos de exercício listados abaixo. Qualquer outro tipo causará erro no sistema.
    3. O campo "type" deve ter exatamente um destes valores: "multiple_choice", "fill_in_blank", "sentence_ordering", "paragraph_ordering", "column_matching"

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
    Estrutura:
    {
      "type": "fill_in_blank",
      "content": "No sábado, Ana _____ ao mercado com a sua mãe de manhã. (ir — pretérito perfeito)",
      "correct_answer": "foi"
    }
    REGRAS:
    - "content" deve conter EXATAMENTE _____ (5 underscores) onde a resposta vai
    - "correct_answer" é a palavra ou expressão que preenche a lacuna
    - Pode incluir a instrução entre parênteses no final da frase, como acima
    - NÃO inclua "options"

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

    ═══════════════════════════════════════════
    MAPEAMENTO PEDAGÓGICO
    ═══════════════════════════════════════════
    Quando o professor pedir:
    - "compreensão de texto/diálogo" → coloque o texto em "statement" + use "multiple_choice"
    - "preencher lacunas / conjugação" → use "fill_in_blank"
    - "ordenar palavras" → use "sentence_ordering"
    - "ordenar frases / parágrafos" → use "paragraph_ordering"
    - "associar / combinar / matching" → use "column_matching"
    - "variar os tipos" → use os 5 tipos disponíveis acima, não invente novos

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
          "content": "Carlos _____ cedo no sábado. (dormir — pretérito perfeito)",
          "correct_answer": "dormiu"
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
      model: :"claude-sonnet-4-6",
      max_tokens: 4096,
      system_: SYSTEM_PROMPT,
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
    when "multiple_choice", "fill_in_blank"
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
    question = activity.questions.build(
      question_type:  ex["type"],
      content:        ex["content"],
      correct_answer: ex["correct_answer"],
      options:        ex["options"] || []
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
