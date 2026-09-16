require "rails_helper"

RSpec.describe "Governed Events", type: :model do # rubocop:disable RSpec/DescribeClass
  shared_examples "validates required properties" do |event_class, valid_attrs, required_keys|
    it "accepts valid attributes" do
      event = event_class.new(valid_attrs)
      expect(event).to be_valid
    end

    required_keys.each do |key|
      it "requires #{key}" do
        event = event_class.new(valid_attrs.except(key))
        expect(event).not_to be_valid
        expect(event.errors[key]).to include("can't be blank")
      end
    end

    it "has the correct event_name" do
      expect(event_class.event_name).to be_present
      expect(event_class.event_name).to include(".")
    end
  end

  describe Analytics::Events::QrScanned do
    it_behaves_like "validates required properties",
      described_class,
      { qr_code_pid: "a1b2c3d4", destination_url: "/go/listings/abc" },
      %i[qr_code_pid destination_url]

    it "has only qr_code_pid and destination_url attributes" do
      event = described_class.new(qr_code_pid: "a1b2c3d4", destination_url: "/go/listings/abc")
      expect(event).to be_valid
      expect(event.send(:properties)).to eq({ qr_code_pid: "a1b2c3d4", destination_url: "/go/listings/abc" })
    end
  end

  describe Analytics::Events::ContentImpressed do
    it_behaves_like "validates required properties",
      described_class,
      { ad_pid: "a1", screen_pid: "b2", screen_content_pid: "c3", playlist_pid: "d4", position: 1, duration: 10 },
      %i[ad_pid screen_pid screen_content_pid playlist_pid position duration]
  end

  describe Analytics::Events::ContentLoaded do
    it_behaves_like "validates required properties",
      described_class,
      { screen_pid: "a1", screen_content_pid: "b2", content_type: "playlist", content_pid: "c3" },
      %i[screen_pid screen_content_pid content_type content_pid]
  end

  describe Analytics::Events::InteractionStarted do
    it_behaves_like "validates required properties",
      described_class,
      { experience_pid: "a1", screen_pid: "b2", screen_content_pid: "c3" },
      %i[experience_pid screen_pid screen_content_pid]
  end

  describe Analytics::Events::InteractionEnded do
    it_behaves_like "validates required properties",
      described_class,
      { experience_pid: "a1", screen_pid: "b2", screen_content_pid: "c3", duration: 45 },
      %i[experience_pid screen_pid screen_content_pid duration]
  end

  describe Analytics::Events::InteractionNavigated do
    it_behaves_like "validates required properties",
      described_class,
      { experience_pid: "a1", screen_content_pid: "b2", direction: "next", photo_index: 3 },
      %i[experience_pid screen_content_pid direction photo_index]
  end

  describe Analytics::Events::InteractionOpened do
    it_behaves_like "validates required properties",
      described_class,
      { experience_pid: "a1", screen_content_pid: "b2", target: "floor_plan" },
      %i[experience_pid screen_content_pid target]
  end

  describe Analytics::Events::InteractionClosed do
    it_behaves_like "validates required properties",
      described_class,
      { experience_pid: "a1", screen_content_pid: "b2", target: "floor_plan", view_duration: 16 },
      %i[experience_pid screen_content_pid target view_duration]
  end

  describe Analytics::Events::DeviceConnected do
    it_behaves_like "validates required properties",
      described_class,
      { screen_pid: "a1", player_token: "abc123" },
      %i[screen_pid player_token]
  end
end
