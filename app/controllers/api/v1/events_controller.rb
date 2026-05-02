class Api::V1::EventsController < ApplicationController
  before_action :authenticate_user!

  def create
    event = current_user.events.build(event_params)

    if event.save
      render json: event, status: :created
    else
      render json: { errors: event.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def event_params
    params.require(:event).permit(:type, :timestamp, payload: {})
  end
end
