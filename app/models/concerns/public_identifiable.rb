module PublicIdentifiable
  extend ActiveSupport::Concern

  included do
    before_create :set_public_id
    validates :public_id, uniqueness: true, allow_nil: true
  end

  def to_param
    public_id
  end

  class_methods do
    def find_by_param!(value)
      find_by!(public_id: value)
    end
  end

  private

  def set_public_id
    self.public_id ||= SecureRandom.uuid
  end
end
