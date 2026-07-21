require 'rails_helper'

RSpec.describe ParagraphOrdering, type: :model do
  let(:activity) { create(:activity) }
  let(:ordering) { activity.paragraph_orderings.create! }

  before do
    ordering.add_sentence("Primeiro parágrafo.")
    ordering.add_sentence("Segundo parágrafo.")
    ordering.add_sentence("Terceiro parágrafo.")
  end

  let(:sentences) { ordering.paragraph_sentences.order(:correct_position).to_a }

  describe '#sentence_results' do
    it 'marca todas as posições como corretas quando o aluno acerta tudo' do
      answer = sentences.map(&:id)

      results = ordering.sentence_results(answer)

      expect(results.size).to eq(3)
      expect(results).to all(include("ok" => true))
    end

    it 'marca só as posições erradas quando o aluno acerta parte' do
      answer = [sentences[1].id, sentences[0].id, sentences[2].id] # trocou as 2 primeiras

      results = ordering.sentence_results(answer)

      expect(results.count { |r| r["ok"] }).to eq(1)
      expect(results[0]["ok"]).to be false
      expect(results[0]["correct"]).to eq(sentences[0].sentence)
    end

    it 'retorna um item por frase mesmo quando a resposta vem incompleta' do
      results = ordering.sentence_results([sentences[0].id])

      expect(results.size).to eq(3)
      expect(results.first["ok"]).to be true
      expect(results[1]["given"]).to be_nil
    end
  end

  describe '#check_order' do
    it 'retorna true quando toda a ordem está correta' do
      expect(ordering.check_order(sentences.map(&:id))).to be true
    end

    it 'retorna false quando há pelo menos uma posição errada' do
      answer = [sentences[1].id, sentences[0].id, sentences[2].id]
      expect(ordering.check_order(answer)).to be false
    end
  end
end
