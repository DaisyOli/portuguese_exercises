class ActivityFromVideoService
  MAX_TRANSCRIPT_CHARS = 8000

  def initialize(youtube_url:, transcript:, teacher:, level_hint: nil)
    @youtube_url = youtube_url.to_s.strip
    @transcript  = transcript.to_s.strip[0, MAX_TRANSCRIPT_CHARS]
    @teacher     = teacher
    @level_hint  = level_hint.presence || "adequado ao vocabulário e estruturas do vídeo (infira o nível CEFR)"
  end

  def call
    svc = YoutubeTranscriptService.new(@youtube_url)
    unless svc.valid?
      return { success: false, error: "URL do YouTube inválida. Verifique o link do vídeo." }
    end

    if @transcript.blank?
      return { success: false, error: "A transcrição está vazia. Cole o texto da transcrição do vídeo." }
    end

    # Release DB connection before the long Claude API call so it doesn't
    # time out idle on Heroku/RDS while waiting for the response.
    ActiveRecord::Base.connection_pool.release_connection

    result = ActivityGenerationService.new(
      prompt:  build_prompt,
      teacher: @teacher
    ).call

    return result unless result[:success]

    video_url = "https://www.youtube.com/watch?v=#{svc.video_id}"
    result[:activity].update(video_url: video_url)

    { success: true, activity: result[:activity] }
  end

  private

  def build_prompt
    <<~PROMPT
      Crie uma atividade de português brasileiro baseada na transcrição de vídeo abaixo.

      Nível desejado: #{@level_hint}

      TRANSCRIÇÃO DO VÍDEO:
      #{@transcript}

      INSTRUÇÕES ESPECÍFICAS PARA ATIVIDADE BASEADA EM VÍDEO:
      - Leia a transcrição e identifique o tema, vocabulário e estruturas gramaticais principais
      - O campo "explanation_text" deve conter um trecho adaptado e limpo da transcrição (não a transcrição bruta — reescreva de forma clara e fluida, como um texto para leitura)
      - Crie entre 5 e 8 exercícios variados usando os tipos disponíveis, baseados no conteúdo real da transcrição
      - Use vocabulário e expressões que aparecem na transcrição nas questões
      - A "description" deve mencionar o tema do vídeo e o que o aluno vai praticar
      - NÃO faça referência a "assista ao vídeo" nos exercícios — o player já fica integrado à atividade
    PROMPT
  end
end
