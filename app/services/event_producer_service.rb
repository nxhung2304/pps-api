require "ostruct"

class EventProducerService
  def initialize(user, payload)
    @user = user
    @payload = payload
  end

  def call
    Karafka.producer.produce_async(
      topic: "user.events",
      payload: build_payload
    )

    OpenStruct.new(success?: true)
  rescue => e
    Rails.logger.error("[EventProducer] #{e.message}")

    OpenStruct.new(success?: false, error: e.message)
  end

  private

    def build_payload
      {
        user_id: @user.id,
        type: @payload.type,
        timestamp: @payload.timestamp || Time.current.to_i,
        data: @payload.payload || {}
      }.to_json
    end
end
