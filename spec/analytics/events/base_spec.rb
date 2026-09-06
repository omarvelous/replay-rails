require "rails_helper"

# Test event class for specs
class TestEvent < Analytics::Events::Base
  self.event_name = "test.event"
  self.event_context = :test

  attribute :widget_id, :integer
  attribute :action, :string

  validates :widget_id, presence: true
  validates :action, presence: true
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
