class UserEventsConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      Rails.logger.info(message.payload)
    end
  end
end
