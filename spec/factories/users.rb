FactoryBot.define do
  factory :user do
    name { Faker::Name.name }
    
    trait :with_sleep_records do
      after(:create) do |user|
        create_list(:sleep_record, 3, user: user)
      end
    end
    
    trait :with_completed_sleep_records do
      after(:create) do |user|
        create_list(:sleep_record, 2, :completed, user: user)
      end
    end
  end
end
