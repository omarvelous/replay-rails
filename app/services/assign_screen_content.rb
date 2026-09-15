class AssignScreenContent
  def initialize(screen:, contentable:)
    @screen = screen
    @contentable = contentable
  end

  def call
    @screen.screen_contents.where(active: true).update_all(active: false)
    @screen.screen_contents.create!(contentable: @contentable, active: true)
  end
end
