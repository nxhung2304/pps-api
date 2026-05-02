require "test_helper"

class Api::V1::EventIngestionTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = JwtService.encode(user_id: @user.id)
    @headers = { "Authorization" => "Bearer #{@token}", "Content-Type" => "application/json" }
  end

  test "should create event with valid token and payload" do
    assert_difference("Event.count", 1) do
      post api_v1_events_url,
           params: { event: { type: "auth_event", payload: { button: "buy" }, timestamp: Time.current.to_i } }.to_json,
           headers: @headers
    end
  end

  test "should return unauthorized with missing token" do
    post api_v1_events_url,
         params: { event: { type: "auth_event", payload: { button: "buy" }, timestamp: Time.current.to_i } }.to_json,
         headers: { "Content-Type" => "application/json" }

    assert_response :unauthorized
  end

  test "should return unauthorized with invalid token" do
    post api_v1_events_url,
         params: { event: { type: "auth_event", payload: { button: "buy" }, timestamp: Time.current.to_i } }.to_json,
         headers: { "Authorization" => "Bearer invalid", "Content-Type" => "application/json" }

    assert_response :unauthorized
  end

  test "should return unprocessable entity with invalid payload" do
    post api_v1_events_url,
         params: { event: { type: "", payload: { button: "buy" }, timestamp: Time.current.to_i } }.to_json,
         headers: @headers

    assert_response :unprocessable_entity
  end
end
