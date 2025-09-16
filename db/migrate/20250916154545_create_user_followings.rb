class CreateUserFollowings < ActiveRecord::Migration[8.0]
  def change
    create_table :user_followings do |t|
      t.references :follower, null: false, foreign_key: { to_table: :users }
      t.references :followed, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :user_followings, [ :follower_id, :followed_id ], unique: true, if_not_exists: true
    add_index :user_followings, :followed_id, if_not_exists: true
  end
end
