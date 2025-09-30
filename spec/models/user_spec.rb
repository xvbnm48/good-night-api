require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:name).is_at_least(1) }
    it { should validate_length_of(:name).is_at_most(100) }
  end

  describe 'associations' do
    it { should have_many(:sleep_records).dependent(:destroy) }
    it { should have_many(:following_relationships).class_name('UserFollowing').with_foreign_key('follower_id').dependent(:destroy) }
    it { should have_many(:follower_relationships).class_name('UserFollowing').with_foreign_key('followed_id').dependent(:destroy) }
    it { should have_many(:following).through(:following_relationships).source(:followed) }
    it { should have_many(:followers).through(:follower_relationships).source(:follower) }
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end

    it 'creates a valid user with traits' do
      user = create(:user, :with_sleep_records)
      expect(user).to be_valid
      expect(user.sleep_records.count).to eq(3)
    end
  end

  describe '#follow' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    context 'when following a different user' do
      it 'creates a following relationship' do
        expect { user.follow(other_user) }.to change { user.following.count }.by(1)
      end

      it 'returns the created user_following record' do
        result = user.follow(other_user)
        expect(result).to be_a(UserFollowing)
        expect(result.persisted?).to be true
      end
    end

    context 'when trying to follow self' do
      it 'returns false' do
        expect(user.follow(user)).to be false
      end

      it 'does not create a following relationship' do
        expect { user.follow(user) }.not_to change { user.following.count }
      end
    end

    context 'when already following the user' do
      before { user.follow(other_user) }

      it 'returns false' do
        expect(user.follow(other_user)).to be false
      end

      it 'does not create a duplicate relationship' do
        expect { user.follow(other_user) }.not_to change { user.following.count }
      end
    end
  end

  describe '#unfollow' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    context 'when following the user' do
      before { user.follow(other_user) }

      it 'removes the following relationship' do
        expect { user.unfollow(other_user) }.to change { user.following.count }.by(-1)
      end

      it 'returns the destroyed relationship' do
        result = user.unfollow(other_user)
        expect(result).to be_truthy
      end
    end

    context 'when not following the user' do
      it 'returns nil' do
        expect(user.unfollow(other_user)).to be_nil
      end

      it 'does not change following count' do
        expect { user.unfollow(other_user) }.not_to change { user.following.count }
      end
    end
  end

  describe '#following?' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }

    context 'when following the user' do
      before { user.follow(other_user) }

      it 'returns true' do
        expect(user.following?(other_user)).to be true
      end
    end

    context 'when not following the user' do
      it 'returns false' do
        expect(user.following?(other_user)).to be false
      end
    end
  end

  describe '#sleep_duration_for_week' do
    let(:user) { create(:user) }

    context 'with completed sleep records in the past week' do
      before do
        # Create sleep records with known durations
        create(:sleep_record, :completed, user: user, 
               clock_in_time: 2.days.ago, clock_out_time: 2.days.ago + 8.hours)
        create(:sleep_record, :completed, user: user, 
               clock_in_time: 3.days.ago, clock_out_time: 3.days.ago + 7.hours)
      end

      it 'calculates total sleep duration for the week' do
        duration = user.sleep_duration_for_week
        expect(duration).to be > 0
        # Should be approximately 15 hours in seconds (8 + 7 hours)
        expect(duration).to be_within(3600).of(15 * 3600)
      end
    end

    context 'with no completed sleep records' do
      it 'returns 0' do
        expect(user.sleep_duration_for_week).to eq(0)
      end
    end

    context 'with sleep records older than a week' do
      before do
        create(:sleep_record, :completed, user: user, 
               clock_in_time: 2.weeks.ago, clock_out_time: 2.weeks.ago + 8.hours)
      end

      it 'excludes old records' do
        expect(user.sleep_duration_for_week).to eq(0)
      end
    end
  end

  describe 'scopes' do
    describe '.with_sleep_records' do
      let!(:user_with_records) { create(:user, :with_sleep_records) }
      let!(:user_without_records) { create(:user) }

      it 'includes sleep_records association' do
        users = User.with_sleep_records
        expect(users).to include(user_with_records)
        # Test that association is loaded by checking if it's loaded
        user = users.find(user_with_records.id)
        expect(user.association(:sleep_records).loaded?).to be true
      end
    end

    describe '.with_following' do
      let!(:user) { create(:user) }
      let!(:other_user) { create(:user) }

      before { user.follow(other_user) }

      it 'includes following association' do
        users = User.with_following
        expect(users).to include(user)
        # Test that association is loaded by checking if it's loaded
        user_record = users.find(user.id)
        expect(user_record.association(:following).loaded?).to be true
      end
    end
  end
end
