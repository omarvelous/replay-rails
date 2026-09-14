require "rails_helper"

# Test event class for specs
class TestEvent < Analytics::Events::Base
  self.event_name = "test.event"
  self.event_context = :test

  attribute :widget_id, :integer
  attribute :action, :string

  validates :widget_id, presence: true
  validates :action, presence: true

  module Scopes
    def clicked
      where("properties @> ?", { action: "clicked" }.to_json)
    end
  end
end

RSpec.describe Analytics::Events::Base do
  describe ".create" do
    it "returns the event object on valid attributes" do
      event = TestEvent.create(widget_id: 1, action: "clicked")
      expect(event).to be_a(TestEvent)
    end

    it "returns false from #create on invalid attributes" do
      event = TestEvent.new(widget_id: nil, action: nil)
      expect(event.create).to be false
    end

    it "populates errors on invalid attributes" do
      event = TestEvent.new(widget_id: nil, action: nil)
      event.create
      expect(event.errors[:widget_id]).to include("can't be blank")
      expect(event.errors[:action]).to include("can't be blank")
    end
  end

  describe ".create!" do
    it "raises ValidationError on invalid attributes" do
      expect {
        TestEvent.create!(widget_id: nil, action: nil)
      }.to raise_error(ActiveModel::ValidationError)
    end
  end

  describe ".events" do
    it "returns Ahoy::Event scope filtered to the event name" do
      visit = create(:ahoy_visit)
      matching = Ahoy::Event.create!(visit: visit, name: "test.event", time: Time.current, properties: { "widget_id" => 1 })
      Ahoy::Event.create!(visit: visit, name: "other.event", time: Time.current, properties: {})

      expect(TestEvent.events).to eq([ matching ])
    end

    it "extends the relation with Scopes when defined" do
      visit = create(:ahoy_visit)
      match = Ahoy::Event.create!(visit: visit, name: "test.event", time: Time.current, properties: { "widget_id" => 1, "action" => "clicked" })
      Ahoy::Event.create!(visit: visit, name: "test.event", time: Time.current, properties: { "widget_id" => 2, "action" => "viewed" })

      expect(TestEvent.events.clicked).to eq([ match ])
    end

    it "preserves scopes when chaining with where_properties" do
      visit = create(:ahoy_visit)
      match = Ahoy::Event.create!(visit: visit, name: "test.event", time: Time.current, properties: { "widget_id" => 1, "action" => "clicked" })
      Ahoy::Event.create!(visit: visit, name: "test.event", time: Time.current, properties: { "widget_id" => 1, "action" => "viewed" })
      Ahoy::Event.create!(visit: visit, name: "test.event", time: Time.current, properties: { "widget_id" => 2, "action" => "clicked" })

      expect(TestEvent.where_properties(widget_id: 1).clicked).to eq([ match ])
    end
  end

  describe ".where_properties" do
    it "filters events by jsonb property containment" do
      visit = create(:ahoy_visit)
      match = Ahoy::Event.create!(visit: visit, name: "test.event", time: Time.current, properties: { "widget_id" => 5 })
      Ahoy::Event.create!(visit: visit, name: "test.event", time: Time.current, properties: { "widget_id" => 99 })

      expect(TestEvent.where_properties(widget_id: 5)).to eq([ match ])
    end

    it "supports multiple property filters" do
      visit = create(:ahoy_visit)
      match = Ahoy::Event.create!(visit: visit, name: "test.event", time: Time.current, properties: { "widget_id" => 5, "action" => "clicked" })
      Ahoy::Event.create!(visit: visit, name: "test.event", time: Time.current, properties: { "widget_id" => 5, "action" => "viewed" })

      expect(TestEvent.where_properties(widget_id: 5, action: "clicked")).to eq([ match ])
    end

    it "is chainable with where_properties on the relation" do
      visit = create(:ahoy_visit)
      match = Ahoy::Event.create!(visit: visit, name: "test.event", time: Time.current, properties: { "widget_id" => 5, "action" => "clicked" })
      Ahoy::Event.create!(visit: visit, name: "test.event", time: Time.current, properties: { "widget_id" => 5, "action" => "viewed" })

      expect(TestEvent.where_properties(widget_id: 5).where_properties(action: "clicked")).to eq([ match ])
    end
  end

  describe "#properties" do
    it "returns a hash of attribute values" do
      event = TestEvent.new(widget_id: 5, action: "viewed")
      expect(event.send(:properties)).to eq({ widget_id: 5, action: "viewed" })
    end

    it "excludes nil values" do
      event = TestEvent.new(widget_id: 5)
      expect(event.send(:properties)).to eq({ widget_id: 5 })
    end
  end
end
