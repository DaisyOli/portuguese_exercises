require 'rails_helper'

RSpec.describe "Admin::Activities", type: :request do
  include Devise::Test::IntegrationHelpers

  let(:admin) { create(:user, :admin) }

  def rate!(activity, stars)
    create(:activity_rating, activity: activity, stars: stars)
  end

  describe "GET /admin/activities" do
    it "retorna 200 pro admin" do
      sign_in admin
      get admin_activities_path
      expect(response).to have_http_status(:ok)
    end

    it "redireciona quem não é admin" do
      teacher = create(:user, :teacher)
      sign_in teacher
      get admin_activities_path
      expect(response).to redirect_to(root_path)
    end

    it "só lista atividades com o mínimo de avaliações exigido" do
      well_rated   = create(:activity, :B1)
      few_ratings  = create(:activity, :B1)
      3.times { rate!(well_rated, 5) }
      2.times { rate!(few_ratings, 1) }

      sign_in admin
      get admin_activities_path

      expect(response.body).to include(well_rated.title)
      expect(response.body).not_to include(few_ratings.title)
    end

    it "ordena mais bem avaliadas por nota decrescente e menos apreciadas por nota crescente" do
      loved = create(:activity, :B1, title: "Atividade Amada")
      hated = create(:activity, :B1, title: "Atividade Odiada")
      3.times { rate!(loved, 5) }
      3.times { rate!(hated, 1) }

      sign_in admin
      get admin_activities_path
      body = response.body

      best_section  = body[body.index("Mais bem avaliadas")...body.index("Menos apreciadas")]
      worst_section = body[body.index("Menos apreciadas")..]

      expect(best_section.index(loved.title)).to be < best_section.index(hated.title)
      expect(worst_section.index(hated.title)).to be < worst_section.index(loved.title)
    end
  end
end
