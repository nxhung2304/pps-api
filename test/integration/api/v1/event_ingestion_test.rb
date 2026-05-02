require "test_helper"

class Api::V1::EventIngestionTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = JwtService.encode(user_id: @user.id)
    @headers = { "Authorization" => "Bearer #{@token}", "Content-Type" => "application/json" }
  end

  test "should queue event with valid token and payload" do
    # Create a simple mock object for the producer
    producer_mock = Object.new
    def producer_mock.produce_async(args)
      @produced_args = args
    end
    def producer_mock.produced_args; @produced_args; end

    # Manually mock Karafka.producer
    class << Karafka
      alias_method :real_producer, :producer
      def producer; @mock_producer || real_producer; end
      def mock_producer=(val); @mock_producer = val; end
    end
    Karafka.mock_producer = producer_mock

    begin
      post api_v1_events_url,
           params: { event: { type: "auth_event", payload: { button: "buy" }, timestamp: Time.current.to_i } }.to_json,
           headers: @headers

      assert_response :accepted
      assert_equal "queued", JSON.parse(response.body)["status"]
      
      produced = producer_mock.produced_args
      assert_equal 'user.events', produced[:topic]
      assert_equal 'auth_event', JSON.parse(produced[:payload])['type']
    ensure
      # Restore Karafka.producer
      class << Karafka
        remove_method :producer
        remove_method :mock_producer=
        alias_method :producer, :real_producer
        remove_method :real_producer
      end
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
