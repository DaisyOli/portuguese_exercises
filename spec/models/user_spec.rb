require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'factory' do
    it 'creates a valid user' do
      user = build(:user)
      expect(user).to be_valid
    end

    it 'creates a valid teacher' do
      teacher = build(:user, :teacher)
      expect(teacher).to be_valid
      expect(teacher.role).to eq('teacher')
    end

    it 'creates a valid student' do
      student = build(:user, :student)
      expect(student).to be_valid
      expect(student.role).to eq('student')
    end

    it 'creates a valid trial user' do
      trial = build(:user, :trial)
      expect(trial).to be_valid
      expect(trial.role).to eq('trial')
    end

    it 'creates a valid admin' do
      admin = build(:user, :admin)
      expect(admin).to be_valid
      expect(admin.admin).to be true
      expect(admin.role).to eq('teacher')
    end
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(['teacher', 'student', 'trial']) }
    it { should validate_inclusion_of(:language).in_array(['en', 'pt', 'fr']) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }

    it 'requires level when role is trial' do
      trial = build(:user, :trial, level: nil)
      expect(trial).not_to be_valid
      expect(trial.errors[:level]).to be_present
    end
  end

  describe 'associations' do
    it { should have_many(:quiz_attempts).dependent(:destroy) }

    it 'can access activities as teacher through direct query' do
      teacher = create(:user, :teacher)
      activity = create(:activity, teacher: teacher)

      teacher_activities = Activity.where(teacher_id: teacher.id)
      expect(teacher_activities).to include(activity)
    end
  end

  describe 'methods' do
    let(:teacher) { create(:user, :teacher) }
    let(:student) { create(:user, :student) }
    let(:trial)   { create(:user, :trial) }
    let(:admin)   { create(:user, :admin) }

    describe '#teacher?' do
      it 'returns true for teacher role' do
        expect(teacher.teacher?).to be true
      end

      it 'returns false for student role' do
        expect(student.teacher?).to be false
      end
    end

    describe '#student?' do
      it 'returns true for student role' do
        expect(student.student?).to be true
      end

      it 'returns false for teacher role' do
        expect(teacher.student?).to be false
      end
    end

    describe '#trial?' do
      it 'returns true for trial role' do
        expect(trial.trial?).to be true
      end

      it 'returns false for student role' do
        expect(student.trial?).to be false
      end
    end

    describe '#admin?' do
      it 'returns true when admin flag is true' do
        expect(admin.admin?).to be true
      end

      it 'returns false for regular teacher' do
        expect(teacher.admin?).to be false
      end

      it 'returns false for student' do
        expect(student.admin?).to be false
      end
    end

    describe '#student_like?' do
      it 'returns true for student' do
        expect(student.student_like?).to be true
      end

      it 'returns true for trial user' do
        expect(trial.student_like?).to be true
      end

      it 'returns false for teacher' do
        expect(teacher.student_like?).to be false
      end
    end

    describe '#trial_expired?' do
      it 'returns true when trial_expires_at is in the past' do
        expired = create(:user, :trial, trial_expires_at: 1.day.ago)
        expect(expired.trial_expired?).to be true
      end

      it 'returns true when trial_expires_at is nil' do
        no_expiry = create(:user, :trial, trial_expires_at: nil)
        expect(no_expiry.trial_expired?).to be true
      end

      it 'returns false when trial is still active' do
        active = create(:user, :trial, trial_expires_at: 3.days.from_now)
        expect(active.trial_expired?).to be false
      end

      it 'returns false for non-trial user' do
        expect(student.trial_expired?).to be false
      end
    end

    describe '#trial_exhausted?' do
      it 'returns true when 3 activities used' do
        exhausted = create(:user, :trial, trial_activities_used: 3)
        expect(exhausted.trial_exhausted?).to be true
      end

      it 'returns false when fewer than 3 activities used' do
        expect(trial.trial_exhausted?).to be false
      end

      it 'returns false for non-trial user' do
        expect(student.trial_exhausted?).to be false
      end
    end

    describe '#accessible_levels' do
      it 'returns the assigned level and everything below it for a trial user' do
        b1_trial = create(:user, :trial, level: 'B1')
        expect(b1_trial.accessible_levels).to eq(['A1', 'A2', 'B1'])
      end

      it 'returns all levels up to C1 for a C1 student' do
        c1_student = create(:user, :student, level: 'C1')
        expect(c1_student.accessible_levels).to include('A1', 'A2', 'B1', 'B2', 'C1')
      end
    end

    describe '#weighted_priority_levels' do
      it 'includes every accessible level exactly once' do
        student = create(:user, :student, level: 'B2')
        result = student.weighted_priority_levels
        expect(result.sort).to eq(student.accessible_levels.sort)
      end

      it 'returns the single accessible level unchanged for an A1 user' do
        a1_trial = create(:user, :trial, level: 'A1')
        expect(a1_trial.weighted_priority_levels).to eq(['A1'])
      end

      it 'favors the assigned level as the first pick across repeated draws' do
        student = create(:user, :student, level: 'B2')
        picks = Array.new(200) { student.weighted_priority_levels.first }
        expect(picks.tally['B2']).to be > picks.tally.values_at('A1', 'A2', 'B1').compact.max
      end
    end

    describe '#language_name' do
      it 'returns "Português" for pt language' do
        user = create(:user, language: 'pt')
        expect(user.language_name).to eq('Português')
      end

      it 'returns "English" for en language' do
        user = create(:user, language: 'en')
        expect(user.language_name).to eq('English')
      end

      it 'returns "Français" for fr language' do
        user = create(:user, language: 'fr')
        expect(user.language_name).to eq('Français')
      end
    end
  end

  describe 'defaults and callbacks' do
    it 'sets default language correctly in factories' do
      user_with_default = create(:user)
      expect(['pt', 'en']).to include(user_with_default.language)
    end

    it 'preserves specified language when provided' do
      user = create(:user, language: 'en')
      expect(user.language).to eq('en')
    end

    it 'can create user with pt language' do
      user = create(:user, language: 'pt')
      expect(user.language).to eq('pt')
    end
  end
end
