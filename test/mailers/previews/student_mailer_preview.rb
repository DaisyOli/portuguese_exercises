class StudentMailerPreview < ActionMailer::Preview
  def new_activity_pt
    student  = User.where(role: "student", language: "pt").first ||
               User.new(name: "Aluno Exemplo", email: "aluno@exemplo.com", language: "pt", level: "B1")
    activity = Activity.published.first ||
               Activity.new(title: "Exemplo de Atividade", level: "B1", slug: "exemplo")
    StudentMailer.new_activity(student, activity)
  end

  def new_activity_fr
    student  = User.where(role: "student", language: "fr").first ||
               User.new(name: "Étudiant Exemple", email: "etudiant@exemple.com", language: "fr", level: "B1")
    activity = Activity.published.first ||
               Activity.new(title: "Exemplo de Atividade", level: "B1", slug: "exemplo")
    StudentMailer.new_activity(student, activity)
  end

  def new_activity_en
    student  = User.where(role: "student", language: "en").first ||
               User.new(name: "Example Student", email: "student@example.com", language: "en", level: "B1")
    activity = Activity.published.first ||
               Activity.new(title: "Exemplo de Atividade", level: "B1", slug: "exemplo")
    StudentMailer.new_activity(student, activity)
  end

  def weekly_reminder_pt
    student    = User.where(role: "student", language: "pt").first ||
                 User.new(name: "Aluno Exemplo", email: "aluno@exemplo.com", language: "pt", level: "B1")
    activities = Activity.published.limit(3)
    StudentMailer.weekly_reminder(student, activities)
  end

  def weekly_reminder_with_featured
    student    = User.where(role: "student", language: "pt").first ||
                 User.new(name: "Aluno Exemplo", email: "aluno@exemplo.com", language: "pt", level: "B1")
    activities = Activity.published.limit(1)
    featured   = Activity.published.limit(3)
    StudentMailer.weekly_reminder(student, activities, featured)
  end
end
