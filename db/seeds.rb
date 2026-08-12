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

  User.create!(
    account:        account,
    email_address:  "demo@example.com",
    first_name:     "Demo",
    last_name:      "User",
    phone:          "+12125550001",
    password:       "password"
  )
  puts "Created demo user: demo@example.com / password"
end

demo_account = User.find_by(email_address: "demo@example.com")&.account

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
end
puts "Seeded #{Listing.count} listing(s)"

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
    listing_ad = ListingAd.create!(listing: fifth_ave, badge: "just_listed")
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
    listing_ad = ListingAd.create!(
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
    collection_ad = CollectionAd.create!(collection_title: "Featured Listings")
    member_ads = Ad.where(account: demo_account).where(adable_type: "ListingAd").order(:id)
    member_ads.each_with_index do |ad, i|
      CollectionAdAd.create!(collection_ad: collection_ad, ad: ad, position: i)
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
      agent_ad = AgentAd.create!(agent: jane)
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
    brand_ad = BrandAd.create!
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
