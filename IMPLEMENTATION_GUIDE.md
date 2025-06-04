# 🔧 GUIA PRÁTICO DE IMPLEMENTAÇÃO

## 🚨 IMPLEMENTAÇÕES CRÍTICAS - PASSO A PASSO

### 1. 🧪 **SETUP DE TESTES COMPLETO**

#### Adicionar gems no Gemfile:

```ruby
group :development, :test do
  gem 'rspec-rails', '~> 6.0'
  gem 'factory_bot_rails'
  gem 'database_cleaner-active_record'
  gem 'shoulda-matchers'
  gem 'faker'
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
end
```

#### Configuração inicial:

```bash
# 1. Instalar gems
bundle install

# 2. Gerar configuração RSpec
rails generate rspec:install

# 3. Configurar database cleaner
```

#### spec/rails_helper.rb:

```ruby
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  
  add_group 'Controllers', 'app/controllers'
  add_group 'Models', 'app/models'
  add_group 'Services', 'app/services'
  add_group 'Helpers', 'app/helpers'
end

require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'capybara/rspec'

# Shoulda Matchers
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# FactoryBot
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
```

#### Factories exemplo (spec/factories/):

```ruby
# spec/factories/users.rb
FactoryBot.define do
  factory :user do
    email { Faker::Internet.email }
    password { 'password123' }
    role { 'student' }
    language { 'pt' }
    
    trait :teacher do
      role { 'teacher' }
    end
    
    trait :student do
      role { 'student' }
    end
  end
end

# spec/factories/activities.rb
FactoryBot.define do
  factory :activity do
    title { Faker::Educator.course_name }
    description { Faker::Lorem.paragraph }
    level { Activity.levels.keys.sample }
    association :teacher, factory: [:user, :teacher]
  end
end

# spec/factories/questions.rb
FactoryBot.define do
  factory :question do
    association :activity
    content { "Complete a frase: O gato _____ no telhado." }
    question_type { 'fill_in_blank' }
    correct_answer { 'está' }
    
    trait :multiple_choice do
      question_type { 'multiple_choice' }
      content { "Qual é a capital do Brasil?" }
      options { ["São Paulo", "Rio de Janeiro", "Brasília", "Salvador"] }
      correct_answer { "Brasília" }
    end
  end
end
```

#### Testes de modelo exemplo:

```ruby
# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(['teacher', 'student']) }
    it { should validate_presence_of(:language) }
    it { should validate_inclusion_of(:language).in_array(['en', 'pt', 'fr']) }
  end

  describe 'associations' do
    it { should have_many(:activities).dependent(:destroy) }
    it { should have_many(:quiz_attempts).dependent(:destroy) }
  end

  describe 'methods' do
    let(:teacher) { create(:user, :teacher) }
    let(:student) { create(:user, :student) }

    it 'correctly identifies teacher role' do
      expect(teacher.teacher?).to be true
      expect(teacher.student?).to be false
    end

    it 'correctly identifies student role' do
      expect(student.student?).to be true
      expect(student.teacher?).to be false
    end
  end
end
```

---

### 2. 🏗️ **REFATORAÇÃO DE CONTROLLERS**

#### Service Object para submissão de quiz:

```ruby
# app/services/quiz/submission_service.rb
class Quiz::SubmissionService
  attr_reader :activity, :user, :answers

  def initialize(activity:, user:, answers:)
    @activity = activity
    @user = user
    @answers = answers
  end

  def call
    results = process_answers
    score = calculate_score(results)
    save_attempt(results, score)
  end

  private

  def process_answers
    results = {}
    
    activity.questions.each do |question|
      given_answer = answers[question.id.to_s]
      is_correct = evaluate_answer(question, given_answer)
      
      results[question.id] = {
        is_correct: is_correct,
        question_text: question.content,
        question_type: question.question_type,
        given_answer: given_answer || 'Não respondida',
        correct_answer: question.correct_answer
      }
    end
    
    results
  end

  def evaluate_answer(question, given_answer)
    return false if given_answer.blank?
    
    if question.fill_in_blank?
      normalize_text(given_answer) == normalize_text(question.correct_answer)
    else
      given_answer.strip == question.correct_answer.strip
    end
  end

  def normalize_text(text)
    I18n.transliterate(text.to_s.strip.downcase.gsub(/\s+/, ''))
  end

  def calculate_score(results)
    total_questions = results.count
    return 0 if total_questions.zero?
    
    correct_answers = results.values.count { |r| r[:is_correct] }
    ((correct_answers.to_f / total_questions) * 100).round(2)
  end

  def save_attempt(results, score)
    quiz_attempt = QuizAttempt.find_or_initialize_by(
      user: user,
      activity: activity
    )
    
    quiz_attempt.update!(
      score: score,
      results: {
        activity_id: activity.id,
        results: results,
        score: score,
        total_correct: results.values.count { |r| r[:is_correct] },
        total_questions: results.count,
        submitted_at: Time.current
      },
      submitted_at: Time.current
    )
    
    quiz_attempt
  end
end
```

#### Controller refatorado:

```ruby
# app/controllers/activities_controller.rb (versão limpa)
class ActivitiesController < ApplicationController
  include QuizManagement
  include CacheClearing
  
  before_action :authenticate_user!
  before_action :set_activity, only: [:show, :edit, :update, :destroy, 
                                      :resolve_quiz, :submit_quiz, :quiz_results]

  def index
    @activities = Activities::IndexService.new(
      user: current_user,
      level: params[:level]
    ).call
  end

  def show
    redirect_to resolve_quiz_activity_path(@activity) if current_user.student?
  end

  def resolve_quiz
    @questions = load_questions
  end

  def submit_quiz
    result = Quiz::SubmissionService.new(
      activity: @activity,
      user: current_user,
      answers: params[:answers] || {}
    ).call

    session[:quiz_attempt_id] = result.id
    redirect_to quiz_results_activity_path(@activity)
  end

  def quiz_results
    @quiz_attempt = current_user.quiz_attempts.find_by(
      id: session[:quiz_attempt_id],
      activity: @activity
    )
    
    redirect_to resolve_quiz_activity_path(@activity) unless @quiz_attempt
  end

  # ... outros métodos

  private

  def set_activity
    @activity = Activity.find(params[:id])
  end

  def load_questions
    Rails.cache.fetch(["activity_questions", @activity.id, @activity.updated_at.to_i], 
                     expires_in: 1.hour) do
      @activity.questions.to_a
    end
  end
end
```

#### Concern para gerenciamento de quiz:

```ruby
# app/controllers/concerns/quiz_management.rb
module QuizManagement
  extend ActiveSupport::Concern

  private

  def ensure_quiz_access
    redirect_to activities_path unless current_user.student?
  end

  def load_quiz_attempt
    @quiz_attempt = current_user.quiz_attempts.find_by(
      activity: @activity,
      id: session[:quiz_attempt_id]
    )
  end

  def clear_quiz_session
    session.delete(:quiz_attempt_id)
    session.delete(:last_quiz_score)
  end
end
```

---

### 3. 🎨 **MELHORIAS DE UX/UI**

#### Loading states com Stimulus:

```javascript
// app/javascript/controllers/quiz_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "submitButton", "spinner"]

  connect() {
    this.originalButtonText = this.submitButtonTarget.innerHTML
  }

  submit(event) {
    this.showLoading()
    // O form será submetido naturalmente
  }

  showLoading() {
    this.submitButtonTarget.disabled = true
    this.submitButtonTarget.innerHTML = `
      <span class="spinner-border spinner-border-sm me-2" role="status"></span>
      Processando...
    `
  }

  hideLoading() {
    this.submitButtonTarget.disabled = false
    this.submitButtonTarget.innerHTML = this.originalButtonText
  }
}
```

#### Toast notifications:

```javascript
// app/javascript/controllers/toast_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { 
    message: String, 
    type: String,
    duration: { type: Number, default: 5000 }
  }

  connect() {
    this.show()
  }

  show() {
    const toast = this.createToast()
    document.body.appendChild(toast)
    
    // Auto-remove after duration
    setTimeout(() => {
      this.remove(toast)
    }, this.durationValue)
  }

  createToast() {
    const toast = document.createElement('div')
    toast.className = `toast align-items-center text-white bg-${this.typeValue} border-0`
    toast.setAttribute('role', 'alert')
    toast.innerHTML = `
      <div class="d-flex">
        <div class="toast-body">
          ${this.messageValue}
        </div>
        <button type="button" class="btn-close btn-close-white me-2 m-auto" 
                data-bs-dismiss="toast"></button>
      </div>
    `
    return toast
  }

  remove(toast) {
    toast.remove()
  }
}
```

#### Progress bar para quizzes:

```erb
<!-- app/views/activities/resolve_quiz.html.erb -->
<div class="quiz-progress mb-4" data-controller="quiz-progress">
  <div class="progress">
    <div class="progress-bar" role="progressbar" style="width: 0%" 
         data-quiz-progress-target="bar">
    </div>
  </div>
  <small class="text-muted">
    Questão <span data-quiz-progress-target="current">1</span> 
    de <span data-quiz-progress-target="total"><%= @questions.count %></span>
  </small>
</div>
```

```javascript
// app/javascript/controllers/quiz_progress_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["bar", "current", "total"]

  connect() {
    this.totalQuestions = parseInt(this.totalTarget.textContent)
    this.currentQuestion = 1
    this.updateProgress()
  }

  nextQuestion() {
    if (this.currentQuestion < this.totalQuestions) {
      this.currentQuestion++
      this.updateProgress()
    }
  }

  previousQuestion() {
    if (this.currentQuestion > 1) {
      this.currentQuestion--
      this.updateProgress()
    }
  }

  updateProgress() {
    const percentage = (this.currentQuestion / this.totalQuestions) * 100
    this.barTarget.style.width = `${percentage}%`
    this.currentTarget.textContent = this.currentQuestion
  }
}
```

---

### 4. 📊 **DASHBOARD BÁSICO PARA PROFESSORES**

#### Service para analytics:

```ruby
# app/services/analytics/teacher_dashboard_service.rb
class Analytics::TeacherDashboardService
  attr_reader :teacher

  def initialize(teacher)
    @teacher = teacher
  end

  def call
    {
      total_activities: total_activities,
      total_students: total_students,
      recent_activities: recent_activities,
      top_performing_activities: top_performing_activities,
      student_engagement: student_engagement,
      level_distribution: level_distribution
    }
  end

  private

  def total_activities
    teacher.activities.count
  end

  def total_students
    User.joins(quiz_attempts: :activity)
        .where(activities: { teacher: teacher })
        .distinct
        .count
  end

  def recent_activities
    teacher.activities
           .order(created_at: :desc)
           .limit(5)
           .includes(:questions)
  end

  def top_performing_activities
    teacher.activities
           .joins(:quiz_attempts)
           .group('activities.id, activities.title')
           .average('quiz_attempts.score')
           .sort_by { |_, avg_score| -avg_score }
           .first(5)
  end

  def student_engagement
    last_30_days = 30.days.ago..Time.current
    
    QuizAttempt.joins(:activity)
               .where(activities: { teacher: teacher })
               .where(created_at: last_30_days)
               .group('DATE(quiz_attempts.created_at)')
               .count
  end

  def level_distribution
    teacher.activities.group(:level).count
  end
end
```

#### View do dashboard:

```erb
<!-- app/views/teachers/dashboard.html.erb -->
<div class="container-fluid">
  <div class="row">
    <!-- Métricas principais -->
    <div class="col-md-3 mb-4">
      <div class="card text-center">
        <div class="card-body">
          <h5 class="card-title">Atividades Criadas</h5>
          <h2 class="text-primary"><%= @dashboard_data[:total_activities] %></h2>
        </div>
      </div>
    </div>
    
    <div class="col-md-3 mb-4">
      <div class="card text-center">
        <div class="card-body">
          <h5 class="card-title">Estudantes Únicos</h5>
          <h2 class="text-success"><%= @dashboard_data[:total_students] %></h2>
        </div>
      </div>
    </div>
    
    <!-- Gráfico de engajamento -->
    <div class="col-md-6 mb-4">
      <div class="card">
        <div class="card-header">
          <h5>Atividade nos Últimos 30 Dias</h5>
        </div>
        <div class="card-body">
          <canvas id="engagementChart" data-controller="chart" 
                  data-chart-data-value="<%= @dashboard_data[:student_engagement].to_json %>">
          </canvas>
        </div>
      </div>
    </div>
  </div>
  
  <!-- Atividades recentes e top performance -->
  <div class="row">
    <div class="col-md-6">
      <div class="card">
        <div class="card-header">
          <h5>Atividades Recentes</h5>
        </div>
        <div class="card-body">
          <% @dashboard_data[:recent_activities].each do |activity| %>
            <div class="d-flex justify-content-between align-items-center mb-2">
              <div>
                <strong><%= activity.title %></strong>
                <br>
                <small class="text-muted">
                  <%= activity.questions.count %> questões • 
                  <%= activity.level %>
                </small>
              </div>
              <span class="badge bg-<%= activity.level_color_class %>">
                <%= activity.level %>
              </span>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    
    <div class="col-md-6">
      <div class="card">
        <div class="card-header">
          <h5>Melhor Performance</h5>
        </div>
        <div class="card-body">
          <% @dashboard_data[:top_performing_activities].each do |activity_data| %>
            <div class="d-flex justify-content-between align-items-center mb-2">
              <strong><%= activity_data[0] %></strong>
              <span class="badge bg-success">
                <%= "%.1f%" % activity_data[1] %>
              </span>
            </div>
          <% end %>
        </div>
      </div>
    </div>
  </div>
</div>
```

---

### 5. 🎮 **SISTEMA BÁSICO DE GAMIFICAÇÃO**

#### Models para gamificação:

```ruby
# app/models/badge.rb
class Badge < ApplicationRecord
  has_many :user_badges, dependent: :destroy
  has_many :users, through: :user_badges

  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  validates :icon, presence: true
  validates :condition_type, presence: true
  validates :condition_value, presence: true, numericality: { greater_than: 0 }

  enum condition_type: {
    activities_completed: 'activities_completed',
    perfect_score: 'perfect_score',
    streak_days: 'streak_days',
    total_score: 'total_score'
  }
end

# app/models/user_badge.rb
class UserBadge < ApplicationRecord
  belongs_to :user
  belongs_to :badge

  validates :user_id, uniqueness: { scope: :badge_id }
end

# app/models/streak.rb
class Streak < ApplicationRecord
  belongs_to :user

  validates :current_streak, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :longest_streak, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :last_activity_date, presence: true

  def update_streak!
    today = Date.current
    
    if last_activity_date == today
      # Já fez atividade hoje, não muda nada
      return
    elsif last_activity_date == today - 1.day
      # Atividade ontem, continua a sequência
      self.current_streak += 1
      self.longest_streak = [longest_streak, current_streak].max
    elsif last_activity_date < today - 1.day
      # Quebrou a sequência
      self.current_streak = 1
    end
    
    self.last_activity_date = today
    save!
  end
end
```

#### Service para verificar conquistas:

```ruby
# app/services/gamification/badge_checker_service.rb
class Gamification::BadgeCheckerService
  attr_reader :user

  def initialize(user)
    @user = user
  end

  def check_and_award_badges
    badges_awarded = []

    Badge.all.each do |badge|
      next if user.badges.include?(badge)
      
      if badge_earned?(badge)
        award_badge(badge)
        badges_awarded << badge
      end
    end

    badges_awarded
  end

  private

  def badge_earned?(badge)
    case badge.condition_type
    when 'activities_completed'
      user.quiz_attempts.count >= badge.condition_value
    when 'perfect_score'
      user.quiz_attempts.where(score: 100.0).count >= badge.condition_value
    when 'streak_days'
      user.streak&.current_streak.to_i >= badge.condition_value
    when 'total_score'
      user.quiz_attempts.sum(:score) >= badge.condition_value
    else
      false
    end
  end

  def award_badge(badge)
    UserBadge.create!(user: user, badge: badge, earned_at: Time.current)
  end
end
```

#### Migration para tabelas de gamificação:

```ruby
# db/migrate/xxx_create_gamification_tables.rb
class CreateGamificationTables < ActiveRecord::Migration[7.1]
  def change
    create_table :badges do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.string :icon, null: false
      t.string :condition_type, null: false
      t.integer :condition_value, null: false
      t.string :rarity, default: 'common'
      
      t.timestamps
    end

    create_table :user_badges do |t|
      t.references :user, null: false, foreign_key: true
      t.references :badge, null: false, foreign_key: true
      t.datetime :earned_at, null: false
      
      t.timestamps
    end

    create_table :streaks do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :current_streak, default: 0
      t.integer :longest_streak, default: 0
      t.date :last_activity_date
      
      t.timestamps
    end

    add_index :badges, :name, unique: true
    add_index :user_badges, [:user_id, :badge_id], unique: true
  end
end
```

---

## 🚀 IMPLEMENTAÇÃO RECOMENDADA

### Ordem de implementação:

1. **Semana 1**: Setup de testes + Factories
2. **Semana 2**: Testes unitários dos models
3. **Semana 3**: Refatoração do ActivitiesController
4. **Semana 4**: Melhorias de UX básicas
5. **Semana 5-6**: Dashboard para professores
6. **Semana 7-8**: Sistema básico de gamificação

### Comandos úteis para desenvolvimento:

```bash
# Rodar testes
bundle exec rspec

# Rodar testes com cobertura
COVERAGE=true bundle exec rspec

# Verificar qualidade do código
bundle exec rubocop

# Corrigir automaticamente alguns problemas
bundle exec rubocop -a

# Gerar documentação
bundle exec yard doc
```

Esse guia deve dar uma base sólida para implementar as melhorias mais críticas do seu app! 🚀 