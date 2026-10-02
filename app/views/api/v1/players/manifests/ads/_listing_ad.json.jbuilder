json.pid listing_ad.public_id
json.updated_at listing_ad.updated_at.to_i
json.badge listing_ad.badge
json.badge_label listing_ad.badge_label
json.event_date listing_ad.event_date
json.event_start_time listing_ad.event_start_time&.strftime("%-l:%M %p")
json.event_end_time listing_ad.event_end_time&.strftime("%-l:%M %p")
json.original_price listing_ad.original_price&.to_f
json.sold_price listing_ad.sold_price&.to_f

json.listing do
  json.partial! "api/v1/players/manifests/listing", listing: listing_ad.listing
end

if listing_ad.listing.primary_agent
  json.agent do
    json.partial! "api/v1/players/manifests/agent", agent: listing_ad.listing.primary_agent
  end
end
