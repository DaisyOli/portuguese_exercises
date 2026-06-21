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
    require Rails.root.join("lib/activity_prompt_templates")

    teacher = User.find_by(email: TEACHER_EMAIL)
    return redirect_to admin_drafts_path, alert: "Professora não encontrada." unless teacher

    target  = TARGET
    current = Activity.where(teacher: teacher, ai_generated: true, draft: false).group(:level).count
    level   = target
      .map    { |lvl, goal| [lvl, goal - current.fetch(lvl, 0)] }
      .select { |_, gap| gap > 0 }
      .max_by { |_, gap| gap }
      &.first

    return redirect_to admin_drafts_path, notice: "Meta atingida em todos os níveis! 🎉" if level.nil?

    prompt = ActivityPromptTemplates.pick(level)
    result = ActivityGenerationService.new(prompt: prompt, teacher: teacher).call

    if result[:success]
      redirect_to admin_drafts_path, notice: "✅ '#{result[:activity].title}' (#{level}) gerada e aguardando revisão."
    else
      redirect_to admin_drafts_path, alert: "❌ Falha ao gerar (#{result[:error]}). Tente novamente."
    end
  end

  def destroy
    activity = Activity.find(params[:id])
    title = activity.title
    activity.destroy
    redirect_to admin_drafts_path, notice: "Rascunho '#{title}' descartado."
  end
end
