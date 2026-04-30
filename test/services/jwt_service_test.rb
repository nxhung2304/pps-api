require "test_helper"

class JwtServiceTest < ActiveSupport::TestCase
  test "should encode payload into JWT" do
    payload = { user_id: 1 }
    token = JwtService.encode(payload)
    assert_kind_of String, token
    assert token.present?
  end

  test "should decode valid token" do
    payload = { "user_id" => 1 }
    token = JwtService.encode(payload)
    decoded = JwtService.decode(token)
    assert_equal payload["user_id"], decoded[:user_id]
  end

  test "should return nil for invalid token" do
    assert_nil JwtService.decode("invalid-token")
  end

  test "should return nil for expired token" do
    payload = { user_id: 1 }
    token = JwtService.encode(payload, 1.minute.ago)
    assert_nil JwtService.decode(token)
  end
end
