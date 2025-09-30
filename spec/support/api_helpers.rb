module ApiHelpers
  def json_response
    @json_response ||= JSON.parse(response.body)
  end

  def expect_successful_response(message = nil)
    expect(response).to have_http_status(:ok)
    expect(json_response['success']).to be true
    expect(json_response['message']).to eq(message) if message
  end

  def expect_created_response(message = nil)
    expect(response).to have_http_status(:created)
    expect(json_response['success']).to be true
    expect(json_response['message']).to eq(message) if message
  end

  def expect_error_response(status = :unprocessable_entity, message = nil)
    expect(response).to have_http_status(status)
    expect(json_response['success']).to be false
    expect(json_response['message']).to eq(message) if message
  end

  def expect_not_found_response(message = nil)
    expect_error_response(:not_found, message)
  end

  def post_json(path, params = {})
    post path, params: params.to_json, headers: { 'Content-Type' => 'application/json' }
  end

  def put_json(path, params = {})
    put path, params: params.to_json, headers: { 'Content-Type' => 'application/json' }
  end

  def patch_json(path, params = {})
    patch path, params: params.to_json, headers: { 'Content-Type' => 'application/json' }
  end
end

RSpec.configure do |config|
  config.include ApiHelpers, type: :request
end
