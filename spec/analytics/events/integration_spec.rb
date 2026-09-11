require "rails_helper"

RSpec.describe "Analytics event integration", type: :model do # rubocop:disable RSpec/DescribeClass
  describe "governed event emission" do
    it "QrScanned.create calls Ahoy::Tracker#track with correct params" do
      tracker = instance_double(Ahoy::Tracker)
      allow(Ahoy::Tracker).to receive(:new).and_return(tracker)
      allow(tracker).to receive(:track)

      Analytics::Events::QrScanned.create(
        qr_code_id: 1,
        destination_url: "/go/listings/1"
      )

      expect(tracker).to have_received(:track).with(
        "qr.scanned",
        hash_including(qr_code_id: 1, destination_url: "/go/listings/1")
      )
    end

    it "ContentImpressed.create calls Ahoy::Tracker#track" do
      tracker = instance_double(Ahoy::Tracker)
      allow(Ahoy::Tracker).to receive(:new).and_return(tracker)
      allow(tracker).to receive(:track)

      Analytics::Events::ContentImpressed.create(
        ad_id: 1, screen_id: 2, screen_content_id: 3,
        playlist_id: 4, position: 1, duration: 10
      )

      expect(tracker).to have_received(:track).with(
        "content.impressed",
        hash_including(ad_id: 1, screen_id: 2, duration: 10)
      )
    end

    it "invalid event does not call Ahoy::Tracker#track" do
      tracker = instance_double(Ahoy::Tracker)
      allow(Ahoy::Tracker).to receive(:new).and_return(tracker)
      allow(tracker).to receive(:track)

      event = Analytics::Events::QrScanned.create(
        qr_code_id: nil, destination_url: nil
      )

      expect(event.errors).to be_present
      expect(tracker).not_to have_received(:track)
    end
  end
end
