require 'rails_helper'

RSpec.describe SleepRecord, type: :model do
  describe 'validations' do
    it { should validate_presence_of(:clock_in_time) }
    it { should belong_to(:user) }

    describe 'clock_out_time validation' do
      context 'when sleep record is completed' do
        subject { build(:sleep_record, :completed) }
        
        it 'is valid with clock_out_time present' do
          expect(subject).to be_valid
        end
        
        it 'is invalid without clock_out_time when completed? returns true' do
          subject.clock_out_time = nil
          # Force the completed? method to return true to trigger validation
          allow(subject).to receive(:completed?).and_return(true)
          expect(subject).not_to be_valid
          expect(subject.errors[:clock_out_time]).to include("can't be blank")
        end
      end

      context 'when sleep record is in progress' do
        subject { build(:sleep_record, :in_progress) }
        it 'is valid without clock_out_time' do
          expect(subject).to be_valid
        end
      end
    end

    describe 'clock_out_after_clock_in validation' do
      let(:user) { create(:user) }

      it 'is invalid when clock_out_time is before clock_in_time' do
        sleep_record = build(:sleep_record, 
                           user: user,
                           clock_in_time: Time.current,
                           clock_out_time: 1.hour.ago)
        
        expect(sleep_record).not_to be_valid
        expect(sleep_record.errors[:clock_out_time]).to include('must be after clock in time')
      end

      it 'is invalid when clock_out_time equals clock_in_time' do
        time = Time.current
        sleep_record = build(:sleep_record, 
                           user: user,
                           clock_in_time: time,
                           clock_out_time: time)
        
        expect(sleep_record).not_to be_valid
        expect(sleep_record.errors[:clock_out_time]).to include('must be after clock in time')
      end

      it 'is valid when clock_out_time is after clock_in_time' do
        sleep_record = build(:sleep_record, 
                           user: user,
                           clock_in_time: 1.hour.ago,
                           clock_out_time: Time.current)
        
        expect(sleep_record).to be_valid
      end
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:sleep_record)).to be_valid
    end

    it 'creates a valid completed sleep record' do
      sleep_record = create(:sleep_record, :completed)
      expect(sleep_record).to be_valid
      expect(sleep_record.completed?).to be true
    end

    it 'creates a valid in-progress sleep record' do
      sleep_record = create(:sleep_record, :in_progress)
      expect(sleep_record).to be_valid
      expect(sleep_record.in_progress?).to be true
    end
  end

  describe 'scopes' do
    let(:user) { create(:user) }
    let!(:completed_record) { create(:sleep_record, :completed, user: user) }
    let!(:in_progress_record) { create(:sleep_record, :in_progress, user: user) }
    let!(:old_record) { create(:sleep_record, :completed, user: user, clock_in_time: 2.weeks.ago) }

    describe '.completed' do
      it 'returns only completed sleep records' do
        expect(SleepRecord.completed).to include(completed_record, old_record)
        expect(SleepRecord.completed).not_to include(in_progress_record)
      end
    end

    describe '.in_progress' do
      it 'returns only in-progress sleep records' do
        expect(SleepRecord.in_progress).to include(in_progress_record)
        expect(SleepRecord.in_progress).not_to include(completed_record, old_record)
      end
    end

    describe '.for_week' do
      it 'returns records from the past week' do
        records = SleepRecord.for_week
        expect(records).to include(completed_record, in_progress_record)
        expect(records).not_to include(old_record)
      end

      it 'accepts custom start date' do
        records = SleepRecord.for_week(3.weeks.ago)
        expect(records).to include(completed_record, in_progress_record, old_record)
      end
    end

    describe '.ordered_by_creation' do
      it 'orders records by created_at' do
        records = SleepRecord.ordered_by_creation
        expect(records.first.created_at).to be <= records.last.created_at
      end
    end

    describe '.ordered_by_duration' do
      let!(:short_sleep) { create(:sleep_record, user: user, 
                                 clock_in_time: 4.hours.ago, clock_out_time: 1.hour.ago) }
      let!(:long_sleep) { create(:sleep_record, user: user, 
                                clock_in_time: 10.hours.ago, clock_out_time: 2.hours.ago) }

      it 'orders completed records by duration descending' do
        records = SleepRecord.ordered_by_duration
        # Verify that records are ordered by duration (longest first)
        durations = records.map(&:duration_in_seconds)
        expect(durations).to eq(durations.sort.reverse)
      end

      it 'only includes completed records' do
        records = SleepRecord.ordered_by_duration
        expect(records).not_to include(in_progress_record)
        expect(records.all?(&:completed?)).to be true
      end
    end
  end

  describe 'instance methods' do
    describe '#completed?' do
      it 'returns true when clock_out_time is present' do
        sleep_record = build(:sleep_record, clock_out_time: Time.current)
        expect(sleep_record.completed?).to be true
      end

      it 'returns false when clock_out_time is nil' do
        sleep_record = build(:sleep_record, clock_out_time: nil)
        expect(sleep_record.completed?).to be false
      end
    end

    describe '#in_progress?' do
      it 'returns true when clock_out_time is nil' do
        sleep_record = build(:sleep_record, clock_out_time: nil)
        expect(sleep_record.in_progress?).to be true
      end

      it 'returns false when clock_out_time is present' do
        sleep_record = build(:sleep_record, clock_out_time: Time.current)
        expect(sleep_record.in_progress?).to be false
      end
    end

    describe '#duration_in_seconds' do
      context 'when completed' do
        it 'returns duration in seconds' do
          clock_in = 2.hours.ago
          clock_out = Time.current
          sleep_record = build(:sleep_record, 
                             clock_in_time: clock_in, 
                             clock_out_time: clock_out)
          
          expected_duration = (clock_out - clock_in).to_i
          expect(sleep_record.duration_in_seconds).to eq(expected_duration)
        end
      end

      context 'when in progress' do
        it 'returns nil' do
          sleep_record = build(:sleep_record, :in_progress)
          expect(sleep_record.duration_in_seconds).to be_nil
        end
      end
    end

    describe '#duration_in_hours' do
      context 'when completed' do
        it 'returns duration in hours' do
          clock_in = 8.hours.ago
          clock_out = Time.current
          sleep_record = build(:sleep_record, 
                             clock_in_time: clock_in, 
                             clock_out_time: clock_out)
          
          expect(sleep_record.duration_in_hours).to be_within(0.1).of(8.0)
        end
      end

      context 'when in progress' do
        it 'returns nil' do
          sleep_record = build(:sleep_record, :in_progress)
          expect(sleep_record.duration_in_hours).to be_nil
        end
      end
    end

    describe '#clock_out!' do
      let(:sleep_record) { create(:sleep_record, :in_progress) }

      it 'sets clock_out_time to current time' do
        freeze_time do
          sleep_record.clock_out!
          expect(sleep_record.clock_out_time).to be_within(1.second).of(Time.current)
        end
      end

      it 'saves the record' do
        sleep_record.clock_out!
        sleep_record.reload
        expect(sleep_record.clock_out_time).to be_present
      end

      it 'makes the record completed' do
        sleep_record.clock_out!
        expect(sleep_record.completed?).to be true
      end
    end
  end
end
