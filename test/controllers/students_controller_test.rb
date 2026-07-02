require "test_helper"

class StudentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "redireciona para login quando não autenticado" do
    get student_dashboard_url
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  test "exibe a dashboard para aluno autenticado" do
    sign_in users(:student_pt)
    get student_dashboard_url
    assert_response :success
  end
end
