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
end
puts "Seeded #{Listing.count} listing(s)"
