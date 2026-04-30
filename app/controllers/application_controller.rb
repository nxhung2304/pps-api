class ApplicationController < ActionController::API
  before_action :authenticate_user!

  private

  def authenticate_user!
    token = request.headers["Authorization"]&.split(" ")&.last
    user_data = JwtService.decode(token) if token

    if user_data && (@current_user = User.find_by(id: user_data[:user_id]))
      @current_user
    else
      render json: { error: "Unauthorized" }, status: :unauthorized
    end
  end
end
