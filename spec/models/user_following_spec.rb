require 'rails_helper'

RSpec.describe UserFollowing, type: :model do
  describe 'associations' do
    it { should belong_to(:follower).class_name('User') }
    it { should belong_to(:followed).class_name('User') }
  end

  describe 'validations' do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }

    describe 'uniqueness validation' do
      before { create(:user_following, follower: follower, followed: followed) }

      it 'prevents duplicate following relationships' do
        duplicate_following = build(:user_following, follower: follower, followed: followed)
        
        expect(duplicate_following).not_to be_valid
        expect(duplicate_following.errors[:follower_id]).to include('already following this user')
      end

      it 'allows following different users' do
        other_user = create(:user)
        new_following = build(:user_following, follower: follower, followed: other_user)
        
        expect(new_following).to be_valid
      end

      it 'allows different users to follow the same user' do
        other_follower = create(:user)
        new_following = build(:user_following, follower: other_follower, followed: followed)
        
        expect(new_following).to be_valid
      end
    end

    describe 'cannot follow self validation' do
      it 'prevents users from following themselves' do
        self_following = build(:user_following, follower: follower, followed: follower)
        
        expect(self_following).not_to be_valid
        expect(self_following.errors[:followed_id]).to include('cannot follow yourself')
      end

      it 'allows following different users' do
        following = build(:user_following, follower: follower, followed: followed)
        
        expect(following).to be_valid
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user_following)).to be_valid
    end

    it 'creates different users for follower and followed' do
      user_following = create(:user_following)
      expect(user_following.follower).not_to eq(user_following.followed)
    end
  end

  describe 'database constraints' do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }

    it 'enforces uniqueness at database level' do
      create(:user_following, follower: follower, followed: followed)
      
      expect {
        # Try to create duplicate using raw SQL to bypass validations
        ActiveRecord::Base.connection.execute(
          "INSERT INTO user_followings (follower_id, followed_id, created_at, updated_at) VALUES (#{follower.id}, #{followed.id}, '#{Time.current}', '#{Time.current}')"
        )
      }.to raise_error(ActiveRecord::StatementInvalid)
    end
  end

  describe 'cascade deletion' do
    let(:follower) { create(:user) }
    let(:followed) { create(:user) }
    let!(:user_following) { create(:user_following, follower: follower, followed: followed) }

    it 'deletes following relationship when follower is deleted' do
      expect { follower.destroy }.to change { UserFollowing.count }.by(-1)
    end

    it 'deletes following relationship when followed user is deleted' do
      expect { followed.destroy }.to change { UserFollowing.count }.by(-1)
    end
  end

  describe 'complex scenarios' do
    let(:user_a) { create(:user) }
    let(:user_b) { create(:user) }
    let(:user_c) { create(:user) }

    it 'allows mutual following relationships' do
      following_ab = create(:user_following, follower: user_a, followed: user_b)
      following_ba = create(:user_following, follower: user_b, followed: user_a)
      
      expect(following_ab).to be_valid
      expect(following_ba).to be_valid
      expect(UserFollowing.count).to eq(2)
    end

    it 'allows complex following networks' do
      # A follows B, B follows C, C follows A
      create(:user_following, follower: user_a, followed: user_b)
      create(:user_following, follower: user_b, followed: user_c)
      create(:user_following, follower: user_c, followed: user_a)
      
      expect(UserFollowing.count).to eq(3)
      expect(user_a.following).to include(user_b)
      expect(user_b.following).to include(user_c)
      expect(user_c.following).to include(user_a)
    end
  end
end
