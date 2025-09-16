class User < ApplicationRecord
  validates :name, presence: true, length: { minimum: 1, maximum: 100 }

  has_many :sleep_records, dependent: :destroy

  has_many :following_relationships, class_name: "UserFollowing", foreign_key: "follower_id", dependent: :destroy
  has_many :follower_relationships, class_name: "UserFollowing", foreign_key: "followed_id", dependent: :destroy

  has_many :following, through: :following_relationships, source: :followed
  has_many :followers, through: :follower_relationships, source: :follower

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
    sleep_records
      .where("clock_in_time >= ? AND clock_out_time IS NOT NULL", start_date)
      .sum("EXTRACT(EPOCH FROM (clock_out_time - clock_in_time))")
  end
end
