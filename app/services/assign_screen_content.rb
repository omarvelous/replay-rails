class AssignScreenContent
  def initialize(screen_content:)
    @screen_content = screen_content
  end

  def call
    screen = @screen_content.screen
    screen.screen_contents.where(active: true).update_all(active: false)
    @screen_content.save!
    @screen_content
  end
end
