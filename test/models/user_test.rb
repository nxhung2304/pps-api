require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "should be valid with valid attributes" do
    user = User.new(email: "test@example.com", password: "password", password_confirmation: "password")
    assert user.valid?
  end

  test "should be invalid without email" do
    user = User.new(email: nil)
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "should be invalid with duplicate email" do
    User.create!(email: "duplicate@example.com", password: "password")
    user = User.new(email: "duplicate@example.com", password: "password")
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "should be invalid with malformed email" do
    user = User.new(email: "invalid-email")
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "should have secure password" do
    user = User.new(email: "test@example.com", password: "password")
    assert user.respond_to?(:authenticate)
    assert user.authenticate("password")
    assert_not user.authenticate("wrongpassword")
  end
end
