class ApplicationController < ActionController::API
  before_action :authenticate_user!

  attr_reader :current_user

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last

    return unauthorized! unless token

    user_data = begin
                  JwtService.decode(token)
                rescue StandardError
                  nil
                end

    return unauthorized! unless user_data && user_data[:user_id]

    @current_user = User.find_by(id: user_data[:user_id])

    unauthorized! unless @current_user
  end

  def unauthorized!
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
