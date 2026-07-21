require 'rails_helper'

RSpec.describe SentenceOrdering, type: :model do
  let(:activity) { create(:activity) }
  let(:ordering) { activity.sentence_orderings.create!(sentence: "Eu gosto de café") }
  let(:words) { ordering.sentence_words.order(:correct_position).to_a }

  describe '#word_results' do
    it 'marca todas as posições como corretas quando o aluno acerta tudo' do
      answer = words.map(&:id)

      results = ordering.word_results(answer)

      expect(results.size).to eq(4)
      expect(results).to all(include("ok" => true))
    end

    it 'marca só as posições erradas quando o aluno acerta parte' do
      answer = [words[0].id, words[1].id, words[3].id, words[2].id] # trocou as 2 últimas

      results = ordering.word_results(answer)

      expect(results.count { |r| r["ok"] }).to eq(2)
      expect(results[2]["ok"]).to be false
      expect(results[2]["correct"]).to eq(words[2].word)
    end

    it 'retorna um item por palavra mesmo quando a resposta vem incompleta' do
      results = ordering.word_results([words[0].id])

      expect(results.size).to eq(4)
      expect(results.first["ok"]).to be true
      expect(results[1]["ok"]).to be false
      expect(results[1]["given"]).to be_nil
    end
  end

  describe '#check_order' do
    it 'retorna true quando toda a ordem está correta' do
      expect(ordering.check_order(words.map(&:id))).to be true
    end

    it 'retorna false quando há pelo menos uma posição errada' do
      answer = [words[0].id, words[1].id, words[3].id, words[2].id]
      expect(ordering.check_order(answer)).to be false
    end
  end
end
