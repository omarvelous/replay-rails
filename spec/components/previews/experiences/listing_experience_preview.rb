class Experiences::ListingExperiencePreview < ViewComponent::Preview
  layout "lookbook_preview"

  # @label Default — With Details
  def default_with_details
    render_with_template(locals: build_locals)
  end

  # @label With Agent
  def with_agent
    render_with_template(locals: build_locals(show_agent: true))
  end

  # @label Minimal — Details Only
  def minimal_details_only
    render_with_template(locals: build_locals(
      sections: { "photos" => false, "details" => true, "agent_card" => false, "qr_handoff" => false, "floor_plans" => false }
    ))
  end

  # @label All Sections
  def all_sections
    render_with_template(locals: build_locals(
      show_agent: true,
      sections: { "photos" => true, "details" => true, "agent_card" => true, "qr_handoff" => true, "floor_plans" => true }
    ))
  end

  # @label No Content
  def no_content
    render_with_template(locals: build_locals(
      sections: { "photos" => false, "details" => false, "agent_card" => false, "qr_handoff" => false, "floor_plans" => false }
    ))
  end

  private

  def build_locals(show_agent: false, sections: nil)
    sections ||= { "photos" => true, "details" => true, "agent_card" => show_agent, "qr_handoff" => false, "floor_plans" => false }

    listing = FactoryBot.build(:listing,
      address: "350 Fifth Ave, New York, NY 10118",
      price: 2_500_000,
      beds: 3,
      baths: 2,
      sqft: 2200,
      listing_type: "sale",
      description: "Stunning three-bedroom apartment with panoramic city views. Floor-to-ceiling windows, chef's kitchen, and private terrace."
    )

    agent = show_agent ? FactoryBot.build(:agent, name: "Jane Broker", email: "jane@example.com", phone: "+12125550001") : nil

    experience = FactoryBot.build(:experience, name: "Open House Experience", config: { "sections" => sections })

    { experience: experience, listing: listing, agent: agent }
  end
end
