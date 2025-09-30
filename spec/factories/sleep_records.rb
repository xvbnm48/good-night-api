FactoryBot.define do
  factory :sleep_record do
    association :user
    clock_in_time { 8.hours.ago }
    clock_out_time { nil }
    
    trait :completed do
      clock_out_time { 30.minutes.ago }
    end
    
    trait :in_progress do
      clock_out_time { nil }
    end
    
    trait :with_8_hours_sleep do
      clock_in_time { 8.hours.ago }
      clock_out_time { Time.current }
    end
    
    trait :yesterday do
      clock_in_time { 1.day.ago + 22.hours }
      clock_out_time { 1.day.ago + 30.hours }
    end
  end
end
