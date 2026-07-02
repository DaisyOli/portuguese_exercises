require "test_helper"

class StudentMailerTest < ActionMailer::TestCase
  # ── notifiable_levels_for_activity ──────────────────────────────────────────

  test "A1 activity notifica A1 e A2" do
    assert_equal %w[A1 A2], StudentMailer.notifiable_levels_for_activity("A1")
  end

  test "B1 activity notifica B1 e B2" do
    assert_equal %w[B1 B2], StudentMailer.notifiable_levels_for_activity("B1")
  end

  test "C1 activity (topo) notifica somente C1" do
    assert_equal %w[C1], StudentMailer.notifiable_levels_for_activity("C1")
  end

  test "nível desconhecido retorna array vazio" do
    assert_equal [], StudentMailer.notifiable_levels_for_activity("Z9")
  end

  # ── new_activity ────────────────────────────────────────────────────────────

  test "new_activity envia para o email do aluno" do
    email = StudentMailer.new_activity(users(:student_pt), activities(:b1_published))
    assert_equal [users(:student_pt).email], email.to
  end

  test "new_activity assunto em português inclui o nome do aluno" do
    student = users(:student_pt)
    email = StudentMailer.new_activity(student, activities(:b1_published))
    assert_match "Exercício novo", email.subject
    assert_match student.name, email.subject
  end

  test "new_activity assunto em francês" do
    email = StudentMailer.new_activity(users(:student_fr), activities(:b1_published))
    assert_match "Nouvel exercice", email.subject
  end

  test "new_activity assunto em inglês" do
    email = StudentMailer.new_activity(users(:student_en), activities(:b1_published))
    assert_match "New exercise", email.subject
  end

  test "new_activity enfileira o email para entrega" do
    assert_emails 1 do
      StudentMailer.new_activity(users(:student_pt), activities(:b1_published)).deliver_now
    end
  end

  # ── weekly_reminder ─────────────────────────────────────────────────────────

  test "weekly_reminder assunto em português inclui o nome do aluno" do
    student = users(:student_pt)
    email = StudentMailer.weekly_reminder(student, [activities(:b1_published)])
    assert_match "Seus exercícios desta semana", email.subject
    assert_match student.name, email.subject
  end

  test "weekly_reminder assunto em francês" do
    email = StudentMailer.weekly_reminder(users(:student_fr), [activities(:b1_published)])
    assert_match "Vos exercices", email.subject
  end

  test "weekly_reminder assunto em inglês" do
    email = StudentMailer.weekly_reminder(users(:student_en), [activities(:b1_published)])
    assert_match "Your exercises", email.subject
  end

  test "weekly_reminder aceita lista vazia com featured" do
    email = StudentMailer.weekly_reminder(
      users(:student_pt),
      [],
      [activities(:b1_published)]
    )
    assert_equal [users(:student_pt).email], email.to
  end

  test "weekly_reminder envia para o email do aluno" do
    email = StudentMailer.weekly_reminder(users(:student_pt), [activities(:b1_published)])
    assert_equal [users(:student_pt).email], email.to
  end
end
