class Ad::ManifestSerializer
  include Rails.application.routes.url_helpers

  def initialize(ad, position: 0, duration: 10)
    @ad = ad
    @position = position
    @duration = duration
  end

  def as_json(*)
    {
      pid: @ad.public_id,
      updated_at: @ad.updated_at.to_i,
      position: @position,
      duration: @duration,
      headline: @ad.headline,
      body: @ad.body,
      layout: @ad.layout,
      theme: @ad.theme,
      images: serialize_attachments(@ad.image.attached? ? [ @ad.image_attachment ] : []),
      adable: serialize_adable
    }
  end

  private

    def serialize_adable
      listing_ad = @ad.adable
      listing = listing_ad.listing
      agent = listing.primary_agent

      {
        type: @ad.adable_type,
        pid: listing_ad.public_id,
        updated_at: listing_ad.updated_at.to_i,
        badge: listing_ad.badge,
        badge_label: listing_ad.badge_label,
        event_date: listing_ad.event_date,
        event_start_time: listing_ad.event_start_time&.strftime("%-l:%M %p"),
        event_end_time: listing_ad.event_end_time&.strftime("%-l:%M %p"),
        original_price: listing_ad.original_price&.to_f,
        sold_price: listing_ad.sold_price&.to_f,
        listing: serialize_listing(listing),
        agent: agent ? serialize_agent(agent) : nil
      }.compact
    end

    def serialize_listing(listing)
      {
        pid: listing.public_id,
        updated_at: listing.updated_at.to_i,
        address: listing.address,
        street: listing.street,
        city: listing.city,
        state: listing.state,
        zip: listing.zip,
        neighborhood: listing.neighborhood,
        price: listing.price.to_f,
        beds: listing.beds,
        baths: listing.baths,
        sqft: listing.sqft,
        property_type: listing.property_type,
        listing_type: listing.listing_type,
        status: listing.status,
        photos: serialize_attachments(listing.photos_attachments),
        floor_plans: serialize_attachments(listing.floor_plans_attachments)
      }
    end

    def serialize_agent(agent)
      {
        pid: agent.public_id,
        updated_at: agent.updated_at.to_i,
        name: agent.name,
        email: agent.email,
        phone: agent.phone,
        bio: agent.bio,
        photos: serialize_attachments(agent.photo.attached? ? [ agent.photo_attachment ] : [])
      }
    end

    def serialize_attachments(attachments)
      attachments.map do |attachment|
        {
          id: attachment.id,
          url: rails_storage_proxy_url(attachment),
          created_at: attachment.created_at.to_i
        }
      end
    end

    def default_url_options
      Rails.application.config.action_mailer.default_url_options || { host: "localhost", port: 3000 }
    end
end
