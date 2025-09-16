# Create sample users
puts "Creating sample users..."

users = []
user_names = [ "Alice", "Bob", "Charlie", "Diana", "Eva" ]

user_names.each do |name|
  user = User.find_or_create_by(name: name)
  users << user
  puts "Created user: #{user.name}"
end

# Create some following relationships
puts "\nCreating following relationships..."

users[0].follow(users[1]) # Alice follows Bob
users[0].follow(users[2]) # Alice follows Charlie
users[1].follow(users[0]) # Bob follows Alice
users[1].follow(users[3]) # Bob follows Diana
users[2].follow(users[1]) # Charlie follows Bob
users[3].follow(users[4]) # Diana follows Eva

puts "Alice follows: #{users[0].following.pluck(:name).join(', ')}"
puts "Bob follows: #{users[1].following.pluck(:name).join(', ')}"
puts "Charlie follows: #{users[2].following.pluck(:name).join(', ')}"
puts "Diana follows: #{users[3].following.pluck(:name).join(', ')}"

# Create some sample sleep records
puts "\nCreating sample sleep records..."

# Create records from past week
[ 6, 5, 4, 3, 2, 1 ].each do |days_ago|
  users.each_with_index do |user, index|
    # Vary sleep times to make it interesting
    base_hour = 22 + (index % 3) # Keep hours between 22-24
    clock_in = days_ago.days.ago.change(hour: base_hour, min: 0)
    clock_out = clock_in + (7 + rand(3)).hours # Sleep 7-10 hours

    sleep_record = user.sleep_records.create!(
      clock_in_time: clock_in,
      clock_out_time: clock_out
    )

    puts "#{user.name} slept from #{clock_in.strftime('%Y-%m-%d %H:%M')} to #{clock_out.strftime('%Y-%m-%d %H:%M')} (#{sleep_record.duration_in_hours.round(1)} hours)"
  end
end

# Create one in-progress sleep record for Alice
alice = users[0]
in_progress = alice.sleep_records.create!(clock_in_time: 2.hours.ago)
puts "\nAlice has an in-progress sleep record from #{in_progress.clock_in_time.strftime('%Y-%m-%d %H:%M')}"

puts "\nSeed data created successfully!"
puts "Total users: #{User.count}"
puts "Total sleep records: #{SleepRecord.count}"
puts "Total following relationships: #{UserFollowing.count}"
