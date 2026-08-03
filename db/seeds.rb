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
