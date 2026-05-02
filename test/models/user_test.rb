require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "fixtures should be valid" do
    assert_predicate users(:one), :valid?
    assert_predicate users(:two), :valid?
  end

  test "should be valid with valid attributes" do
    user = User.new(email: "unique@example.com", password: "password", password_confirmation: "password")

    assert_predicate user, :valid?
  end

  test "should be invalid without email" do
    user = User.new(email: nil)

    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should be invalid with duplicate email" do
    user = User.new(email: users(:one).email, password: "password")

    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "should be invalid with malformed email" do
    user = User.new(email: "invalid-email")

    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "should have secure password" do
    user = users(:one)

    assert_respond_to user, :authenticate
    assert user.authenticate("password")
    assert_not user.authenticate("wrongpassword")
  end

  test "should have many events" do
    user = users(:one)
    event = user.events.create!(type: "auth_event", timestamp: Time.now.to_i, payload: {})

    assert_includes user.events, event
  end

  test "should destroy associated events when user is destroyed" do
    user = users(:one)
    user.events.create!(type: "auth_event", timestamp: Time.now.to_i, payload: {})

    assert_difference "Event.count", -1 do
      user.destroy
    end
  end
end
