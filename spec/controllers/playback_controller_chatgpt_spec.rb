# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PlaybackController, type: :request do
  describe 'GET #playback' do
    it 'should get playback' do
      recording = create(:recording)

      get "/playback/presentation/2.0/#{recording.record_id}"

      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET #playback resource' do
    it 'can serve js files' do
      recording = create(:recording, :published, state: 'published')
      playback_format = create(
        :playback_format,
        recording: recording,
        format: 'capture',
        url: "/capture/#{recording.record_id}/"
      )

      get "#{playback_format.url}capture.js"

      expect(response).to have_http_status(:success)

      expect(response.get_header('X-Accel-Redirect')).to eq("/static-resource#{playback_format.url}capture.js")
    end

    it 'renders a 404 page if the recording url is invalid' do
      get "/recording/invalid_recording_id/invalid_format"

      expect(response).to have_http_status(:not_found)
      expect(response).to render_template('errors/recording_not_found')
    end

    it 'protected recording without cookies blocks resource access if enabled' do
      recording = create(
        :recording,
        :published,
        state: 'published',
        protected: true
      )
      playback_format = create(
        :playback_format,
        recording: recording,
        format: 'presentation',
        url: "/playback/presentation/index.html?meetingID=#{recording.record_id}"
      )

      get "/#{playback_format.format}/#{recording.record_id}/slides.svg"
      expect(response).to have_http_status(:success)

      Rails.configuration.x.protected_recordings_enabled = true

      get "/#{playback_format.format}/#{recording.record_id}/slides.svg"
      expect(response).to have_http_status(:not_found)
      expect(response.has_header?('X-Accel-Redirect')).to be_falsey
    end
  end
end
