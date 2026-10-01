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

# =====================================================================
# ACCOUNT 1: RePlay (internal / admin)
# =====================================================================
puts "\n=== RePlay (admin account) ==="

unless Account.exists?(name: "RePlay")
  Account.create!(name: "RePlay")
  puts "Created account: RePlay"
end
replay_account = Account.find_by(name: "RePlay")

unless User.exists?(email_address: "admin@replaytv.co")
  admin = User.create!(
    email_address: "admin@replaytv.co",
    first_name: "Omar",
    last_name: "Johnson",
    phone: "+12125550001",
    password: "password",
    admin: true
  )
  AccountUser.create!(account: replay_account, user: admin, role: "owner")
  puts "Created admin user: admin@replaytv.co / password (owner, admin)"
end
admin_user = User.find_by(email_address: "admin@replaytv.co")
admin_user.update!(admin: true) unless admin_user.admin?

# =====================================================================
# ACCOUNT 2: RE/MAX Elite (full brokerage)
# =====================================================================
puts "\n=== RE/MAX Elite ==="

unless Account.exists?(name: "RE/MAX Elite")
  Account.create!(name: "RE/MAX Elite")
  puts "Created account: RE/MAX Elite"
end
remax_account = Account.find_by(name: "RE/MAX Elite")

# -- Users -------------------------------------------------------------
unless User.exists?(email_address: "owner@remax.com")
  owner = User.create!(
    email_address: "owner@remax.com",
    first_name: "Rachel",
    last_name: "Maxwell",
    phone: "+12125550010",
    password: "password"
  )
  AccountUser.create!(account: remax_account, user: owner, role: "owner")
  puts "Created user: owner@remax.com / password (owner)"
end

unless User.exists?(email_address: "manager@remax.com")
  manager = User.create!(
    email_address: "manager@remax.com",
    first_name: "Morgan",
    last_name: "Hale",
    phone: "+12125550011",
    password: "password"
  )
  AccountUser.create!(account: remax_account, user: manager, role: "manager")
  puts "Created user: manager@remax.com / password (manager)"
end

unless User.exists?(email_address: "agent.01@remax.com")
  agent1 = User.create!(
    email_address: "agent.01@remax.com",
    first_name: "Jane",
    last_name: "Archer",
    phone: "+12125550012",
    password: "password"
  )
  AccountUser.create!(account: remax_account, user: agent1, role: "agent")
  puts "Created user: agent.01@remax.com / password (agent)"
end

unless User.exists?(email_address: "agent.02@remax.com")
  agent2 = User.create!(
    email_address: "agent.02@remax.com",
    first_name: "Tom",
    last_name: "Reeves",
    phone: "+12125550013",
    password: "password"
  )
  AccountUser.create!(account: remax_account, user: agent2, role: "agent")
  puts "Created user: agent.02@remax.com / password (agent)"
end

remax_owner = User.find_by(email_address: "owner@remax.com")
remax_agent1 = User.find_by(email_address: "agent.01@remax.com")
remax_agent2 = User.find_by(email_address: "agent.02@remax.com")

# -- Sites -------------------------------------------------------------
ActsAsTenant.with_tenant(remax_account) do
  unless Site.exists?(name: "Midtown Office")
    Site.create!(account: remax_account, name: "Midtown Office", address: "350 Fifth Ave, New York, NY 10118")
    puts "Created site: Midtown Office"
  end
  midtown = Site.find_by(name: "Midtown Office")
  attach_seed_image(midtown, :photo, "site-office.jpg") if midtown

  unless Site.exists?(name: "Chelsea Gallery")
    Site.create!(account: remax_account, name: "Chelsea Gallery", address: "456 W 25th St, New York, NY 10001")
    puts "Created site: Chelsea Gallery"
  end
  chelsea = Site.find_by(name: "Chelsea Gallery")
  attach_seed_image(chelsea, :photo, "site-gallery.jpg") if chelsea

  # -- Screens -----------------------------------------------------------
  if midtown
    unless Screen.exists?(site: midtown, name: "Window Display")
      Screen.create!(site: midtown, name: "Window Display", orientation: "landscape")
      puts "Created screen: Window Display (Midtown)"
    end
    unless Screen.exists?(site: midtown, name: "Lobby Kiosk")
      Screen.create!(site: midtown, name: "Lobby Kiosk", orientation: "portrait")
      puts "Created screen: Lobby Kiosk (Midtown)"
    end
  end

  if chelsea
    unless Screen.exists?(site: chelsea, name: "Storefront")
      Screen.create!(site: chelsea, name: "Storefront", orientation: "landscape")
      puts "Created screen: Storefront (Chelsea)"
    end
  end

  # -- Player ------------------------------------------------------------
  window_display = Screen.joins(:site).find_by(name: "Window Display", sites: { account_id: remax_account.id })
  unless Player.joins(:screen_players).where(screen_players: { screen: window_display }).exists?
    if window_display
      player = Player.create!(
        ip_address: "192.168.1.100",
        user_agent: "Mozilla/5.0 (Linux; Android 11; AFTSSS Build/NS6294) AppleWebKit/537.36 (KHTML, like Gecko) Silk/120.0.6099.109 like Chrome/120.0.6099.109 Mobile Safari/537.36",
        device_name: "Lobby Fire Stick",
        screen_width: 1920,
        screen_height: 1080,
        touch_capable: false
      )
      UpdateDeviceInfo.new(player: player).call
      window_display.screen_players.create!(player: player, paired_by: remax_owner)
      player.update!(pairing_code: nil, pairing_code_expires_at: nil)
      player.update!(last_heartbeat_at: Time.current)
      puts "Created player (Fire TV) paired to Window Display"
    end
  end

  # -- Agents ------------------------------------------------------------
  unless Agent.exists?(account: remax_account, email: "agent.01@remax.com")
    Agent.create!(
      account: remax_account,
      user: remax_agent1,
      name: "Jane Archer",
      email: "agent.01@remax.com",
      phone: "+12125550012",
      bio: "Top-producing broker with 15 years of experience in Manhattan luxury real estate. Specializing in co-ops and condos from Tribeca to the Upper West Side."
    )
    puts "Created agent: Jane Archer (linked to agent.01@remax.com)"
  end
  jane = Agent.find_by(account: remax_account, email: "agent.01@remax.com")
  attach_seed_image(jane, :photo, "agent-jane.jpg") if jane

  unless Agent.exists?(account: remax_account, email: "agent.02@remax.com")
    Agent.create!(
      account: remax_account,
      user: remax_agent2,
      name: "Tom Reeves",
      email: "agent.02@remax.com",
      phone: "+12125550013",
      bio: "NYC native and licensed agent focused on helping first-time buyers navigate the city's competitive market."
    )
    puts "Created agent: Tom Reeves (linked to agent.02@remax.com)"
  end
  tom = Agent.find_by(account: remax_account, email: "agent.02@remax.com")
  attach_seed_image(tom, :photo, "agent-tom.jpg") if tom

  # -- Listings ----------------------------------------------------------
  unless Listing.exists?(account: remax_account, address: "350 Fifth Ave, New York, NY 10118")
    Listing.create!(
      account: remax_account,
      address: "350 Fifth Ave, New York, NY 10118",
      price: 2_500_000,
      beds: 3, baths: 2, sqft: 2200,
      status: "active",
      property_type: "condo",
      listing_type: "for_sale"
    )
    puts "Created listing: 350 Fifth Ave"
  end
  fifth_ave = Listing.find_by(account: remax_account, address: "350 Fifth Ave, New York, NY 10118")
  attach_seed_photos(fifth_ave, "house-1.jpg", "interior-1.jpg") if fifth_ave

  unless Listing.exists?(account: remax_account, address: "20 W 34th St, New York, NY 10001")
    Listing.create!(
      account: remax_account,
      address: "20 W 34th St, New York, NY 10001",
      price: 1_850_000,
      beds: 2, baths: 2, sqft: 1500,
      status: "pending",
      property_type: "apartment",
      listing_type: "for_sale"
    )
    puts "Created listing: 20 W 34th St"
  end
  w34th = Listing.find_by(account: remax_account, address: "20 W 34th St, New York, NY 10001")
  attach_seed_photos(w34th, "house-2.jpg", "interior-2.jpg") if w34th

  unless Listing.exists?(account: remax_account, address: "88 Greenwich St, New York, NY 10006")
    Listing.create!(
      account: remax_account,
      address: "88 Greenwich St, New York, NY 10006",
      price: 4_200_000,
      beds: 4, baths: 3, sqft: 3100,
      status: "active",
      property_type: "condo",
      listing_type: "for_sale"
    )
    puts "Created listing: 88 Greenwich St"
  end
  greenwich = Listing.find_by(account: remax_account, address: "88 Greenwich St, New York, NY 10006")
  attach_seed_photos(greenwich, "house-3.jpg") if greenwich

  unless Listing.exists?(account: remax_account, address: "15 Hudson Yards, New York, NY 10001")
    Listing.create!(
      account: remax_account,
      address: "15 Hudson Yards, New York, NY 10001",
      price: 6_750,
      beds: 1, baths: 1, sqft: 850,
      status: "active",
      property_type: "apartment",
      listing_type: "for_rent"
    )
    puts "Created listing: 15 Hudson Yards (rental)"
  end
  hudson = Listing.find_by(account: remax_account, address: "15 Hudson Yards, New York, NY 10001")
  attach_seed_photos(hudson, "house-4.jpg") if hudson

  # QR codes for listings
  [ fifth_ave, w34th, greenwich, hudson ].compact.each { |listing| listing.qr_code_for }

  # -- Listing Agents ----------------------------------------------------
  if jane && fifth_ave && !ListingAgent.exists?(listing: fifth_ave, agent: jane)
    ListingAgent.create!(listing: fifth_ave, agent: jane, role: "listing_agent", primary_at: Time.current)
    puts "Assigned Jane Archer to 350 Fifth Ave (primary)"
  end
  if tom && fifth_ave && !ListingAgent.exists?(listing: fifth_ave, agent: tom)
    ListingAgent.create!(listing: fifth_ave, agent: tom, role: "listing_agent")
    puts "Assigned Tom Reeves to 350 Fifth Ave"
  end
  if jane && w34th && !ListingAgent.exists?(listing: w34th, agent: jane)
    ListingAgent.create!(listing: w34th, agent: jane, role: "listing_agent", primary_at: Time.current)
    puts "Assigned Jane Archer to 20 W 34th St (primary)"
  end
  if tom && greenwich && !ListingAgent.exists?(listing: greenwich, agent: tom)
    ListingAgent.create!(listing: greenwich, agent: tom, role: "listing_agent", primary_at: Time.current)
    puts "Assigned Tom Reeves to 88 Greenwich St (primary)"
  end
  if jane && hudson && !ListingAgent.exists?(listing: hudson, agent: jane)
    ListingAgent.create!(listing: hudson, agent: jane, role: "listing_agent", primary_at: Time.current)
    puts "Assigned Jane Archer to 15 Hudson Yards (primary)"
  end

  # -- Ads ---------------------------------------------------------------
  # ListingAd — just listed
  unless Ad.exists?(account: remax_account, headline: "Just Listed")
    listing_ad = Ads::ListingAd.create!(listing: fifth_ave, badge: "just_listed")
    Ad.create!(
      account: remax_account, adable: listing_ad,
      headline: "Just Listed",
      body: "Stunning 3BR with panoramic city views.",
      layout: "hero", theme: "dark"
    )
    puts "Created ListingAd: Just Listed (350 Fifth Ave)"
  end
  just_listed_ad = Ad.find_by(account: remax_account, headline: "Just Listed")
  attach_seed_image(just_listed_ad, :image, "house-1.jpg") if just_listed_ad

  # ListingAd — open house
  unless Ad.exists?(account: remax_account, headline: "Open House")
    listing_ad = Ads::ListingAd.create!(
      listing: w34th, badge: "open_house",
      event_date: Date.current.next_occurring(:saturday),
      event_start_time: Time.zone.parse("13:00"),
      event_end_time: Time.zone.parse("15:00")
    )
    Ad.create!(
      account: remax_account, adable: listing_ad,
      headline: "Open House",
      body: "Visit this Saturday 1-3 PM.",
      layout: "split", theme: "dark"
    )
    puts "Created ListingAd: Open House (20 W 34th St)"
  end
  open_house_ad = Ad.find_by(account: remax_account, headline: "Open House")
  attach_seed_image(open_house_ad, :image, "house-2.jpg") if open_house_ad

  # ListingAd — price reduced
  unless Ad.exists?(account: remax_account, headline: "Price Reduced")
    listing_ad = Ads::ListingAd.create!(listing: greenwich, badge: "price_reduction", original_price: 4_500_000)
    Ad.create!(
      account: remax_account, adable: listing_ad,
      headline: "Price Reduced",
      body: "Now $300K below original asking.",
      layout: "hero", theme: "dark"
    )
    puts "Created ListingAd: Price Reduced (88 Greenwich St)"
  end
  price_reduced_ad = Ad.find_by(account: remax_account, headline: "Price Reduced")
  attach_seed_image(price_reduced_ad, :image, "house-3.jpg") if price_reduced_ad

  # CollectionAd
  unless Ad.exists?(account: remax_account, headline: "Featured Listings")
    collection_ad = Ads::CollectionAd.create!(collection_title: "Featured Listings")
    member_ads = Ad.where(account: remax_account, adable_type: "Ads::ListingAd").order(:id)
    member_ads.each_with_index do |ad, i|
      Ads::CollectionAdAd.create!(collection_ad: collection_ad, ad: ad, position: i)
    end
    Ad.create!(
      account: remax_account, adable: collection_ad,
      headline: "Featured Listings",
      body: "Our top properties this week.",
      layout: "grid", theme: "dark"
    )
    puts "Created CollectionAd: Featured Listings (#{member_ads.count} ads)"
  end

  # AgentAd
  if jane && !Ad.exists?(account: remax_account, headline: "Jane Archer")
    agent_ad = Ads::AgentAd.create!(agent: jane)
    Ad.create!(
      account: remax_account, adable: agent_ad,
      headline: "Jane Archer",
      body: "Your trusted real estate advisor.",
      layout: "profile", theme: "dark"
    )
    puts "Created AgentAd: Jane Archer"
  end
  agent_ad_record = Ad.find_by(account: remax_account, headline: "Jane Archer")
  attach_seed_image(agent_ad_record, :image, "agent-jane.jpg") if agent_ad_record

  # BrandAd
  unless Ad.exists?(account: remax_account, headline: "Your Window, Working 24/7")
    brand_ad = Ads::BrandAd.create!
    Ad.create!(
      account: remax_account, adable: brand_ad,
      headline: "Your Window, Working 24/7",
      body: "Digital signage purpose-built for real estate.",
      layout: "hero", theme: "brand"
    )
    puts "Created BrandAd: Your Window, Working 24/7"
  end
  brand_ad_record = Ad.find_by(account: remax_account, headline: "Your Window, Working 24/7")
  attach_seed_image(brand_ad_record, :image, "brand.jpg") if brand_ad_record

  # -- Playlist ----------------------------------------------------------
  unless Playlist.exists?(account: remax_account, name: "Evening Showcase")
    playlist = Playlist.create!(account: remax_account, name: "Evening Showcase", status: "published")
    remax_ads = Ad.where(account: remax_account).order(:id)
    remax_ads.each_with_index do |ad, i|
      PlaylistAd.create!(playlist: playlist, ad: ad, position: i + 1, duration: 15)
    end
    puts "Created playlist: Evening Showcase (#{remax_ads.count} ads)"
  end

  # -- Screen Content ----------------------------------------------------
  window_display = Screen.joins(:site).find_by(name: "Window Display", sites: { account_id: remax_account.id })
  evening_showcase = Playlist.find_by(account: remax_account, name: "Evening Showcase")

  if window_display && evening_showcase
    unless ScreenContent.exists?(screen: window_display, contentable: evening_showcase)
      ScreenContent.create!(screen: window_display, contentable: evening_showcase, active: true)
      puts "Assigned Evening Showcase to Window Display"
    end
  end

  # -- Experience --------------------------------------------------------
  if fifth_ave && jane && !Experience.exists?(account: remax_account, name: "350 Fifth Ave Open House")
    listing_exp = Experiences::ListingExperience.create!(listing: fifth_ave, agent: jane)
    Experience.create!(
      account: remax_account,
      experienceable: listing_exp,
      name: "350 Fifth Ave Open House",
      config: { sections: { photos: true, details: true, agent_card: true, qr_handoff: true, floor_plans: true }, idle_timeout: 30, theme: "dark" }
    )
    puts "Created experience: 350 Fifth Ave Open House"
  end

  # -- Leads -------------------------------------------------------------
  unless Lead.exists?(account: remax_account, name: "Sarah Chen")
    lead = Lead.create!(
      account: remax_account, listing: fifth_ave,
      name: "Sarah Chen", email: "sarah.chen@example.com", phone: "212-555-0142",
      lead_type: "buyer_inquiry", status: "new",
      message: "Hi, I saw this listing on your window display and I'm very interested. Could we schedule a viewing this weekend?"
    )
    lead.lead_agents.create!(agent: jane) if jane
    puts "Created lead: Sarah Chen (buyer inquiry)"
  end

  unless Lead.exists?(account: remax_account, name: "Michael Torres")
    lead = Lead.create!(
      account: remax_account,
      name: "Michael Torres", email: "m.torres@example.com",
      lead_type: "general_inquiry", status: "contacted",
      message: "Looking to sell my 2BR in the area. What's the market like right now?"
    )
    lead.lead_agents.create!(agent: jane) if jane
    puts "Created lead: Michael Torres (general inquiry)"
  end

  unless Lead.exists?(account: remax_account, name: "Emily Park")
    lead = Lead.create!(
      account: remax_account, listing: fifth_ave,
      name: "Emily Park", phone: "917-555-0198",
      lead_type: "renter_inquiry", status: "qualified",
      message: "Is the apartment at 350 Fifth Ave available for a 12-month lease?"
    )
    lead.lead_agents.create!(agent: jane) if jane
    puts "Created lead: Emily Park (renter inquiry)"
  end

  unless Lead.exists?(account: remax_account, name: "David Kim")
    Lead.create!(
      account: remax_account,
      name: "David Kim", email: "david.kim@example.com",
      lead_type: "seller_inquiry", status: "closed"
    )
    puts "Created lead: David Kim (seller inquiry, closed)"
  end

  # Time-distributed leads for chart data (30 days)
  if Lead.where(account: remax_account).count < 10
    names = [ "Alex Rivera", "Priya Patel", "Marcus Chen", "Olivia Brown", "James Wilson",
              "Sofia Garcia", "Liam O'Brien", "Amara Okafor", "Noah Taylor", "Isla Nguyen",
              "Ethan Roberts", "Maya Johansson" ]
    types = Lead::TYPES
    statuses = Lead::STATUSES

    names.each do |name|
      days_ago = rand(1..28)
      lead = Lead.create!(
        account: remax_account,
        listing: [ fifth_ave, w34th, greenwich, nil ].sample,
        name: name,
        email: "#{name.downcase.tr(" '", ".")}@example.com",
        lead_type: types.sample,
        status: statuses.sample,
        message: [ "Interested in scheduling a viewing", "What's the asking price?", "Is this still available?", nil ].sample,
        created_at: days_ago.days.ago + rand(8..20).hours
      )
      lead.lead_agents.create!(agent: [ jane, tom ].compact.sample) if rand < 0.7
    end
    puts "Created #{names.size} time-distributed leads"
  end

  # -- Invite ------------------------------------------------------------
  unless Invite.exists?(account: remax_account, email: "new.agent@remax.com")
    Invite.create!(
      account: remax_account,
      invited_by: remax_owner,
      email: "new.agent@remax.com",
      role: "agent"
    )
    puts "Created invite: new.agent@remax.com (agent, pending)"
  end
end

# =====================================================================
# ACCOUNT 3: Compass Downtown (smaller brokerage)
# =====================================================================
puts "\n=== Compass Downtown ==="

unless Account.exists?(name: "Compass Downtown")
  Account.create!(name: "Compass Downtown")
  puts "Created account: Compass Downtown"
end
compass_account = Account.find_by(name: "Compass Downtown")

# -- Users -------------------------------------------------------------
unless User.exists?(email_address: "owner@compass.com")
  owner = User.create!(
    email_address: "owner@compass.com",
    first_name: "David",
    last_name: "Chen",
    phone: "+12125550020",
    password: "password"
  )
  AccountUser.create!(account: compass_account, user: owner, role: "owner")
  puts "Created user: owner@compass.com / password (owner)"
end
compass_owner = User.find_by(email_address: "owner@compass.com")

unless User.exists?(email_address: "agent.01@compass.com")
  agent = User.create!(
    email_address: "agent.01@compass.com",
    first_name: "Sofia",
    last_name: "Ruiz",
    phone: "+12125550021",
    password: "password"
  )
  AccountUser.create!(account: compass_account, user: agent, role: "agent")
  puts "Created user: agent.01@compass.com / password (agent)"
end
compass_agent1 = User.find_by(email_address: "agent.01@compass.com")

ActsAsTenant.with_tenant(compass_account) do
  # -- Site & Screen -----------------------------------------------------
  unless Site.exists?(name: "SoHo Office")
    Site.create!(account: compass_account, name: "SoHo Office", address: "72 Spring St, New York, NY 10012")
    puts "Created site: SoHo Office"
  end
  soho = Site.find_by(name: "SoHo Office")
  attach_seed_image(soho, :photo, "site-gallery.jpg") if soho

  if soho && !Screen.exists?(site: soho, name: "Window Display")
    Screen.create!(site: soho, name: "Window Display", orientation: "landscape")
    puts "Created screen: Window Display (SoHo)"
  end

  # -- Agent -------------------------------------------------------------
  unless Agent.exists?(account: compass_account, email: "agent.01@compass.com")
    Agent.create!(
      account: compass_account,
      user: compass_agent1,
      name: "Sofia Ruiz",
      email: "agent.01@compass.com",
      phone: "+12125550021",
      bio: "Bilingual agent specializing in SoHo and Nolita properties. 8 years of experience helping families find their dream home."
    )
    puts "Created agent: Sofia Ruiz (linked to agent.01@compass.com)"
  end
  sofia = Agent.find_by(account: compass_account, email: "agent.01@compass.com")
  attach_seed_image(sofia, :photo, "agent-tom.jpg") if sofia

  # -- Listings ----------------------------------------------------------
  unless Listing.exists?(account: compass_account, address: "72 Spring St, Unit 4A, New York, NY 10012")
    Listing.create!(
      account: compass_account,
      address: "72 Spring St, Unit 4A, New York, NY 10012",
      price: 1_950_000,
      beds: 2, baths: 1, sqft: 1100,
      status: "active",
      property_type: "condo",
      listing_type: "for_sale"
    )
    puts "Created listing: 72 Spring St, Unit 4A"
  end
  spring_st = Listing.find_by(account: compass_account, address: "72 Spring St, Unit 4A, New York, NY 10012")
  attach_seed_photos(spring_st, "house-3.jpg", "interior-1.jpg") if spring_st

  unless Listing.exists?(account: compass_account, address: "210 Lafayette St, New York, NY 10012")
    Listing.create!(
      account: compass_account,
      address: "210 Lafayette St, New York, NY 10012",
      price: 5_200,
      beds: 1, baths: 1, sqft: 750,
      status: "active",
      property_type: "apartment",
      listing_type: "for_rent"
    )
    puts "Created listing: 210 Lafayette St (rental)"
  end
  lafayette = Listing.find_by(account: compass_account, address: "210 Lafayette St, New York, NY 10012")
  attach_seed_photos(lafayette, "house-4.jpg") if lafayette

  # QR codes
  [ spring_st, lafayette ].compact.each { |listing| listing.qr_code_for }

  # -- Listing Agents ----------------------------------------------------
  if sofia && spring_st && !ListingAgent.exists?(listing: spring_st, agent: sofia)
    ListingAgent.create!(listing: spring_st, agent: sofia, role: "listing_agent", primary_at: Time.current)
    puts "Assigned Sofia Ruiz to 72 Spring St (primary)"
  end
  if sofia && lafayette && !ListingAgent.exists?(listing: lafayette, agent: sofia)
    ListingAgent.create!(listing: lafayette, agent: sofia, role: "listing_agent", primary_at: Time.current)
    puts "Assigned Sofia Ruiz to 210 Lafayette St (primary)"
  end

  # -- Ads ---------------------------------------------------------------
  unless Ad.exists?(account: compass_account, headline: "SoHo Gem")
    listing_ad = Ads::ListingAd.create!(listing: spring_st, badge: "just_listed")
    Ad.create!(
      account: compass_account, adable: listing_ad,
      headline: "SoHo Gem",
      body: "Charming 2BR in the heart of SoHo.",
      layout: "hero", theme: "dark"
    )
    puts "Created ListingAd: SoHo Gem"
  end
  soho_ad = Ad.find_by(account: compass_account, headline: "SoHo Gem")
  attach_seed_image(soho_ad, :image, "house-3.jpg") if soho_ad

  unless Ad.exists?(account: compass_account, headline: "Now Leasing")
    listing_ad = Ads::ListingAd.create!(listing: lafayette, badge: "just_listed")
    Ad.create!(
      account: compass_account, adable: listing_ad,
      headline: "Now Leasing",
      body: "Modern 1BR steps from Lafayette.",
      layout: "split", theme: "dark"
    )
    puts "Created ListingAd: Now Leasing"
  end
  leasing_ad = Ad.find_by(account: compass_account, headline: "Now Leasing")
  attach_seed_image(leasing_ad, :image, "house-4.jpg") if leasing_ad

  # -- Playlist ----------------------------------------------------------
  unless Playlist.exists?(account: compass_account, name: "SoHo Showcase")
    playlist = Playlist.create!(account: compass_account, name: "SoHo Showcase", status: "published")
    compass_ads = Ad.where(account: compass_account).order(:id)
    compass_ads.each_with_index do |ad, i|
      PlaylistAd.create!(playlist: playlist, ad: ad, position: i + 1, duration: 12)
    end
    puts "Created playlist: SoHo Showcase (#{compass_ads.count} ads)"
  end

  # -- Screen Content ----------------------------------------------------
  soho_screen = Screen.joins(:site).find_by(name: "Window Display", sites: { account_id: compass_account.id })
  soho_showcase = Playlist.find_by(account: compass_account, name: "SoHo Showcase")

  if soho_screen && soho_showcase
    unless ScreenContent.exists?(screen: soho_screen, contentable: soho_showcase)
      ScreenContent.create!(screen: soho_screen, contentable: soho_showcase, active: true)
      puts "Assigned SoHo Showcase to Window Display"
    end
  end

  # -- Leads -------------------------------------------------------------
  unless Lead.exists?(account: compass_account, name: "Anna Kowalski")
    lead = Lead.create!(
      account: compass_account, listing: spring_st,
      name: "Anna Kowalski", email: "anna.k@example.com",
      lead_type: "buyer_inquiry", status: "new",
      message: "Love the SoHo location. Is this still available?"
    )
    lead.lead_agents.create!(agent: sofia) if sofia
    puts "Created lead: Anna Kowalski"
  end

  unless Lead.exists?(account: compass_account, name: "Ryan Mitchell")
    lead = Lead.create!(
      account: compass_account, listing: lafayette,
      name: "Ryan Mitchell", email: "ryan.m@example.com",
      lead_type: "renter_inquiry", status: "contacted",
      message: "Looking for a December 1st move-in. Is that possible?"
    )
    lead.lead_agents.create!(agent: sofia) if sofia
    puts "Created lead: Ryan Mitchell"
  end
end

# =====================================================================
# Ahoy Events: Impressions (RE/MAX — 30 days)
# =====================================================================
puts "\n=== Analytics ==="

if Ahoy::Event.for_account(remax_account).where(name: "content.impressed").empty?
  screen = Screen.joins(:site).find_by(sites: { account_id: remax_account.id })
  screen_content = screen&.active_screen_content
  playlist = Playlist.find_by(account: remax_account, status: "published")
  ads = Ad.where(account: remax_account).limit(5).to_a

  if screen && ads.any?
    seed_visit = Ahoy::Visit.create!(
      visit_token: SecureRandom.hex(16),
      visitor_token: SecureRandom.hex(16),
      started_at: 30.days.ago
    )

    events = []
    30.downto(1) do |days_ago|
      date = days_ago.days.ago.to_date
      daily_count = rand(200..400)
      daily_count.times do
        ad = ads.sample
        playlist_ad = playlist&.playlist_ads&.find_by(ad: ad)
        events << {
          visit_id: seed_visit.id,
          name: "content.impressed",
          properties: {
            account_pid: remax_account.public_id,
            ad_pid: ad.public_id,
            screen_pid: screen.public_id,
            screen_content_pid: screen_content&.public_id,
            playlist_pid: playlist&.public_id,
            position: playlist_ad&.position || rand(1..5),
            duration: playlist_ad&.duration || 10
          },
          time: date + rand(8..16).hours + rand(0..59).minutes
        }
      end
    end

    Ahoy::Event.insert_all(events)
    puts "Created #{events.size} impression events (30 days)"
  end
end

# QR Scan Events (RE/MAX — 30 days)
if Analytics::Events::QrScanned.events.for_account(remax_account).empty?
  qr_codes = QrCode.where(account: remax_account).to_a
  demo_visit = Ahoy::Visit.find_or_create_by!(visit_token: "demo-scan-visit") do |v|
    v.visitor_token = "demo-scan-visitor"
    v.started_at = 30.days.ago
  end

  if qr_codes.any?
    events = []

    30.downto(1) do |days_ago|
      date = days_ago.days.ago.to_date
      daily_count = rand(2..8)
      daily_count.times do
        qr_code = qr_codes.sample
        events << {
          visit_id: demo_visit.id,
          name: "qr.scanned",
          properties: {
            account_pid: remax_account.public_id,
            qr_code_pid: qr_code.public_id,
            destination_url: "/go/listings/#{qr_code.destination_record&.to_param}"
          },
          time: date + rand(8..20).hours + rand(0..59).minutes
        }
      end
    end

    Ahoy::Event.insert_all(events)
    puts "Created #{events.size} qr.scanned events (30 days)"
  end
end

# Rollups
if Rollup.count.zero?
  AnalyticsRollupJob.new.perform
  puts "Created #{Rollup.count} rollup entries"
end

# =====================================================================
# Summary
# =====================================================================
puts "\n=== Seed Summary ==="
puts "Accounts:        #{Account.count}"
puts "Users:           #{User.count}"
puts "Account members: #{AccountUser.count}"
puts "Sites:           #{Site.count}"
puts "Screens:         #{Screen.count}"
puts "Players:         #{Player.count}"
puts "Agents:          #{Agent.count}"
puts "Listings:        #{Listing.count}"
puts "Ads:             #{Ad.count}"
puts "Playlists:       #{Playlist.count}"
puts "Screen contents: #{ScreenContent.count}"
puts "Experiences:     #{Experience.count}"
puts "QR codes:        #{QrCode.count}"
puts "Leads:           #{Lead.count}"
puts "Invites:         #{Invite.count}"
puts "Ahoy events:     #{Ahoy::Event.count}"
puts "Rollups:         #{Rollup.count}"
