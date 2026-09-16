class AcceptInvite
  def initialize(invite:, user:)
    @invite = invite
    @user = user
  end

  def call
    @invite.transaction do
      @invite.update!(accepted_at: Time.current)
      AccountUser.create!(account: @invite.account, user: @user, role: @invite.role)
      link_agent_profile if @invite.role == "agent"
    end
  end

  private

  def link_agent_profile
    agent = Agent.find_by(account: @invite.account, email: @invite.email)
    agent&.update!(user: @user) if agent&.user_id.nil?
  end
end
