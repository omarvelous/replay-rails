require "rails_helper"

RSpec.describe "Analytics event integration", type: :model do # rubocop:disable RSpec/DescribeClass
  describe "governed event emission" do
    it "QrScanned.create calls Ahoy::Tracker#track with correct params" do
      tracker = instance_double(Ahoy::Tracker)
      allow(Ahoy::Tracker).to receive(:new).and_return(tracker)
      allow(tracker).to receive(:track)

      Analytics::Events::QrScanned.create(
        qr_code_pid: "a1b2c3d4",
        destination_url: "/go/listings/abc"
      )

      expect(tracker).to have_received(:track).with(
        "qr.scanned",
        hash_including(qr_code_pid: "a1b2c3d4", destination_url: "/go/listings/abc")
      )
    end

    it "ContentImpressed.create calls Ahoy::Tracker#track" do
      tracker = instance_double(Ahoy::Tracker)
      allow(Ahoy::Tracker).to receive(:new).and_return(tracker)
      allow(tracker).to receive(:track)

      Analytics::Events::ContentImpressed.create(
        ad_pid: "a1", screen_pid: "b2", screen_content_pid: "c3",
        playlist_pid: "d4", position: 1, duration: 10
      )

      expect(tracker).to have_received(:track).with(
        "content.impressed",
        hash_including(ad_pid: "a1", screen_pid: "b2", duration: 10)
      )
    end

    it "invalid event does not call Ahoy::Tracker#track" do
      tracker = instance_double(Ahoy::Tracker)
      allow(Ahoy::Tracker).to receive(:new).and_return(tracker)
      allow(tracker).to receive(:track)

      event = Analytics::Events::QrScanned.create(
        qr_code_pid: nil, destination_url: nil
      )

      expect(event.errors).to be_present
      expect(tracker).not_to have_received(:track)
    end
  end
end
