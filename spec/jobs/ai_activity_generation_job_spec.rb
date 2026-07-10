require 'rails_helper'

RSpec.describe AiActivityGenerationJob, type: :job do
  let(:teacher) { create(:user, :teacher) }

  it "marca done e liga a activity quando o service tem sucesso" do
    generation = AiGeneration.create!(teacher: teacher, kind: "prompt", request_params: { "prompt" => "verbos" })
    activity = create(:activity, teacher: teacher)
    allow(ActivityGenerationService).to receive(:new)
      .with(prompt: "verbos", teacher: teacher)
      .and_return(instance_double(ActivityGenerationService, call: { success: true, activity: activity }))

    described_class.perform_now(generation.id)

    generation.reload
    expect(generation.status).to eq("done")
    expect(generation.activity).to eq(activity)
  end

  it "usa o service de vídeo para kind video" do
    generation = AiGeneration.create!(teacher: teacher, kind: "video", request_params: {
      "youtube_url" => "https://youtu.be/abc", "transcript" => "texto longo", "level_hint" => "B1"
    })
    service = instance_double(ActivityFromVideoService, call: { success: false, error: "transcrição ilegível" })
    allow(ActivityFromVideoService).to receive(:new)
      .with(youtube_url: "https://youtu.be/abc", transcript: "texto longo", teacher: teacher, level_hint: "B1")
      .and_return(service)

    described_class.perform_now(generation.id)

    generation.reload
    expect(generation.status).to eq("failed")
    expect(generation.error_message).to eq("transcrição ilegível")
  end

  it "kind agent escolhe o prompt do template e marca done" do
    generation = AiGeneration.create!(teacher: teacher, kind: "agent", request_params: { "level" => "A1" })
    activity = create(:activity, teacher: teacher)
    allow(ActivityPromptTemplates).to receive(:pick)
      .with("A1", existing_count: kind_of(Integer))
      .and_return("prompt do template A1")
    allow(ActivityGenerationService).to receive(:new)
      .with(prompt: a_string_including("prompt do template A1"), teacher: teacher)
      .and_return(instance_double(ActivityGenerationService, call: { success: true, activity: activity }))

    described_class.perform_now(generation.id)

    generation.reload
    expect(generation.status).to eq("done")
    expect(generation.activity).to eq(activity)
  end

  it "kind agent lista as atividades existentes do nível no prompt (anti-repetição)" do
    create(:activity, teacher: teacher, level: "A1", ai_generated: true, title: "Cafezinho no Balcão")
    generation = AiGeneration.create!(teacher: teacher, kind: "agent", request_params: { "level" => "A1" })
    activity = create(:activity, teacher: teacher)
    allow(ActivityPromptTemplates).to receive(:pick).and_return("prompt base")

    captured_prompt = nil
    allow(ActivityGenerationService).to receive(:new) do |prompt:, teacher:|
      captured_prompt = prompt
      instance_double(ActivityGenerationService, call: { success: true, activity: activity })
    end

    described_class.perform_now(generation.id)

    expect(captured_prompt).to include("prompt base")
    expect(captured_prompt).to include("DIFERENTE")
    expect(captured_prompt).to include("Cafezinho no Balcão")
  end

  it "erro inesperado vira failed com mensagem genérica" do
    generation = AiGeneration.create!(teacher: teacher, kind: "prompt", request_params: { "prompt" => "x" })
    allow(ActivityGenerationService).to receive(:new).and_raise(StandardError, "boom")

    described_class.perform_now(generation.id)

    expect(generation.reload.status).to eq("failed")
    expect(generation.error_message).to eq(I18n.t('ai.errors.generic'))
  end
end
