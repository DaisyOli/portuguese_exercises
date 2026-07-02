require "test_helper"

class TeachersControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "redireciona para login quando não autenticado" do
    get teacher_dashboard_url
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  test "exibe a dashboard para professor autenticado" do
    sign_in users(:one)
    get teacher_dashboard_url
    assert_response :success
  end
end
