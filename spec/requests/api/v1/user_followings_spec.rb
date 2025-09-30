require 'rails_helper'

RSpec.describe 'Api::V1::UserFollowings', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:third_user) { create(:user) }

  describe 'POST /api/v1/users/:user_id/followings' do
    context 'when user exists' do
      context 'with valid followed_user_id' do
        let(:valid_params) { { followed_user_id: other_user.id } }

        it 'creates a following relationship' do
          expect {
            post "/api/v1/users/#{user.id}/followings", params: valid_params
          }.to change { user.following.count }.by(1)
        end

        it 'returns success response' do
          post "/api/v1/users/#{user.id}/followings", params: valid_params
          
          expect(response).to have_http_status(:ok)
          
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be true
          expect(json_response['message']).to eq('Successfully followed user')
          expect(json_response['data']['follower']['id']).to eq(user.id)
          expect(json_response['data']['followed']['id']).to eq(other_user.id)
        end

        it 'includes user data in response' do
          post "/api/v1/users/#{user.id}/followings", params: valid_params
          
          json_response = JSON.parse(response.body)
          
          expect(json_response['data']['follower']).to have_key('name')
          expect(json_response['data']['followed']).to have_key('name')
        end
      end

      context 'when trying to follow self' do
        let(:self_follow_params) { { followed_user_id: user.id } }

        it 'does not create a following relationship' do
          expect {
            post "/api/v1/users/#{user.id}/followings", params: self_follow_params
          }.not_to change { user.following.count }
        end

        it 'returns error response' do
          post "/api/v1/users/#{user.id}/followings", params: self_follow_params
          
          expect(response).to have_http_status(:unprocessable_entity)
          
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be false
          expect(json_response['message']).to eq('Unable to follow user. You may already be following them or trying to follow yourself.')
        end
      end

      context 'when already following the user' do
        before { user.follow(other_user) }

        let(:duplicate_params) { { followed_user_id: other_user.id } }

        it 'does not create a duplicate relationship' do
          expect {
            post "/api/v1/users/#{user.id}/followings", params: duplicate_params
          }.not_to change { user.following.count }
        end

        it 'returns error response' do
          post "/api/v1/users/#{user.id}/followings", params: duplicate_params
          
          expect(response).to have_http_status(:unprocessable_entity)
          
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be false
          expect(json_response['message']).to eq('Unable to follow user. You may already be following them or trying to follow yourself.')
        end
      end

      context 'when followed_user_id does not exist' do
        let(:invalid_params) { { followed_user_id: 999999 } }

        it 'returns not found error' do
          post "/api/v1/users/#{user.id}/followings", params: invalid_params
          
          expect(response).to have_http_status(:not_found)
          
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be false
          expect(json_response['message']).to eq('User to follow not found')
        end
      end

      context 'with missing followed_user_id' do
        it 'returns error' do
          post "/api/v1/users/#{user.id}/followings", params: {}
          
          expect(response).to have_http_status(:not_found)
        end
      end
    end

    context 'when user does not exist' do
      it 'returns not found error' do
        post "/api/v1/users/999999/followings", params: { followed_user_id: other_user.id }
        
        expect(response).to have_http_status(:not_found)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('User not found')
      end
    end
  end

  describe 'GET /api/v1/users/:user_id/followings' do
    context 'when user exists' do
      before do
        user.follow(other_user)
        user.follow(third_user)
      end

      it 'returns users that the current user is following' do
        get "/api/v1/users/#{user.id}/followings"
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Following list retrieved successfully')
        expect(json_response['data']['following']).to have(2).items
        expect(json_response['data']['total_count']).to eq(2)
      end

      it 'returns correct user data format' do
        get "/api/v1/users/#{user.id}/followings"
        
        json_response = JSON.parse(response.body)
        user_data = json_response['data']['following'].first
        
        expect(user_data).to have_key('id')
        expect(user_data).to have_key('name')
        expect(user_data).to have_key('created_at')
      end

      it 'orders users by name' do
        other_user.update(name: 'Charlie')
        third_user.update(name: 'Alice')
        
        get "/api/v1/users/#{user.id}/followings"
        
        json_response = JSON.parse(response.body)
        user_names = json_response['data']['following'].map { |u| u['name'] }
        expect(user_names).to eq(['Alice', 'Charlie'])
      end
    end

    context 'when user follows no one' do
      it 'returns empty array' do
        get "/api/v1/users/#{user.id}/followings"
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['data']['following']).to be_empty
        expect(json_response['data']['total_count']).to eq(0)
      end
    end

    context 'when user does not exist' do
      it 'returns not found error' do
        get "/api/v1/users/999999/followings"
        
        expect(response).to have_http_status(:not_found)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('User not found')
      end
    end
  end

  describe 'GET /api/v1/users/:user_id/followings/followers' do
    context 'when user exists' do
      before do
        other_user.follow(user)
        third_user.follow(user)
      end

      it 'returns users that follow the current user' do
        get "/api/v1/users/#{user.id}/followings/followers"
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Followers list retrieved successfully')
        expect(json_response['data']['followers']).to have(2).items
        expect(json_response['data']['total_count']).to eq(2)
      end

      it 'returns correct user data format' do
        get "/api/v1/users/#{user.id}/followings/followers"
        
        json_response = JSON.parse(response.body)
        user_data = json_response['data']['followers'].first
        
        expect(user_data).to have_key('id')
        expect(user_data).to have_key('name')
        expect(user_data).to have_key('created_at')
      end

      it 'orders followers by name' do
        other_user.update(name: 'Zoe')
        third_user.update(name: 'Bob')
        
        get "/api/v1/users/#{user.id}/followings/followers"
        
        json_response = JSON.parse(response.body)
        user_names = json_response['data']['followers'].map { |u| u['name'] }
        expect(user_names).to eq(['Bob', 'Zoe'])
      end
    end

    context 'when user has no followers' do
      it 'returns empty array' do
        get "/api/v1/users/#{user.id}/followings/followers"
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['data']['followers']).to be_empty
        expect(json_response['data']['total_count']).to eq(0)
      end
    end

    context 'when user does not exist' do
      it 'returns not found error' do
        get "/api/v1/users/999999/followings/followers"
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'DELETE /api/v1/users/:user_id/followings/:id' do
    context 'when user exists and is following the target user' do
      before { user.follow(other_user) }

      it 'removes the following relationship' do
        expect {
          delete "/api/v1/users/#{user.id}/followings/#{other_user.id}"
        }.to change { user.following.count }.by(-1)
      end

      it 'returns success response' do
        delete "/api/v1/users/#{user.id}/followings/#{other_user.id}"
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Successfully unfollowed user')
        expect(json_response['data']['follower']['id']).to eq(user.id)
        expect(json_response['data']['unfollowed']['id']).to eq(other_user.id)
      end
    end

    context 'when user is not following the target user' do
      it 'returns error response' do
        delete "/api/v1/users/#{user.id}/followings/#{other_user.id}"
        
        expect(response).to have_http_status(:unprocessable_entity)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('You are not following this user')
      end
    end

    context 'when target user does not exist' do
      it 'returns not found error' do
        delete "/api/v1/users/#{user.id}/followings/999999"
        
        expect(response).to have_http_status(:not_found)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('User to unfollow not found')
      end
    end

    context 'when user does not exist' do
      it 'returns not found error' do
        delete "/api/v1/users/999999/followings/#{other_user.id}"
        
        expect(response).to have_http_status(:not_found)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('User not found')
      end
    end
  end

  describe 'complex following scenarios' do
    let(:user_a) { create(:user, name: 'Alice') }
    let(:user_b) { create(:user, name: 'Bob') }
    let(:user_c) { create(:user, name: 'Charlie') }

    context 'mutual following' do
      before do
        user_a.follow(user_b)
        user_b.follow(user_a)
      end

      it 'allows mutual following relationships' do
        get "/api/v1/users/#{user_a.id}/followings"
        json_a = JSON.parse(response.body)
        
        get "/api/v1/users/#{user_b.id}/followings"
        json_b = JSON.parse(response.body)
        
        expect(json_a['data']['following'].first['id']).to eq(user_b.id)
        expect(json_b['data']['following'].first['id']).to eq(user_a.id)
      end

      it 'shows mutual relationships in followers' do
        get "/api/v1/users/#{user_a.id}/followings/followers"
        json_a = JSON.parse(response.body)
        
        get "/api/v1/users/#{user_b.id}/followings/followers"
        json_b = JSON.parse(response.body)
        
        expect(json_a['data']['followers'].first['id']).to eq(user_b.id)
        expect(json_b['data']['followers'].first['id']).to eq(user_a.id)
      end
    end

    context 'following network' do
      before do
        user_a.follow(user_b)
        user_b.follow(user_c)
        user_c.follow(user_a)
      end

      it 'maintains separate following lists' do
        get "/api/v1/users/#{user_a.id}/followings"
        json_a = JSON.parse(response.body)
        
        get "/api/v1/users/#{user_b.id}/followings"
        json_b = JSON.parse(response.body)
        
        get "/api/v1/users/#{user_c.id}/followings"
        json_c = JSON.parse(response.body)
        
        expect(json_a['data']['following'].first['id']).to eq(user_b.id)
        expect(json_b['data']['following'].first['id']).to eq(user_c.id)
        expect(json_c['data']['following'].first['id']).to eq(user_a.id)
      end
    end
  end

  describe 'edge cases and error handling' do
    context 'with invalid JSON in request body' do
      it 'handles malformed JSON gracefully' do
        post "/api/v1/users/#{user.id}/followings",
             params: 'invalid json',
             headers: { 'Content-Type' => 'application/json' }
        
        expect(response).to have_http_status(:bad_request)
      rescue JSON::ParserError, ActionDispatch::Http::Parameters::ParseError
        expect(response).to have_http_status(:bad_request)
      end
    end

    context 'with very large user IDs' do
      it 'handles large IDs gracefully' do
        huge_id = 999999999999999999
        post "/api/v1/users/#{user.id}/followings", params: { followed_user_id: huge_id }
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
