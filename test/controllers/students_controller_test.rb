require "test_helper"

class StudentsControllerTest < ActionDispatch::IntegrationTest
  test "should get dashboard" do
    get student_dashboard_url
    assert_response :success
  end
end
