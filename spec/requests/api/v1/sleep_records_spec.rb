require 'rails_helper'

RSpec.describe 'Api::V1::SleepRecords', type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  describe 'POST /api/v1/users/:user_id/sleep_records/clock_in' do
    context 'when user exists' do
      context 'with no existing sleep record (clock in)' do
        it 'creates a new sleep record' do
          expect {
            post "/api/v1/users/#{user.id}/sleep_records/clock_in"
          }.to change { user.sleep_records.count }.by(1)
        end

        it 'returns success response with sleep record data' do
          freeze_time do
            post "/api/v1/users/#{user.id}/sleep_records/clock_in"
            
            expect(response).to have_http_status(:ok)
            
            json_response = JSON.parse(response.body)
            expect(json_response['success']).to be true
            expect(json_response['message']).to eq('Successfully clocked in')
            expect(json_response['data']['status']).to eq('in_progress')
            expect(json_response['data']['clock_in_time']).to be_present
            expect(json_response['data']['clock_out_time']).to be_nil
          end
        end

        it 'creates sleep record with current timestamp' do
          freeze_time do
            post "/api/v1/users/#{user.id}/sleep_records/clock_in"
            
            sleep_record = user.sleep_records.last
            expect(sleep_record.clock_in_time).to be_within(1.second).of(Time.current)
            expect(sleep_record.clock_out_time).to be_nil
          end
        end
      end

      context 'with existing in-progress sleep record (clock out)' do
        let!(:in_progress_record) { create(:sleep_record, :in_progress, user: user) }

        it 'does not create a new sleep record' do
          expect {
            post "/api/v1/users/#{user.id}/sleep_records/clock_in"
          }.not_to change { user.sleep_records.count }
        end

        it 'updates the existing record with clock_out_time' do
          freeze_time do
            post "/api/v1/users/#{user.id}/sleep_records/clock_in"
            
            in_progress_record.reload
            expect(in_progress_record.clock_out_time).to be_within(1.second).of(Time.current)
            expect(in_progress_record.completed?).to be true
          end
        end

        it 'returns success response with updated sleep record' do
          post "/api/v1/users/#{user.id}/sleep_records/clock_in"
          
          expect(response).to have_http_status(:ok)
          
          json_response = JSON.parse(response.body)
          expect(json_response['success']).to be true
          expect(json_response['message']).to eq('Successfully clocked out')
          expect(json_response['data']['status']).to eq('completed')
          expect(json_response['data']['clock_out_time']).to be_present
          expect(json_response['data']['duration_hours']).to be_present
        end
      end
    end

    context 'when user does not exist' do
      it 'returns not found error' do
        post "/api/v1/users/999999/sleep_records/clock_in"
        
        expect(response).to have_http_status(:not_found)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('User not found')
      end
    end
  end

  describe 'GET /api/v1/users/:user_id/sleep_records' do
    context 'when user exists' do
      let!(:sleep_records) { create_list(:sleep_record, 3, :completed, user: user) }

      it 'returns user sleep records' do
        get "/api/v1/users/#{user.id}/sleep_records"
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['message']).to eq('Success')
        expect(json_response['data']['sleep_records'].size).to eq(3)
      end

      it 'orders records by creation time' do
        # Update created_at to ensure specific order
        sleep_records[0].update(created_at: 3.days.ago)
        sleep_records[1].update(created_at: 1.day.ago)
        sleep_records[2].update(created_at: 2.days.ago)

        get "/api/v1/users/#{user.id}/sleep_records"
        
        json_response = JSON.parse(response.body)
        returned_ids = json_response['data']['sleep_records'].map { |r| r['id'] }
        
        expect(returned_ids).to eq([sleep_records[0].id, sleep_records[2].id, sleep_records[1].id])
      end

      it 'includes pagination information' do
        get "/api/v1/users/#{user.id}/sleep_records"
        
        json_response = JSON.parse(response.body)
        pagination = json_response['data']['pagination']
        
        expect(pagination['current_page']).to eq(1)
        expect(pagination['per_page']).to eq(20)
        expect(pagination['total_count']).to eq(3)
        expect(pagination['total_pages']).to eq(1)
      end

      context 'with pagination parameters' do
        before { create_list(:sleep_record, 25, :completed, user: user) }

        it 'respects page parameter' do
          get "/api/v1/users/#{user.id}/sleep_records", params: { page: 2 }
          
          json_response = JSON.parse(response.body)
          pagination = json_response['data']['pagination']
          
          expect(pagination['current_page']).to eq(2)
          expect(json_response['data']['sleep_records'].count).to eq(8) # 28 total - 20 on first page
        end

        it 'respects per_page parameter' do
          get "/api/v1/users/#{user.id}/sleep_records", params: { per_page: 10 }
          
          json_response = JSON.parse(response.body)
          pagination = json_response['data']['pagination']
          
          expect(pagination['per_page']).to eq(10)
          expect(json_response['data']['sleep_records'].count).to eq(10)
        end

        it 'limits per_page to maximum of 100' do
          get "/api/v1/users/#{user.id}/sleep_records", params: { per_page: 150 }
          
          json_response = JSON.parse(response.body)
          pagination = json_response['data']['pagination']
          
          expect(pagination['per_page']).to eq(100)
        end
      end

      it 'returns correct sleep record format' do
        get "/api/v1/users/#{user.id}/sleep_records"
        
        json_response = JSON.parse(response.body)
        sleep_record_data = json_response['data']['sleep_records'].first
        
        expect(sleep_record_data).to have_key('id')
        expect(sleep_record_data).to have_key('user')
        expect(sleep_record_data['user']).to have_key('id')
        expect(sleep_record_data['user']).to have_key('name')
        expect(sleep_record_data).to have_key('clock_in_time')
        expect(sleep_record_data).to have_key('clock_out_time')
        expect(sleep_record_data).to have_key('duration_hours')
        expect(sleep_record_data).to have_key('status')
      end
    end

    context 'when user has no sleep records' do
      it 'returns empty array' do
        get "/api/v1/users/#{user.id}/sleep_records"
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['data']['sleep_records']).to be_empty
        expect(json_response['data']['pagination']['total_count']).to eq(0)
      end
    end

    context 'when user does not exist' do
      it 'returns not found error' do
        get "/api/v1/users/999999/sleep_records"
        
        expect(response).to have_http_status(:not_found)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('User not found')
      end
    end
  end

  describe 'GET /api/v1/users/:user_id/sleep_records/:id' do
    let(:sleep_record) { create(:sleep_record, :completed, user: user) }

    context 'when sleep record exists and belongs to user' do
      it 'returns the sleep record' do
        get "/api/v1/users/#{user.id}/sleep_records/#{sleep_record.id}"
        
        expect(response).to have_http_status(:ok)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be true
        expect(json_response['data']['id']).to eq(sleep_record.id)
      end
    end

    context 'when sleep record does not belong to user' do
      let(:other_sleep_record) { create(:sleep_record, :completed, user: other_user) }

      it 'returns not found error' do
        get "/api/v1/users/#{user.id}/sleep_records/#{other_sleep_record.id}"
        
        expect(response).to have_http_status(:not_found)
        
        json_response = JSON.parse(response.body)
        expect(json_response['success']).to be false
        expect(json_response['message']).to eq('Sleep record not found')
      end
    end

    context 'when sleep record does not exist' do
      it 'returns not found error' do
        get "/api/v1/users/#{user.id}/sleep_records/999999"
        
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'GET /api/v1/users/:user_id/sleep_records/following_sleep_records' do
    let(:followed_user1) { create(:user) }
    let(:followed_user2) { create(:user) }
    let(:unfollowed_user) { create(:user) }

    before do
      user.follow(followed_user1)
      user.follow(followed_user2)
      
      # Create sleep records for followed users
      create(:sleep_record, :completed, user: followed_user1, 
             clock_in_time: 10.hours.ago, clock_out_time: 2.hours.ago) # 8 hours
      create(:sleep_record, :completed, user: followed_user2, 
             clock_in_time: 12.hours.ago, clock_out_time: 2.hours.ago) # 10 hours
      
      # Create sleep record for unfollowed user (should not appear)
      create(:sleep_record, :completed, user: unfollowed_user, 
             clock_in_time: 8.hours.ago, clock_out_time: 1.hour.ago)
    end

    it 'returns sleep records from followed users only' do
      get "/api/v1/users/#{user.id}/sleep_records/following_sleep_records"
      
      expect(response).to have_http_status(:ok)
      
      json_response = JSON.parse(response.body)
      expect(json_response['success']).to be true
      expect(json_response['data']['sleep_records'].size).to eq(2)
      
      user_ids = json_response['data']['sleep_records'].map { |r| r['user']['id'] }
      expect(user_ids).to contain_exactly(followed_user1.id, followed_user2.id)
    end

    it 'orders records by sleep duration (longest first)' do
      get "/api/v1/users/#{user.id}/sleep_records/following_sleep_records"
      
      json_response = JSON.parse(response.body)
      durations = json_response['data']['sleep_records'].map { |r| r['duration_hours'] }
      
      expect(durations).to eq(durations.sort.reverse)
      expect(durations.first).to be > durations.last
    end

    it 'includes user information in response' do
      get "/api/v1/users/#{user.id}/sleep_records/following_sleep_records"
      
      json_response = JSON.parse(response.body)
      first_record = json_response['data']['sleep_records'].first
      
      expect(first_record['user']).to have_key('id')
      expect(first_record['user']).to have_key('name')
    end

    context 'when user follows no one' do
      before { user.following_relationships.destroy_all }

      it 'returns empty array' do
        get "/api/v1/users/#{user.id}/sleep_records/following_sleep_records"
        
        json_response = JSON.parse(response.body)
        expect(json_response['data']['sleep_records']).to be_empty
      end
    end

    context 'when followed users have no completed sleep records' do
      before { SleepRecord.update_all(clock_out_time: nil) }

      it 'returns empty array' do
        get "/api/v1/users/#{user.id}/sleep_records/following_sleep_records"
        
        json_response = JSON.parse(response.body)
        expect(json_response['data']['sleep_records']).to be_empty
      end
    end
  end
end
