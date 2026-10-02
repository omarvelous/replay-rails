class Playlist < ApplicationRecord
  include PublicIdentifiable

  has_paper_trail ignore: [ :updated_at ]
  acts_as_tenant :account
  has_many :playlist_ads, -> { order(:position) }, dependent: :destroy, inverse_of: :playlist
  has_many :ads, through: :playlist_ads
  has_many :screen_contents, as: :contentable, dependent: :destroy
  has_many :screens, through: :screen_contents

  after_commit :notify_screens, if: :saved_change_to_updated_at?

  validates :name, presence: true
  validates :status, presence: true, inclusion: { in: %w[draft published archived] }

  scope :search, ->(q) { where("playlists.name ILIKE ?", "%#{sanitize_sql_like(q)}%") }
  scope :by_status, ->(s) { where(status: s) }

  private

  def notify_screens
    screen_contents.each do |sc|
      ActionCable.server.broadcast("screen_#{sc.screen_id}", { event: "content_changed" })
    end
  end
end
