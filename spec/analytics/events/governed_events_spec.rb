require "rails_helper"

RSpec.describe "Governed Events" do
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

  describe Analytics::Events::RedirectFollowed do
    include_examples "validates required properties",
      Analytics::Events::RedirectFollowed,
      { source: "qr", destination_url: "/go/listings/1", status: 302 },
      %i[source destination_url status]
  end

  describe Analytics::Events::ContentImpressed do
    include_examples "validates required properties",
      Analytics::Events::ContentImpressed,
      { ad_id: 1, screen_id: 2, screen_content_id: 3, playlist_id: 4, position: 1, duration: 10 },
      %i[ad_id screen_id screen_content_id playlist_id position duration]
  end

  describe Analytics::Events::ContentLoaded do
    include_examples "validates required properties",
      Analytics::Events::ContentLoaded,
      { screen_id: 1, screen_content_id: 2, content_type: "playlist", content_id: 3 },
      %i[screen_id screen_content_id content_type content_id]
  end

  describe Analytics::Events::InteractionStarted do
    include_examples "validates required properties",
      Analytics::Events::InteractionStarted,
      { experience_id: 1, screen_id: 2, screen_content_id: 3 },
      %i[experience_id screen_id screen_content_id]
  end

  describe Analytics::Events::InteractionEnded do
    include_examples "validates required properties",
      Analytics::Events::InteractionEnded,
      { experience_id: 1, screen_id: 2, screen_content_id: 3, duration: 45 },
      %i[experience_id screen_id screen_content_id duration]
  end

  describe Analytics::Events::InteractionNavigated do
    include_examples "validates required properties",
      Analytics::Events::InteractionNavigated,
      { experience_id: 1, screen_content_id: 2, direction: "next", photo_index: 3 },
      %i[experience_id screen_content_id direction photo_index]
  end

  describe Analytics::Events::InteractionOpened do
    include_examples "validates required properties",
      Analytics::Events::InteractionOpened,
      { experience_id: 1, screen_content_id: 2, target: "floor_plan" },
      %i[experience_id screen_content_id target]
  end

  describe Analytics::Events::InteractionClosed do
    include_examples "validates required properties",
      Analytics::Events::InteractionClosed,
      { experience_id: 1, screen_content_id: 2, target: "floor_plan", view_duration: 16 },
      %i[experience_id screen_content_id target view_duration]
  end

  describe Analytics::Events::DeviceConnected do
    include_examples "validates required properties",
      Analytics::Events::DeviceConnected,
      { screen_id: 1, player_token: "abc123" },
      %i[screen_id player_token]
  end
end
