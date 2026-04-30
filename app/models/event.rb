class Event < ApplicationRecord
  self.inheritance_column = :_type_disabled

  belongs_to :user

  validates :type, presence: true, inclusion: { in: %w[auth_event activity_event] }
  validates :timestamp, presence: true
  validate :timestamp_not_in_future

  private

  def timestamp_not_in_future
    if timestamp.present? && timestamp > Time.now.to_i
      errors.add(:timestamp, "cannot be in the future")
    end
  end
end
