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
