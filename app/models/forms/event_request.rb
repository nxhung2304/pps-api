module Forms
  class EventRequest
    include ActiveModel::Model

    attr_accessor :type, :timestamp, :payload

    validates :type, presence: true
  end
end
