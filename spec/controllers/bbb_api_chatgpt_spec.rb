# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BigBlueButtonApiController, type: :request do
  include BBBErrors
  include ApiHelper

  describe 'GET #index' do
    before do
      allow_any_instance_of(BigBlueButtonApiController).to receive(:verify_checksum).and_return(nil)
    end

    it 'responds with only success and version for a get request' do
      Rails.configuration.x.build_number = nil

      get bigbluebutton_api_url
      response_xml = Nokogiri::XML(response.body)

      expect(response_xml.at_xpath('/response/returncode').text).to eq('SUCCESS')
      expect(response_xml.at_xpath('/response/version').text).to eq('2.0')
      expect(response_xml.at_xpath('/response/build')).to be_nil
      expect(response).to have_http_status(:success)
    end

    it 'responds with only success and version for a post request' do
      Rails.configuration.x.build_number = nil

      post bigbluebutton_api_url
      response_xml = Nokogiri::XML(response.body)

      expect(response_xml.at_xpath('/response/returncode').text).to eq('SUCCESS')
      expect(response_xml.at_xpath('/response/version').text).to eq('2.0')
      expect(response_xml.at_xpath('/response/build')).to be_nil
      expect(response).to have_http_status(:success)
    end

    it 'includes build in response if env variable is set' do
      Rails.configuration.x.build_number = 'alpha-1'

      get bigbluebutton_api_url
      response_xml = Nokogiri::XML(response.body)

      expect(response_xml.at_xpath('/response/returncode').text).to eq('SUCCESS')
      expect(response_xml.at_xpath('/response/version').text).to eq('2.0')
      expect(response_xml.at_xpath('/response/build').text).to eq('alpha-1')
      expect(response).to have_http_status(:success)
    end
  end

  describe 'GET and POST #getMeetingInfo' do
    let(:server) { Server.create!(url: 'https://test-1.example.com/bigbluebutton/api/', secret: 'test-1') }

    context 'when the meeting exists' do
      let!(:meeting) { Meeting.create!(id: 'test-meeting-1', server: server) }

      it 'responds with the correct meeting info for a post request' do
        checksum = Digest::SHA1.hexdigest("getMeetingInfo#{meeting.id}#{server.secret}")
        url = "#{server.url}getMeetingInfo?meetingID=#{meeting.id}&checksum=#{checksum}"
        stub_request(:get, url)
          .to_return(body: "<response><returncode>SUCCESS</returncode><meetingID>#{meeting.id}</meetingID></response>")

        post bigbluebutton_api_get_meeting_info_url, params: { meetingID: 'test-meeting-1' }

        response_xml = Nokogiri::XML(response.body)
        expect(response_xml.at_xpath('/response/returncode').content).to eq('SUCCESS')
        expect(response_xml.at_xpath('/response/meetingID').content).to eq('test-meeting-1')
      end

      it 'responds with the correct meeting info for a get request' do
        checksum = Digest::SHA1.hexdigest("getMeetingInfo#{meeting.id}#{server.secret}")
        url = "#{server.url}getMeetingInfo?meetingID=#{meeting.id}&checksum=#{checksum}"
        stub_request(:get, url)
          .to_return(body: "<response><returncode>SUCCESS</returncode><meetingID>#{meeting.id}</meetingID></response>")

        get bigbluebutton_api_get_meeting_info_url, params: { meetingID: 'test-meeting-1' }

        response_xml = Nokogiri::XML(response.body)
        expect(response_xml.at_xpath('/response/returncode').content).to eq('SUCCESS')
        expect(response_xml.at_xpath('/response/meetingID').content).to eq('test-meeting-1')
      end
    end
  end

end
