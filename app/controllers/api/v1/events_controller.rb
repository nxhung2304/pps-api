class Api::V1::EventsController < ApplicationController
  before_action :authenticate_user!

  def create
    event_request = Forms::EventRequest.new(event_params)

    unless event_request.valid?
      return render json: { errors: event_request.errors.full_messages }, status: :unprocessable_entity
    end

    Rails.logger.info(
      "[Events#create] user_id=#{current_user.id} type=#{event_request.type}"
    )

    result = EventProducerService.new(current_user, event_request).call

    if result.success?
      render json: { status: "queued" }, status: :accepted
    else
      render json: { errors: result.error }, status: :bad_gateway
    end
  end

  private

    def event_params
      params.require(:event).permit(:type, :timestamp, payload: {})
    end
end
