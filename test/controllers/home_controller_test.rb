require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  test "redireciona para login quando não autenticado" do
    get root_url
    assert_response :redirect
    assert_redirected_to new_user_session_url
  end

  test "exibe a home para usuário autenticado" do
    sign_in users(:one)
    get root_url
    assert_response :success
  end
end
