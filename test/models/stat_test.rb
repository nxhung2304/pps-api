require "test_helper"

class StatTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @date = Date.current
  end

  test "should be valid with valid attributes" do
    stat = Stat.new(
      user: @user,
      date: Date.tomorrow, # Use tomorrow to avoid conflict with fixtures
      total_coding_time: 120,
      total_gym_time: 60,
      total_run_distance: 5.5,
      sleep_duration: 8.0,
      event_count: 5
    )

    assert_predicate stat, :valid?, stat.errors.full_messages.join(", ")
  end

  test "should require user, date, and metrics" do
    stat = Stat.new

    assert_not stat.valid?
    assert_includes stat.errors[:user], "must exist"
    assert_includes stat.errors[:date], "can't be blank"
  end

  test "should validate numericality of metrics" do
    stat = Stat.new(user: @user, date: @date, total_coding_time: -1, sleep_duration: -0.5)

    assert_not stat.valid?
    assert_includes stat.errors[:total_coding_time], "must be greater than or equal to 0"
    assert_includes stat.errors[:sleep_duration], "must be greater than or equal to 0"
  end

  test "should validate uniqueness of date scoped to user" do
    existing_stat = stats(:one)
    stat = Stat.new(user: existing_stat.user, date: existing_stat.date)

    assert_not stat.valid?
    assert_includes stat.errors[:date], "has already been taken"
  end

  test ".increment_metrics should create a new record if it doesn't exist" do
    date = Date.tomorrow
    assert_difference "Stat.count", 1 do
      Stat.increment_metrics(@user.id, date, { total_coding_time: 100, event_count: 1 })
    end

    stat = Stat.find_by(user_id: @user.id, date: date)

    assert_equal 100, stat.total_coding_time
    assert_equal 1, stat.event_count
  end

  test ".increment_metrics should increment existing record" do
    existing_stat = stats(:one)
    user_id = existing_stat.user_id
    date = existing_stat.date

    initial_coding_time = existing_stat.total_coding_time
    initial_event_count = existing_stat.event_count

    assert_no_difference "Stat.count" do
      Stat.increment_metrics(user_id, date, { total_coding_time: 50, event_count: 1 })
    end

    existing_stat.reload

    assert_equal initial_coding_time + 50, existing_stat.total_coding_time
    assert_equal initial_event_count + 1, existing_stat.event_count
  end

  test ".increment_metrics should handle multiple metrics correctly" do
    date = Date.yesterday
    updates = {
      total_coding_time: 30,
      total_gym_time: 45,
      total_run_distance: 2.5,
      sleep_duration: 1.0,
      event_count: 2
    }

    Stat.increment_metrics(@user.id, date, updates)
    stat = Stat.find_by(user_id: @user.id, date: date)

    updates.each do |key, value|
      assert_equal value, stat.send(key)
    end
  end
end
