class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last

    unauthorized! unless token

    user_data = JwtService.decode(token) rescue nil

    unauthorized! unless user_data

    @current_user = User.find_by(id: user_data[:user_id])

    unauthorized! unless @current_user
  end

  def unauthorized!
    render json: { error: "Unauthorized" }, status: :unauthorized
  end
end
