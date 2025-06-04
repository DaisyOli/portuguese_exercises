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
  end

  describe 'validations' do
    subject { build(:user) }
    
    it { should validate_presence_of(:role) }
    it { should validate_inclusion_of(:role).in_array(['teacher', 'student']) }
    it { should validate_inclusion_of(:language).in_array(['en', 'pt', 'fr']) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
  end

  describe 'associations' do
    it { should have_many(:quiz_attempts).dependent(:destroy) }
    
    it 'can access activities as teacher through direct query' do
      teacher = create(:user, :teacher)
      activity = create(:activity, teacher: teacher)
      
      # Buscar atividades diretamente pela foreign key
      teacher_activities = Activity.where(teacher_id: teacher.id)
      expect(teacher_activities).to include(activity)
    end
  end

  describe 'methods' do
    let(:teacher) { create(:user, :teacher) }
    let(:student) { create(:user, :student) }

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