class Api::V1::UserFollowingsController < Api::V1::BaseController
  before_action :set_user

  # POST /api/v1/users/:user_id/followings
  # Follow another user
  def create
    followed_user = User.find(params[:followed_user_id])

    if @user.follow(followed_user)
      render_success(
        {
          follower: user_data(@user),
          followed: user_data(followed_user)
        },
        "Successfully followed user"
      )
    else
      render_error("Unable to follow user. You may already be following them or trying to follow yourself.")
    end
  rescue ActiveRecord::RecordNotFound
    render_error("User to follow not found", :not_found)
  end

  # DELETE /api/v1/users/:user_id/followings/:followed_user_id
  # Unfollow a user
  def destroy
    followed_user = User.find(params[:id])

    if @user.unfollow(followed_user)
      render_success(
        {
          follower: user_data(@user),
          unfollowed: user_data(followed_user)
        },
        "Successfully unfollowed user"
      )
    else
      render_error("Unable to unfollow user. You may not be following them.")
    end
  rescue ActiveRecord::RecordNotFound
    render_error("User to unfollow not found", :not_found)
  end

  # GET /api/v1/users/:user_id/followings
  # Get list of users that this user is following
  def index
    following_users = @user.following.order(:name)

    render_success({
      following: following_users.map { |user| user_data(user) },
      total_count: following_users.count
    })
  end

  # GET /api/v1/users/:user_id/followers
  # Get list of users that are following this user
  def followers
    follower_users = @user.followers.order(:name)

    render_success({
      followers: follower_users.map { |user| user_data(user) },
      total_count: follower_users.count
    })
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  end

  def user_data(user)
    {
      id: user.id,
      name: user.name
    }
  end
end
