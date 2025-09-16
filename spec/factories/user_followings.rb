FactoryBot.define do
  factory :user_following do
    follower { nil }
    followed { nil }
  end
end
