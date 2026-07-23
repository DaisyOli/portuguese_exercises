require 'rails_helper'

RSpec.describe InactivityNudgeJob, type: :job do
  it 'avisa aluno com push ativo, já engajado antes, inativo há 48h+' do
    student = create(:user, :student)
    create(:push_subscription, user: student)
    create(:quiz_attempt, user: student, submitted_at: 3.days.ago)

    expect(PushNotificationService).to receive(:send_to_user)
      .with(student, hash_including(title: "Sentimos sua falta!", body: "Que tal 5 minutinhos de português hoje?"))

    described_class.perform_now

    expect(student.reload.inactivity_nudge_sent_at).to be_present
  end

  it 'usa texto misturado com português para aluno de língua inglesa' do
    student = create(:user, :student, language: "en")
    create(:push_subscription, user: student)
    create(:quiz_attempt, user: student, submitted_at: 3.days.ago)

    expect(PushNotificationService).to receive(:send_to_user)
      .with(student, hash_including(title: "We miss you · sentimos sua falta!"))

    described_class.perform_now
  end

  it 'usa texto misturado com português para aluno de língua francesa' do
    student = create(:user, :student, language: "fr")
    create(:push_subscription, user: student)
    create(:quiz_attempt, user: student, submitted_at: 3.days.ago)

    expect(PushNotificationService).to receive(:send_to_user)
      .with(student, hash_including(title: "Vous nous manquez · sentimos sua falta !"))

    described_class.perform_now
  end

  it 'não avisa quem praticou há menos de 48h' do
    student = create(:user, :student)
    create(:push_subscription, user: student)
    create(:quiz_attempt, user: student, submitted_at: 10.hours.ago)

    expect(PushNotificationService).not_to receive(:send_to_user)

    described_class.perform_now
  end

  it 'não avisa quem nunca praticou' do
    student = create(:user, :student)
    create(:push_subscription, user: student)

    expect(PushNotificationService).not_to receive(:send_to_user)

    described_class.perform_now
  end

  it 'não avisa quem não tem push ativo' do
    student = create(:user, :student)
    create(:quiz_attempt, user: student, submitted_at: 3.days.ago)

    expect(PushNotificationService).not_to receive(:send_to_user)

    described_class.perform_now
  end

  it 'não avisa trial mesmo com push ativo e inativo há 48h+' do
    trial = create(:user, :trial)
    create(:push_subscription, user: trial)
    create(:quiz_attempt, user: trial, submitted_at: 3.days.ago)

    expect(PushNotificationService).not_to receive(:send_to_user)

    described_class.perform_now
  end

  it 'não avisa de novo enquanto o aluno não voltar a praticar' do
    student = create(:user, :student, inactivity_nudge_sent_at: 1.hour.ago)
    create(:push_subscription, user: student)
    create(:quiz_attempt, user: student, submitted_at: 3.days.ago)

    expect(PushNotificationService).not_to receive(:send_to_user)

    described_class.perform_now
  end

  it 'avisa de novo se o aluno praticou depois do último aviso e sumiu de novo' do
    student = create(:user, :student, inactivity_nudge_sent_at: 5.days.ago)
    create(:push_subscription, user: student)
    create(:quiz_attempt, user: student, submitted_at: 3.days.ago)

    expect(PushNotificationService).to receive(:send_to_user)

    described_class.perform_now
  end
end
