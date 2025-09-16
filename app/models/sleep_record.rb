class SleepRecord < ApplicationRecord
  belongs_to :user

  validates :clock_in_time, presence: true
  validates :clock_out_time, presence: true, if: :completed?
  validate :clock_out_after_clock_in, if: :clock_out_time?

  # Scopes
  scope :completed, -> { where.not(clock_out_time: nil) }
  scope :in_progress, -> { where(clock_out_time: nil) }
  scope :for_week, ->(start_date = 1.week.ago) { where("clock_in_time >= ?", start_date) }
  scope :ordered_by_creation, -> { order(:created_at) }
  scope :ordered_by_duration, -> { completed.order(Arel.sql("clock_out_time - clock_in_time DESC")) }

  def completed?
    clock_out_time.present?
  end

  def in_progress?
    clock_out_time.nil?
  end

  def duration_in_seconds
    return nil unless completed?

    (clock_out_time - clock_in_time).to_i
  end

  def duration_in_hours
    return nil unless completed?

    duration_in_seconds / 3600.0
  end

  def clock_out!
    update!(clock_out_time: Time.current)
  end

  private

  def clock_out_after_clock_in
    return unless clock_in_time && clock_out_time

    if clock_out_time <= clock_in_time
      errors.add(:clock_out_time, "must be after clock in time")
    end
  end
end
