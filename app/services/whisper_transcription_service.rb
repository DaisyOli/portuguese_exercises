class WhisperTranscriptionService
  def initialize(audio_file)
    @audio_file = audio_file
  end

  def call
    client = OpenAI::Client.new(access_token: ENV["OPENAI_API_KEY"])

    response = client.audio.transcribe(
      parameters: {
        model:    "whisper-1",
        file:     @audio_file,
        language: "pt"
      }
    )

    text = response["text"].to_s.strip
    text.present? ? { success: true, text: text } : { success: false, error: "Não consegui entender o áudio. Tente falar mais claramente." }
  rescue => e
    Rails.logger.error "Whisper error: #{e.message}"
    { success: false, error: "Erro ao transcrever o áudio. Tente digitar sua resposta." }
  end
end
