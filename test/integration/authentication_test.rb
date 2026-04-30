require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  setup do
    @user_params = { email: "test@example.com", password: "password", password_confirmation: "password" }
  end

  test "should register user" do
    post "/auth/register", params: @user_params

    assert_response :created
  end

  test "should not register user with invalid params" do
    post "/auth/register", params: { email: "invalid_email", password: "password", password_confirmation: "password" }

    assert_response :unprocessable_entity
  end

  test "should login user" do
    User.create!(@user_params)
    post "/auth/login", params: { email: "test@example.com", password: "password" }

    assert_response :ok
    assert_match /token/, response.body
  end

  test "should not login with invalid credentials" do
    post "/auth/login", params: { email: "test@example.com", password: "wrongpassword" }

    assert_response :unauthorized
  end
end
