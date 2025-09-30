require 'rails_helper'

RSpec.describe 'Api::V1::Users', type: :request do
  describe 'GET /api/v1/users' do
    context 'when users exist' do
      let!(:users) { create_list(:user, 3) }

      it 'returns all users' do
        get '/api/v1/users'
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Success')
        expect(json_response['data']['users'].length).to eq(3)
        expect(json_response['data']['total_count']).to eq(3)
      end

      it 'returns users in alphabetical order by name' do
        users[0].update(name: 'Charlie')
        users[1].update(name: 'Alice')
        users[2].update(name: 'Bob')

        get '/api/v1/users'
        
        json_response = JSON.parse(response.body)
        user_names = json_response['data']['users'].map { |u| u['name'] }
        expect(user_names).to eq(['Alice', 'Bob', 'Charlie'])
      end

      it 'returns user data in correct format' do
        get '/api/v1/users'
        
        json_response = JSON.parse(response.body)
        user_data = json_response['data']['users'].first
        
        expect(user_data).to have_key('id')
        expect(user_data).to have_key('name')
        expect(user_data).to have_key('created_at')
      end
    end

    context 'when no users exist' do
      it 'returns empty array' do
        get '/api/v1/users'
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['data']['users']).to be_empty
        expect(json_response['data']['total_count']).to eq(0)
      end
    end
  end

  describe 'GET /api/v1/users/:id' do
    let(:user) { create(:user, name: 'John Doe') }

    context 'when user exists' do
      it 'returns the user' do
        get "/api/v1/users/#{user.id}"
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Success')
        expect(json_response['data']['name']).to eq('John Doe')
        expect(json_response['data']['id']).to eq(user.id)
      end
    end

    context 'when user does not exist' do
      it 'returns not found error' do
        get "/api/v1/users/999999"
        
        expect(response).to have_http_status(:not_found)
        
        json_response = JSON.parse(response.body)
        expect(json_response['error']).to eq('Record not found')
      end
    end
  end

  describe 'POST /api/v1/users' do
    context 'with valid parameters' do
      let(:valid_params) { { user: { name: 'Jane Smith' } } }

      it 'creates a new user' do
        expect {
          post '/api/v1/users', params: valid_params
        }.to change { User.count }.by(1)
      end

      it 'returns the created user' do
        post '/api/v1/users', params: valid_params
        
        expect(response).to have_http_status(:created)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('User created successfully')
        expect(json_response['data']['name']).to eq('Jane Smith')
        expect(json_response['data']['id']).to be_present
      end
    end

    context 'with invalid parameters' do
      context 'when name is missing' do
        let(:invalid_params) { { user: { name: '' } } }

        it 'does not create a user' do
          expect {
            post '/api/v1/users', params: invalid_params
          }.not_to change { User.count }
        end

        it 'returns validation errors' do
          post '/api/v1/users', params: invalid_params
          
          expect(response).to have_http_status(:unprocessable_entity)
          
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be false
          expect(json_response['message']).to eq('Failed to create user')
          expect(json_response['errors']).to include("Name can't be blank")
        end
      end

      context 'when name is too long' do
        let(:invalid_params) { { user: { name: 'a' * 101 } } }

        it 'returns validation errors' do
          post '/api/v1/users', params: invalid_params
          
          expect(response).to have_http_status(:unprocessable_entity)
          
          json_response = JSON.parse(response.body)
          expect(json_response['errors']).to include('Name is too long (maximum is 100 characters)')
        end
      end
    end

    context 'with nested parameters' do
      let(:nested_params) { { user: { name: 'Bob Johnson' } } }

      it 'creates a user with nested parameters' do
        expect {
          post '/api/v1/users', params: nested_params
        }.to change { User.count }.by(1)
        
        expect(response).to have_http_status(:created)
        
        json_response = JSON.parse(response.body)
        expect(json_response['data']['name']).to eq('Bob Johnson')
      end
    end
  end

  describe 'error handling' do
    context 'when unexpected error occurs' do
      before do
        allow_any_instance_of(Api::V1::UsersController).to receive(:index).and_raise(StandardError, 'Database error')
      end

      it 'returns internal server error' do
        expect { get '/api/v1/users' }.to raise_error(StandardError, 'Database error')
      end
    end
  end

  describe 'content type' do
    let(:user) { create(:user) }

    it 'returns JSON content type' do
      get '/api/v1/users'
      expect(response.content_type).to include('application/json')
    end

    it 'handles requests with JSON content type' do
      post '/api/v1/users', 
           params: { name: 'Test User' }.to_json,
           headers: { 'Content-Type' => 'application/json' }
      
      expect(response).to have_http_status(:created)
    end
  end
end
