class Admin::DraftsController < Admin::BaseController
  TEACHER_EMAIL = "daisy.oliani@gmail.com".freeze
  TARGET = { "A1" => 30, "A2" => 30, "B1" => 30, "B2" => 20 }.freeze

  def index
    @teacher = User.find_by(email: TEACHER_EMAIL)
    @published = Activity.where(ai_generated: true, draft: false).group(:level).count
    @drafts = Activity.where(ai_generated: true, draft: true)
                      .order(created_at: :desc)
                      .includes(:questions, :sentence_orderings, :paragraph_orderings, :column_matchings)
    @target = TARGET
  end

  def generate
    teacher = User.find_by(email: TEACHER_EMAIL)
    return redirect_to admin_drafts_path, alert: "Professora não encontrada." unless teacher

    forced = TARGET.key?(params[:level]) ? params[:level] : nil
    level  = if forced
               forced
             else
               current = Activity.where(teacher: teacher, ai_generated: true).group(:level).count
               TARGET
                 .map    { |lvl, goal| [lvl, goal - current.fetch(lvl, 0)] }
                 .select { |_, gap| gap > 0 }
                 .max_by { |_, gap| gap }
                 &.first
             end

    return redirect_to admin_drafts_path, notice: "Meta atingida em todos os níveis! 🎉" if level.nil?

    # A geração roda em background (sem limite de 30s do Heroku e sem
    # gerações simultâneas disputando slug); o admin espera no modal do agente.
    generation = AiGeneration.create!(
      teacher:        teacher,
      kind:           "agent",
      request_params: { level: level }
    )
    AiActivityGenerationJob.perform_later(generation.id)

    redirect_to generation_wait_activities_path(id: generation.id)
  end

  def destroy
    activity = Activity.find(params[:id])
    title = activity.title
    activity.destroy
    redirect_to admin_drafts_path, notice: "Rascunho '#{title}' descartado."
  end
end
