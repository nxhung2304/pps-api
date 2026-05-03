require "test_helper"
require "minitest/mock"

class UserEventsConsumerTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @consumer = UserEventsConsumer.new
  end

  class MockMessage
    attr_reader :payload
    def initialize(payload)
      @payload = payload
    end
  end

  test "persists a valid event to the database" do
    payload = {
      "user_id" => @user.id,
      "type" => "auth_event",
      "timestamp" => Time.now.to_i,
      "data" => { "action" => "login" }
    }

    message = MockMessage.new(payload)

    @consumer.stub :messages, [ message ] do
      assert_difference "Event.count", 1 do
        @consumer.consume
      end
    end
  end

  test "correctly maps payload attributes to event" do
    payload = {
      "user_id" => @user.id,
      "type" => "auth_event",
      "timestamp" => Time.now.to_i,
      "data" => { "action" => "login" }
    }

    message = MockMessage.new(payload)

    @consumer.stub :messages, [ message ] do
      @consumer.consume
    end

    event = Event.last

    assert_equal @user.id, event.user_id
    assert_equal "auth_event", event.type
    assert_equal payload["data"], event.payload
  end

  test "handles error during persistence" do
    payload = { "invalid" => "data" }

    message = Minitest::Mock.new
    message.expect :payload, payload

    @consumer.stub :messages, [ message ] do
      # Should not raise error, just log it
      assert_no_difference "Event.count" do
        @consumer.consume
      end
    end

    assert_mock message
  end
end
