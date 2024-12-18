require "test_helper"

class TeachersControllerTest < ActionDispatch::IntegrationTest
  test "should get dashboard" do
    get teachers_dashboard_url
    assert_response :success
  end
end
