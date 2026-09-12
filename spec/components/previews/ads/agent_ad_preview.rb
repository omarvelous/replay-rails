class Ads::AgentAdPreview < ViewComponent::Preview
  layout "lookbook_preview"

  # @label Profile — Dark
  def profile_dark
    render_with_template(locals: { ad: build_ad("profile", "dark") })
  end

  # @label Profile — Light
  def profile_light
    render_with_template(locals: { ad: build_ad("profile", "light") })
  end

  # @label Split — Dark
  def split_dark
    render_with_template(locals: { ad: build_ad("split", "dark") })
  end

  # @label Split — Light
  def split_light
    render_with_template(locals: { ad: build_ad("split", "light") })
  end

  private

  def build_ad(layout, theme)
    agent = FactoryBot.build(:agent, name: "Jane Broker", email: "jane@example.com", phone: "+12125550001")
    agent_ad = FactoryBot.build(:agent_ad, agent: agent)
    FactoryBot.build(:ad, adable: agent_ad, headline: "Jane Broker", layout: layout, theme: theme)
  end
end
