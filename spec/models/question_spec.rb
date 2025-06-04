require 'rails_helper'

RSpec.describe Question, type: :model do
  describe 'validations' do
    subject { build(:question) }
    
    it { should validate_presence_of(:content) }
    it { should validate_presence_of(:correct_answer) }
    it { should validate_presence_of(:question_type) }
    it { should validate_inclusion_of(:question_type).in_array(['multiple_choice', 'fill_in_blank']) }
  end

  describe 'associations' do
    it { should belong_to(:activity) }
  end

  describe 'factory' do
    it 'creates valid fill_in_blank question by default' do
      question = create(:question)
      expect(question).to be_valid
      expect(question.question_type).to eq('fill_in_blank')
      expect(question.content).to include('_____')
    end

    it 'creates valid multiple_choice question with trait' do
      question = create(:question, :multiple_choice)
      expect(question).to be_valid
      expect(question.question_type).to eq('multiple_choice')
      expect(question.options).to be_an(Array)
      expect(question.options).not_to be_empty
    end

    it 'creates valid fill_in_blank question with trait' do
      question = create(:question, :fill_in_blank)
      expect(question).to be_valid
      expect(question.question_type).to eq('fill_in_blank')
      expect(question.content).to include('_____')
    end
  end

  describe 'type-specific validations' do
    describe 'multiple_choice questions' do
      it 'requires options to be present' do
        question = build(:question, question_type: 'multiple_choice', options: nil)
        expect(question).not_to be_valid
        expect(question.errors[:options]).to include("não pode estar em branco")
      end

      it 'requires correct_answer to be in options' do
        question = build(:question, 
          question_type: 'multiple_choice',
          options: ['A', 'B', 'C'],
          correct_answer: 'D'
        )
        expect(question).not_to be_valid
        expect(question.errors[:correct_answer]).to include("deve ser uma das opções disponíveis")
      end

      it 'is valid when correct_answer is in options' do
        question = build(:question,
          question_type: 'multiple_choice',
          options: ['A', 'B', 'C'],
          correct_answer: 'B'
        )
        expect(question).to be_valid
      end
    end

    describe 'fill_in_blank questions' do
      it 'requires content to have blank spaces' do
        question = build(:question,
          question_type: 'fill_in_blank',
          content: 'Esta frase não tem espaços em branco.'
        )
        expect(question).not_to be_valid
        expect(question.errors[:content]).to include("deve conter pelo menos um espaço em branco (_____)")
      end

      it 'is valid when content has blank spaces' do
        question = build(:question,
          question_type: 'fill_in_blank',
          content: 'O gato _____ no telhado.'
        )
        expect(question).to be_valid
      end
    end
  end

  describe 'methods' do
    describe '#multiple_choice?' do
      it 'returns true for multiple_choice questions' do
        question = build(:question, question_type: 'multiple_choice')
        expect(question.multiple_choice?).to be true
      end

      it 'returns false for fill_in_blank questions' do
        question = build(:question, question_type: 'fill_in_blank')
        expect(question.multiple_choice?).to be false
      end
    end

    describe '#fill_in_blank?' do
      it 'returns true for fill_in_blank questions' do
        question = build(:question, question_type: 'fill_in_blank')
        expect(question.fill_in_blank?).to be true
      end

      it 'returns false for multiple_choice questions' do
        question = build(:question, question_type: 'multiple_choice')
        expect(question.fill_in_blank?).to be false
      end
    end
  end

  describe 'callbacks and validations' do
    describe 'ensure_options_is_array' do
      it 'initializes options as empty array when nil' do
        question = Question.new(question_type: 'multiple_choice')
        question.send(:ensure_options_is_array)
        expect(question.options).to eq([])
      end

      it 'removes blank options from array' do
        question = Question.new(
          question_type: 'multiple_choice',
          options: ['A', '', 'B', nil, 'C']
        )
        question.send(:ensure_options_is_array)
        expect(question.options).to eq(['A', 'B', 'C'])
      end
    end

    describe 'process_options_text' do
      it 'splits options_text into options array for multiple_choice' do
        question = Question.new(
          question_type: 'multiple_choice',
          options_text: 'Option A, Option B, Option C'
        )
        question.send(:process_options_text)
        expect(question.options).to eq(['Option A', 'Option B', 'Option C'])
      end

      it 'does not process options_text for fill_in_blank' do
        question = Question.new(
          question_type: 'fill_in_blank',
          options_text: 'Should not be processed'
        )
        original_options = question.options
        question.send(:process_options_text)
        expect(question.options).to eq(original_options)
      end
    end

    describe 'cache clearing' do
      it 'clears activity questions cache after commit' do
        question = create(:question)
        expect(Rails.cache).to receive(:delete_matched).with("activity_questions/#{question.activity_id}*")
        question.update(content: 'Updated content _____')
      end
    end
  end

  describe 'edge cases and error handling' do
    it 'handles empty options array for multiple_choice' do
      question = build(:question,
        question_type: 'multiple_choice',
        options: [],
        correct_answer: 'A'
      )
      expect(question).not_to be_valid
      expect(question.errors[:options]).to include("não pode estar em branco")
    end

    it 'handles special characters in fill_in_blank content' do
      question = build(:question,
        question_type: 'fill_in_blank',
        content: 'O _____ é muito útil! Você concorda?'
      )
      expect(question).to be_valid
    end

    it 'handles unicode characters in options' do
      question = build(:question,
        question_type: 'multiple_choice',
        options: ['São Paulo', 'Rio de Janeiro', 'Brasília'],
        correct_answer: 'São Paulo'
      )
      expect(question).to be_valid
    end
  end

  describe 'integration with activity' do
    let(:activity) { create(:activity) }

    it 'belongs to an activity' do
      question = create(:question, activity: activity)
      expect(question.activity).to eq(activity)
    end

    it 'is destroyed when activity is destroyed' do
      question = create(:question, activity: activity)
      question_id = question.id
      
      expect { activity.destroy }.to change { Question.count }.by(-1)
      expect(Question.find_by(id: question_id)).to be_nil
    end

    it 'can have multiple questions per activity' do
      question1 = create(:question, activity: activity)
      question2 = create(:question, :multiple_choice, activity: activity)
      
      expect(activity.questions).to include(question1, question2)
      expect(activity.questions.count).to eq(2)
    end
  end

  describe 'real-world scenarios' do
    it 'creates a Portuguese grammar question' do
      question = create(:question,
        content: 'Complete: Eu _____ ao mercado ontem.',
        correct_answer: 'fui',
        question_type: 'fill_in_blank'
      )
      
      expect(question).to be_valid
      expect(question.content).to include('_____')
      expect(question.correct_answer).to eq('fui')
    end

    it 'creates a vocabulary multiple choice question' do
      question = create(:question,
        question_type: 'multiple_choice',
        content: 'Qual é o significado de "casa"?',
        options: ['house', 'car', 'tree', 'book'],
        correct_answer: 'house'
      )
      
      expect(question).to be_valid
      expect(question.options).to include('house', 'car', 'tree', 'book')
      expect(question.correct_answer).to eq('house')
    end
  end
end 