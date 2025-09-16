class Api::V1::UsersController < Api::V1::BaseController
  before_action :set_user, only: [ :show ]

  # GET /api/v1/users
  # Get all users
  def index
    users = User.all.order(:name)

    render_success({
      users: users.map { |user| user_data(user) },
      total_count: users.count
    })
  end

  # GET /api/v1/users/:id
  # Get a specific user
  def show
    render_success(user_data(@user))
  end

  # POST /api/v1/users
  # Create a new user
  def create
    user = User.new(user_params)

    if user.save
      render json: {
        success: true,
        message: "User created successfully",
        data: user_data(user)
      }, status: :created
    else
      render json: {
        success: false,
        message: "Failed to create user",
        errors: user.errors.full_messages
      }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def user_params
    params.require(:user).permit(:name)
  end

  def user_data(user)
    {
      id: user.id,
      name: user.name,
      created_at: user.created_at,
      updated_at: user.updated_at
    }
  end
end
