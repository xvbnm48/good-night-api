  class User < ApplicationRecord
  # Validations
  validates :name, presence: true, length: { minimum: 1, maximum: 100 }

  # Associations
  has_many :sleep_records, dependent: :destroy

  # Following relationships
  has_many :following_relationships, class_name: "UserFollowing", foreign_key: "follower_id", dependent: :destroy
  has_many :follower_relationships, class_name: "UserFollowing", foreign_key: "followed_id", dependent: :destroy

  has_many :following, through: :following_relationships, source: :followed
  has_many :followers, through: :follower_relationships, source: :follower

  # Scopes for performance
  scope :with_sleep_records, -> { includes(:sleep_records) }
  scope :with_following, -> { includes(:following) }

  # Instance methods
  def follow(user)
    return false if self == user || following?(user)

    following_relationships.create(followed: user)
  end

  def unfollow(user)
    following_relationships.find_by(followed: user)&.destroy
  end

  def following?(user)
    following.include?(user)
  end

  def sleep_duration_for_week(start_date = 1.week.ago)
    Rails.cache.fetch("user_#{id}_weekly_sleep_duration_#{start_date.to_date}", expires_in: 1.hour) do
      sleep_records
        .where("clock_in_time >= ? AND clock_out_time IS NOT NULL", start_date)
        .sum("julianday(clock_out_time) - julianday(clock_in_time)") * 86400 # Convert days to seconds
    end
  end

  # Cache following status for better performance
  def following_cached?(user)
    Rails.cache.fetch("user_#{id}_following_#{user.id}", expires_in: 30.minutes) do
      following?(user)
    end
  end

  private

  # Clear cache when following relationships change
  def clear_following_cache
    Rails.cache.delete_matched("user_#{id}_following_*")
    Rails.cache.delete_matched("user_#{id}_weekly_sleep_duration_*")
  end
  end
