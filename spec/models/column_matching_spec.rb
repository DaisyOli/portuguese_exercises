require 'rails_helper'

RSpec.describe ColumnMatching, type: :model do
  let(:activity) { create(:activity) }
  let(:matching) { activity.column_matchings.create!(title: "Capitais") }

  let!(:pair1) { matching.add_pair("Brasil", "Brasília") }
  let!(:pair2) { matching.add_pair("França", "Paris") }
  let!(:pair3) { matching.add_pair("Japão", "Tóquio") }
  let!(:pair4) { matching.add_pair("Egito", "Cairo") }

  describe '#pair_results' do
    it 'marca todos os pares como corretos quando o aluno acerta tudo' do
      answer = [pair1, pair2, pair3, pair4].map { |p| "#{p.id}:#{p.id}" }.join(',')

      results = matching.pair_results(answer)

      expect(results.size).to eq(4)
      expect(results).to all(include("correct" => true))
    end

    it 'marca só os pares errados como incorretos quando o aluno acerta parte' do
      answer = [
        "#{pair1.id}:#{pair1.id}",
        "#{pair2.id}:#{pair2.id}",
        "#{pair3.id}:#{pair3.id}",
        "#{pair4.id}:#{pair1.id}" # trocou o par 4
      ].join(',')

      results = matching.pair_results(answer)

      expect(results.count { |r| r["correct"] }).to eq(3)
      wrong = results.find { |r| r["left"] == "Egito" }
      expect(wrong["correct"]).to be false
    end

    it 'marca todos os pares como incorretos quando a resposta está em branco' do
      results = matching.pair_results("")

      expect(results.size).to eq(4)
      expect(results).to all(include("correct" => false))
    end

    it 'retorna lista vazia quando não há pares cadastrados' do
      empty_matching = activity.column_matchings.create!(title: "Vazio")

      expect(empty_matching.pair_results("1:1")).to eq([])
    end
  end
end
