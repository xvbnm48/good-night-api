FactoryBot.define do
  factory :user_following do
    follower { create(:user) }
    followed { create(:user) }
  end
end
