class UserEventsConsumer < ApplicationConsumer
  def consume
    messages.each do |message|
      payload = message.payload

      persist_event(payload)
    rescue StandardError => e
      Rails.logger.error("Failed to persist event: #{e.message}. Payload: #{payload}")
    end
  end

  private

  def persist_event(payload)
    Event.create!(
      user_id: payload["user_id"],
      type: payload["type"],
      timestamp: payload["timestamp"],
      payload: payload["data"] || {}
    )
  end
end
