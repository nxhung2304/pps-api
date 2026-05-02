require "test_helper"

class EventTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email: "test@example.com", password_digest: "password")
  end

  test "should be valid with valid attributes" do
    event = Event.new(user: @user, type: "auth_event", timestamp: Time.now.to_i, payload: {})

    assert_predicate event, :valid?
  end

  test "should be invalid without type" do
    event = Event.new(user: @user, timestamp: Time.now.to_i)

    assert_not event.valid?
  end

  test "should be invalid with invalid type" do
    assert_raises(ArgumentError) do
      Event.new(user: @user, type: "invalid_type", timestamp: Time.now.to_i)
    end
  end

  test "should be invalid with future timestamp" do
    event = Event.new(user: @user, type: "auth_event", timestamp: Time.now.to_i + 100)

    assert_not event.valid?
  end
end
