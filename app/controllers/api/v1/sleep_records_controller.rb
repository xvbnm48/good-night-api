class Api::V1::SleepRecordsController < Api::V1::BaseController
  before_action :set_user
  before_action :set_sleep_record, only: [:show]

  # POST /api/v1/users/:user_id/sleep_records/clock_in
  # Clock In operation - creates a new sleep record or clocks out an in-progress one
  def clock_in
    # Check if user has an in-progress sleep record
    in_progress_record = @user.sleep_records.in_progress.first

    if in_progress_record
      # Clock out the in-progress record
      in_progress_record.clock_out!
      render_success(
        sleep_record_data(in_progress_record),
        "Successfully clocked out"
      )
    else
      # Create new sleep record (clock in)
      sleep_record = @user.sleep_records.create!(clock_in_time: Time.current)
      render_success(
        sleep_record_data(sleep_record),
        "Successfully clocked in"
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    record_invalid(e)
  end

  # GET /api/v1/users/:user_id/sleep_records
  # Return all clocked-in times, ordered by created time
  def index
    page = params[:page].to_i > 0 ? params[:page].to_i : 1
    per_page = [ params[:per_page].to_i, 100 ].min.positive? ? [ params[:per_page].to_i, 100 ].min : 20
    offset = (page - 1) * per_page

    sleep_records = @user.sleep_records
                         .includes(:user)
                         .ordered_by_creation
                         .limit(per_page)
                         .offset(offset)

    total_count = @user.sleep_records.count

    render_success({
      sleep_records: sleep_records.map { |record| sleep_record_data(record) },
      pagination: {
        current_page: page,
        per_page: per_page,
        total_count: total_count,
        total_pages: (total_count.to_f / per_page).ceil,
        has_next_page: (page * per_page) < total_count,
        has_prev_page: page > 1
      }
    })
  end

  # GET /api/v1/users/:user_id/sleep_records/:id
  def show
    if @sleep_record
      render json: {
        success: true,
        message: 'Sleep record retrieved successfully',
        data: sleep_record_data(@sleep_record)
      }
    else
      render json: {
        success: false,
        message: 'Sleep record not found'
      }, status: :not_found
    end
  end

  # GET /api/v1/users/:user_id/sleep_records/following_sleep_records
  # See sleep records of all following users from previous week, sorted by duration
  def following_sleep_records
    following_users = @user.following

    sleep_records = SleepRecord
                      .joins(:user)
                      .where(user: following_users)
                      .completed
                      .for_week
                      .includes(:user)
                      .ordered_by_duration
                      .limit(100) # Limit for performance

    sleep_records_data = sleep_records.map { |record| sleep_record_data(record) }

    render_success({
      sleep_records: sleep_records_data,
      total_count: sleep_records_data.count,
      week_start: 1.week.ago.beginning_of_day
    })
  end

  private

  def set_user
    @user = User.find(params[:user_id])
  rescue ActiveRecord::RecordNotFound
    render json: {
      success: false,
      message: 'User not found'
    }, status: :not_found
  end

  def set_sleep_record
    @sleep_record = @user&.sleep_records&.find_by(id: params[:id])
  end

  def sleep_record_data(record)
    {
      id: record.id,
      user: {
        id: record.user.id,
        name: record.user.name
      },
      clock_in_time: record.clock_in_time,
      clock_out_time: record.clock_out_time,
      duration_hours: record.duration_in_hours,
      status: record.completed? ? "completed" : "in_progress",
      created_at: record.created_at,
      updated_at: record.updated_at
    }
  end
end
