require 'test_helper'

class GameControllerTest < ActionDispatch::IntegrationTest
  test "should get view" do
    get game_view_url
    assert_response :success
  end

  test "should get edit" do
    get game_edit_url
    assert_response :success
  end

end
