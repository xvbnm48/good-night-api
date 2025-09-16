class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Composite index for sleep records query optimization
    add_index :sleep_records, [ :user_id, :clock_out_time, :clock_in_time ],
              name: 'index_sleep_records_on_user_and_times'

    # Index for weekly sleep records query
    add_index :sleep_records, [ :clock_in_time, :clock_out_time ],
              where: 'clock_out_time IS NOT NULL',
              name: 'index_sleep_records_completed_by_time'

    # Optimize user following queries
    add_index :user_followings, [ :followed_id, :created_at ],
              name: 'index_user_followings_on_followed_and_created'
  end
end
