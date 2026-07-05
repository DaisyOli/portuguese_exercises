class VideoSuggestionsController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_teacher!
  before_action :set_suggestion, only: [:approve, :reject]

  def index
    @suggestions = VideoSuggestion.for_teacher(current_user).pending.order(created_at: :desc)
  end

  def approve
    transcript  = params[:transcript].to_s.strip
    youtube_url = params[:youtube_url].presence || @suggestion.youtube_url.presence || ""

    if transcript.blank?
      return redirect_to video_suggestions_path,
                         alert: "Cole a transcrição do vídeo antes de aprovar."
    end

    ActiveRecord::Base.connection_pool.release_connection

    result = ActivityFromVideoService.new(
      youtube_url: youtube_url,
      transcript:  transcript,
      teacher:     current_user,
      level_hint:  @suggestion.level_hint
    ).call

    if result[:success]
      @suggestion.update!(
        status:      'approved',
        transcript:  transcript,
        youtube_url: youtube_url,
        activity_id: result[:activity].id
      )
      redirect_to review_draft_activity_path(result[:activity]),
                  notice: "Atividade gerada! Revise e publique quando estiver pronto."
    else
      redirect_to video_suggestions_path, alert: result[:error]
    end
  end

  def reject
    @suggestion.update!(status: 'rejected')
    redirect_to video_suggestions_path, notice: "Sugestão descartada."
  end

  def generate_now
    result = DailyVideoSuggestionsService.new(teacher: current_user).call
    if result[:skipped]
      redirect_to video_suggestions_path, notice: "Você já tem sugestões para hoje."
    elsif result[:success]
      redirect_to video_suggestions_path,
                  notice: "#{result[:created]} nova(s) sugestão(ões) gerada(s)!"
    else
      redirect_to video_suggestions_path, alert: "Erro ao gerar sugestões: #{result[:error]}"
    end
  end

  private

  def set_suggestion
    @suggestion = VideoSuggestion.for_teacher(current_user).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to video_suggestions_path, alert: "Sugestão não encontrada."
  end

  def authorize_teacher!
    redirect_to root_path, alert: "Acesso restrito a professores." unless current_user&.teacher?
  end
end
