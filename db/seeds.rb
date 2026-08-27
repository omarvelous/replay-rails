SEED_IMAGE_DIR = Rails.root.join("db/seed_images")

# Helper: attach a local image file (skips if already attached)
def attach_seed_image(record, attachment_name, filename)
  attachment = record.send(attachment_name)
  return if attachment.is_a?(ActiveStorage::Attached::One) && attachment.attached?

  path = SEED_IMAGE_DIR.join(filename)
  unless path.exist?
    puts "  Skipped #{filename}: file not found"
    return
  end

  record.send(attachment_name).attach(
    io: File.open(path),
    filename: filename,
    content_type: "image/jpeg"
  )
  puts "  Attached #{filename} to #{record.class.name} ##{record.id}"
end

def attach_seed_photos(record, *filenames)
  return if record.photos.any?

  filenames.each do |filename|
    path = SEED_IMAGE_DIR.join(filename)
    unless path.exist?
      puts "  Skipped #{filename}: file not found"
      next
    end
    record.photos.attach(io: File.open(path), filename: filename, content_type: "image/jpeg")
    puts "  Attached #{filename} to #{record.class.name} ##{record.id}"
  end
end

# -----------------------------------------------------------------------
# Accounts & Users
# -----------------------------------------------------------------------
# One deterministic demo account so developers can log in immediately.

unless User.exists?(email_address: "demo@example.com")
  account = Account.create!

  user = User.create!(
    email_address:  "demo@example.com",
    first_name:     "Demo",
    last_name:      "User",
    phone:          "+12125550001",
    password:       "password"
  )
  AccountUser.create!(account: account, user: user, role: "owner")
  puts "Created demo user: demo@example.com / password (owner)"
end

demo_user_record = User.find_by(email_address: "demo@example.com")
demo_user_record&.update!(admin: true) unless demo_user_record&.admin?
demo_account = demo_user_record&.accounts&.first

# Manager user
if demo_account
  unless User.exists?(email_address: "manager@example.com")
    manager = User.create!(
      email_address: "manager@example.com",
      first_name: "Morgan",
      last_name: "Manager",
      phone: "+12125550002",
      password: "password"
    )
    AccountUser.create!(account: demo_account, user: manager, role: "manager")
    puts "Created manager user: manager@example.com / password (manager)"
  end
end

# -----------------------------------------------------------------------
# Sites
# -----------------------------------------------------------------------
if demo_account
  unless Site.exists?(account: demo_account, name: "Main Office")
    Site.create!(account: demo_account, name: "Main Office", address: "123 Broadway, New York, NY 10006")
    puts "Created demo site: Main Office"
  end

  unless Site.exists?(account: demo_account, name: "Downtown Gallery")
    Site.create!(account: demo_account, name: "Downtown Gallery", address: "456 Park Ave, New York, NY 10022")
    puts "Created demo site: Downtown Gallery"
  end

  main_office = Site.find_by(account: demo_account, name: "Main Office")
  attach_seed_image(main_office, :photo, "site-office.jpg") if main_office

  gallery = Site.find_by(account: demo_account, name: "Downtown Gallery")
  attach_seed_image(gallery, :photo, "site-gallery.jpg") if gallery
end
puts "Seeded #{Site.count} site(s)"

# -----------------------------------------------------------------------
# Screens
# -----------------------------------------------------------------------
if demo_account
  main_office = Site.find_by(account: demo_account, name: "Main Office")
  if main_office
    unless Screen.exists?(site: main_office, name: "Window Display")
      Screen.create!(site: main_office, name: "Window Display", orientation: "landscape")
      puts "Created demo screen: Window Display (Main Office)"
    end
  end

  gallery = Site.find_by(account: demo_account, name: "Downtown Gallery")
  if gallery
    unless Screen.exists?(site: gallery, name: "Gallery Entrance")
      Screen.create!(site: gallery, name: "Gallery Entrance", orientation: "portrait")
      puts "Created demo screen: Gallery Entrance (Downtown Gallery)"
    end
  end
end
puts "Seeded #{Screen.count} screen(s)"

# -----------------------------------------------------------------------
# Players
# -----------------------------------------------------------------------
if demo_account
  unless Player.any?
    window_display = Screen.joins(:site).find_by(name: "Window Display", sites: { account_id: demo_account.id })
    if window_display
      player = Player.create!(
        ip_address: "192.168.1.100",
        user_agent: "RePlayPlayer/1.0 (Chromium)"
      )
      window_display.pair_player!(player)
      player.update!(last_heartbeat_at: Time.current)
      puts "Created demo player and paired to Window Display"
    end
  end
end
puts "Seeded #{Player.count} player(s)"

# -----------------------------------------------------------------------
# Listings
# -----------------------------------------------------------------------
if demo_account
  unless Listing.exists?(account: demo_account, address: "350 Fifth Ave, New York, NY 10118")
    Listing.create!(
      account: demo_account,
      address: "350 Fifth Ave, New York, NY 10118",
      price: 2_500_000,
      beds: 3,
      baths: 2,
      sqft: 2200,
      status: "active"
    )
    puts "Created demo listing: 350 Fifth Ave"
  end
  fifth_ave_listing = Listing.find_by(account: demo_account, address: "350 Fifth Ave, New York, NY 10118")
  attach_seed_photos(fifth_ave_listing, "house-1.jpg", "interior-1.jpg") if fifth_ave_listing

  unless Listing.exists?(account: demo_account, address: "20 W 34th St, New York, NY 10001")
    Listing.create!(
      account: demo_account,
      address: "20 W 34th St, New York, NY 10001",
      price: 1_850_000,
      beds: 2,
      baths: 2,
      sqft: 1500,
      status: "pending"
    )
    puts "Created demo listing: 20 W 34th St"
  end
  w34th_listing = Listing.find_by(account: demo_account, address: "20 W 34th St, New York, NY 10001")
  attach_seed_photos(w34th_listing, "house-2.jpg", "interior-2.jpg") if w34th_listing
  # QR codes for listings
  [ fifth_ave_listing, w34th_listing ].compact.each do |listing|
    listing.ensure_qr_code!
  end
end
puts "Seeded #{Listing.count} listing(s)"
puts "Seeded #{QrCode.count} QR code(s)"

# -----------------------------------------------------------------------
# Agents
# -----------------------------------------------------------------------
demo_user = User.find_by(email_address: "demo@example.com")

if demo_account
  unless Agent.exists?(account: demo_account, email: "jane.broker@example.com")
    Agent.create!(
      account: demo_account,
      user: demo_user,
      name: "Jane Broker",
      email: "jane.broker@example.com",
      phone: "+12125550002"
    )
    puts "Created demo agent: Jane Broker (linked to demo user)"
  end

  unless Agent.exists?(account: demo_account, email: "tom.realtor@example.com")
    Agent.create!(
      account: demo_account,
      name: "Tom Realtor",
      email: "tom.realtor@example.com",
      phone: "+12125550003"
    )
    puts "Created demo agent: Tom Realtor"
  end

  jane_agent = Agent.find_by(account: demo_account, email: "jane.broker@example.com")
  attach_seed_image(jane_agent, :photo, "agent-jane.jpg") if jane_agent

  tom_agent = Agent.find_by(account: demo_account, email: "tom.realtor@example.com")
  attach_seed_image(tom_agent, :photo, "agent-tom.jpg") if tom_agent
  # Agent user (linked to Jane's Agent profile)
  if jane_agent && !User.exists?(email_address: "jane.broker@example.com")
    jane_user = User.create!(
      email_address: "jane.broker@example.com",
      first_name: "Jane",
      last_name: "Broker",
      phone: "+12125550003",
      password: "password"
    )
    AccountUser.create!(account: demo_account, user: jane_user, role: "agent")
    jane_agent.update!(user: jane_user)
    puts "Created agent user: jane.broker@example.com / password (agent)"
  end
end
puts "Seeded #{Agent.count} agent(s)"

# -----------------------------------------------------------------------
# Ads (delegated types: ListingAd, CollectionAd, AgentAd, BrandAd)
# -----------------------------------------------------------------------
if demo_account
  fifth_ave = Listing.find_by(account: demo_account, address: "350 Fifth Ave, New York, NY 10118")
  w34th = Listing.find_by(account: demo_account, address: "20 W 34th St, New York, NY 10001")
  jane = Agent.find_by(account: demo_account, email: "jane.broker@example.com")

  # ListingAd — just_listed
  unless Ad.exists?(account: demo_account, headline: "Just Listed")
    listing_ad = Ads::ListingAd.create!(listing: fifth_ave, badge: "just_listed")
    Ad.create!(
      account: demo_account,
      adable: listing_ad,
      headline: "Just Listed",
      body: "Stunning 3BR with panoramic city views.",
      layout: "hero",
      theme: "dark"
    )
    puts "Created demo ListingAd: Just Listed (350 Fifth Ave)"
  end
  just_listed_ad = Ad.find_by(account: demo_account, headline: "Just Listed")
  attach_seed_image(just_listed_ad, :image, "house-1.jpg") if just_listed_ad

  # ListingAd — open_house
  unless Ad.exists?(account: demo_account, headline: "Open House")
    listing_ad = Ads::ListingAd.create!(
      listing: w34th,
      badge: "open_house",
      event_date: Date.current.next_occurring(:saturday),
      event_start_time: Time.zone.parse("13:00"),
      event_end_time: Time.zone.parse("15:00")
    )
    Ad.create!(
      account: demo_account,
      adable: listing_ad,
      headline: "Open House",
      body: "Visit this Saturday 1-3 PM.",
      layout: "split",
      theme: "dark"
    )
    puts "Created demo ListingAd: Open House (20 W 34th St)"
  end
  open_house_ad = Ad.find_by(account: demo_account, headline: "Open House")
  attach_seed_image(open_house_ad, :image, "house-2.jpg") if open_house_ad

  # CollectionAd
  unless Ad.exists?(account: demo_account, headline: "Featured Listings")
    collection_ad = Ads::CollectionAd.create!(collection_title: "Featured Listings")
    member_ads = Ad.where(account: demo_account).where(adable_type: "Ads::ListingAd").order(:id)
    member_ads.each_with_index do |ad, i|
      Ads::CollectionAdAd.create!(collection_ad: collection_ad, ad: ad, position: i)
    end
    Ad.create!(
      account: demo_account,
      adable: collection_ad,
      headline: "Featured Listings",
      body: "Our top properties this week.",
      layout: "grid",
      theme: "dark"
    )
    puts "Created demo CollectionAd: Featured Listings (#{member_ads.count} ads)"
  end

  # AgentAd
  if jane
    unless Ad.exists?(account: demo_account, headline: "Jane Broker")
      agent_ad = Ads::AgentAd.create!(agent: jane)
      Ad.create!(
        account: demo_account,
        adable: agent_ad,
        headline: "Jane Broker",
        body: "Your trusted real estate advisor.",
        layout: "profile",
        theme: "dark"
      )
      puts "Created demo AgentAd: Jane Broker"
    end
  end
  agent_ad_record = Ad.find_by(account: demo_account, headline: "Jane Broker")
  attach_seed_image(agent_ad_record, :image, "agent.jpg") if agent_ad_record

  # BrandAd
  unless Ad.exists?(account: demo_account, headline: "Your Window, Working 24/7")
    brand_ad = Ads::BrandAd.create!
    Ad.create!(
      account: demo_account,
      adable: brand_ad,
      headline: "Your Window, Working 24/7",
      body: "Digital signage purpose-built for real estate.",
      layout: "hero",
      theme: "brand"
    )
    puts "Created demo BrandAd: Your Window, Working 24/7"
  end
  brand_ad_record = Ad.find_by(account: demo_account, headline: "Your Window, Working 24/7")
  attach_seed_image(brand_ad_record, :image, "brand.jpg") if brand_ad_record
end
puts "Seeded #{Ad.count} ad(s)"

# -----------------------------------------------------------------------
# Playlists
# -----------------------------------------------------------------------
if demo_account
  unless Playlist.exists?(account: demo_account, name: "Evening Showcase")
    playlist = Playlist.create!(account: demo_account, name: "Evening Showcase", status: "published")
    demo_ads = Ad.where(account: demo_account).order(:id)
    demo_ads.each_with_index do |ad, i|
      PlaylistAd.create!(playlist: playlist, ad: ad, position: i + 1, duration: 15)
    end
    puts "Created demo playlist: Evening Showcase (#{demo_ads.count} ads)"
  end
end
puts "Seeded #{Playlist.count} playlist(s)"

# -----------------------------------------------------------------------
# Screen ↔ Playlist Assignments
# -----------------------------------------------------------------------
if demo_account
  window_display = Screen.joins(:site).find_by(name: "Window Display", sites: { account_id: demo_account.id })
  evening_showcase = Playlist.find_by(account: demo_account, name: "Evening Showcase")

  if window_display && evening_showcase
    unless ScreenPlaylist.exists?(screen: window_display, playlist: evening_showcase)
      ScreenPlaylist.create!(screen: window_display, playlist: evening_showcase)
      puts "Assigned Evening Showcase to Window Display"
    end
  end
end
puts "Seeded #{ScreenPlaylist.count} screen-playlist assignment(s)"

# -----------------------------------------------------------------------
# Leads
# -----------------------------------------------------------------------
if demo_account
  fifth_ave = Listing.find_by(account: demo_account, address: "350 Fifth Ave, New York, NY 10118")
  jane = Agent.find_by(account: demo_account, email: "jane.broker@example.com")

  unless Lead.exists?(account: demo_account, name: "Sarah Chen")
    lead = Lead.create!(
      account: demo_account,
      listing: fifth_ave,
      name: "Sarah Chen",
      email: "sarah.chen@example.com",
      phone: "212-555-0142",
      lead_type: "buyer_inquiry",
      status: "new",
      message: "Hi, I saw this listing on your window display and I'm very interested. Could we schedule a viewing this weekend?"
    )
    lead.lead_agents.create!(agent: jane) if jane
    puts "Created demo lead: Sarah Chen (buyer inquiry)"
  end

  unless Lead.exists?(account: demo_account, name: "Michael Torres")
    lead = Lead.create!(
      account: demo_account,
      name: "Michael Torres",
      email: "m.torres@example.com",
      lead_type: "general_inquiry",
      status: "contacted",
      message: "Looking to sell my 2BR in the area. What's the market like right now?"
    )
    lead.lead_agents.create!(agent: jane) if jane
    puts "Created demo lead: Michael Torres (general inquiry)"
  end

  unless Lead.exists?(account: demo_account, name: "Emily Park")
    lead = Lead.create!(
      account: demo_account,
      listing: fifth_ave,
      name: "Emily Park",
      phone: "917-555-0198",
      lead_type: "renter_inquiry",
      status: "qualified",
      message: "Is the apartment at 350 Fifth Ave available for a 12-month lease?"
    )
    lead.lead_agents.create!(agent: jane) if jane
    puts "Created demo lead: Emily Park (renter inquiry)"
  end

  unless Lead.exists?(account: demo_account, name: "David Kim")
    Lead.create!(
      account: demo_account,
      name: "David Kim",
      email: "david.kim@example.com",
      lead_type: "seller_inquiry",
      status: "closed"
    )
    puts "Created demo lead: David Kim (seller inquiry, closed)"
  end
end
puts "Seeded #{Lead.count} lead(s)"

# -----------------------------------------------------------------------
# Invites
# -----------------------------------------------------------------------
if demo_account && demo_user_record
  unless Invite.exists?(account: demo_account, email: "tom.realtor@example.com")
    Invite.create!(
      account: demo_account,
      invited_by: demo_user_record,
      email: "tom.realtor@example.com",
      role: "agent"
    )
    puts "Created demo invite: tom.realtor@example.com (agent, pending)"
  end
end
puts "Seeded #{Invite.count} invite(s)"

# -----------------------------------------------------------------------
# Impressions (last 30 days of simulated data)
# -----------------------------------------------------------------------
if demo_account && Impression.where(account: demo_account).empty?
  screen = Screen.joins(:site).find_by(sites: { account_id: demo_account.id })
  player = screen&.player
  site = screen&.site
  playlist = Playlist.find_by(account: demo_account, status: "published")
  ads = Ad.where(account: demo_account).limit(5).to_a

  if screen && player && site && ads.any?
    impressions = []
    now = Time.current

    30.downto(1) do |days_ago|
      date = days_ago.days.ago.to_date
      # Simulate 8 hours of display (8am-4pm), 5 ads at ~10s each
      daily_count = rand(200..400)
      daily_count.times do
        ad = ads.sample
        playlist_ad = playlist&.playlist_ads&.find_by(ad: ad)
        impressions << {
          ad_id: ad.id,
          screen_id: screen.id,
          player_id: player.id,
          site_id: site.id,
          playlist_id: playlist&.id,
          account_id: demo_account.id,
          position: playlist_ad&.position || rand(1..5),
          duration: playlist_ad&.duration || 10,
          created_at: date + rand(8..16).hours + rand(0..59).minutes,
          updated_at: now
        }
      end
    end

    Impression.insert_all(impressions)
    puts "Created #{impressions.size} demo impressions (30 days)"
  end
end

# -----------------------------------------------------------------------
# Metric Snapshots (rollup the demo data)
# -----------------------------------------------------------------------
if demo_account && MetricSnapshot.where(account: demo_account).empty?
  30.downto(1) do |days_ago|
    MetricsRollupJob.new.perform(days_ago.days.ago.to_date)
  end
  puts "Rolled up #{MetricSnapshot.count} metric snapshots (30 days)"
end
