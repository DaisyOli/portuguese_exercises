require 'rails_helper'

RSpec.describe "Tela de resultados com crédito parcial", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:teacher)  { create(:user, :teacher) }
  let(:student)  { create(:user, :student) }
  let(:activity) { create(:activity, teacher: teacher) }

  let!(:sentence_ordering) { activity.sentence_orderings.create!(sentence: "Eu gosto de café") }
  let(:words) { sentence_ordering.sentence_words.order(:correct_position).to_a }

  let!(:paragraph_ordering) { activity.paragraph_orderings.create! }
  let(:sentences) { paragraph_ordering.paragraph_sentences.order(:correct_position).to_a }

  let!(:column_matching) { activity.column_matchings.create!(title: "Capitais") }
  let!(:cm_pair1) { column_matching.add_pair("Brasil", "Brasília") }
  let!(:cm_pair2) { column_matching.add_pair("França", "Paris") }

  before do
    paragraph_ordering.add_sentence("Primeiro.")
    paragraph_ordering.add_sentence("Segundo.")
    paragraph_ordering.add_sentence("Terceiro.")
    sign_in student
  end

  it "renderiza a tela de resultados sem erro e mostra o estado parcial das ordenações" do
    post submit_activity_path(activity), params: {
      sentence_ordering_answers: {
        sentence_ordering.id.to_s => [words[0].id, words[1].id, words[3].id, words[2].id].join(",")
      },
      paragraph_ordering_answers: {
        paragraph_ordering.id.to_s => [sentences[1].id, sentences[0].id, sentences[2].id].join(",")
      },
      column_matching_answers: {
        column_matching.id.to_s => "#{cm_pair1.id}:#{cm_pair1.id},#{cm_pair2.id}:#{cm_pair1.id}"
      }
    }
    expect(response).to redirect_to(%r{/activities/#{activity.slug}/solve})

    get results_activity_path(activity)

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("2 de 4 corretas") # sentence_ordering parcial
    expect(response.body).to include("1 de 3 corretas") # paragraph_ordering parcial
    expect(response.body).to include("1 de 2 corretas") # column_matching parcial
  end
end
