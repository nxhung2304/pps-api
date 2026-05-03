require "test_helper"

class EventPersistenceFlowTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @token = JwtService.encode(user_id: @user.id)
    @headers = { "Authorization" => "Bearer #{@token}", "Content-Type" => "application/json" }
  end

  class MockProducer
    attr_reader :produced_payload
    def produce_async(topic:, payload:)
      @produced_payload = payload
    end
  end

  class MockMessage
    attr_reader :payload
    def initialize(payload)
      @payload = JSON.parse(payload)
    end
  end

  test "end-to-end flow: API -> Kafka Producer -> Consumer -> Database" do # rubocop:disable Minitest/MultipleAssertions
    producer_mock = MockProducer.new

    # Mock Karafka.producer
    Karafka.stub :producer, producer_mock do
      post api_v1_events_url,
           params: { event: { type: "activity_event", payload: { action: "click" }, timestamp: Time.current.to_i } }.to_json,
           headers: @headers

      assert_response :accepted
      assert_not_nil producer_mock.produced_payload
    end

    # Simulate Consumer receiving the message
    consumer = UserEventsConsumer.new
    message = MockMessage.new(producer_mock.produced_payload)

    # We need to stub messages on the consumer instance
    def consumer.messages; @mock_messages; end
    consumer.instance_variable_set(:@mock_messages, [ message ])

    assert_difference "Event.count", 1 do
      consumer.consume
    end

    event = Event.last

    assert_equal @user.id, event.user_id
    assert_equal "activity_event", event.type
    assert_equal "click", event.payload["action"]
  end
end
