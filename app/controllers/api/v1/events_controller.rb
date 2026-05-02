class Api::V1::EventsController < ApplicationController
  before_action :authenticate_user!

  def create
    # Validate payload
    if event_params[:type].blank?
      render json: { error: "Type is required" }, status: :unprocessable_entity
      return
    end

    payload = {
      event_id: SecureRandom.uuid,
      user_id: current_user.id,
      type: event_params[:type],
      timestamp: event_params[:timestamp] || Time.current.to_i,
      data: event_params[:payload]
    }.to_json

    Karafka.producer.produce_async(
      topic: "user.events",
      payload: payload
    )

    render json: { status: "queued" }, status: :accepted
  end

  private

  def event_params
    params.require(:event).permit(:type, :timestamp, payload: {})
  end
end
