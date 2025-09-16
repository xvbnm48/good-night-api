class Api::V1::BaseController < ApplicationController
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :record_invalid

  private
  def record_not_found(exception)
    render json: { error: "Record not found", message: exception.message }, status: :not_found
  end

  def record_invalid(exception)
    render json: { error: "Validation failed", errors: exception.record.errors.full_messages }, status: :unprocessable_entity
  end

  def render_success(data = {}, message = "Success")
    render json: { success: true, message: message, data: data }
  end

  def render_error(message, status = :unprocessable_entity)
    render json: { success: false, error: message }, status: status
  end
end
