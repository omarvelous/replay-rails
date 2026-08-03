require "rails_helper"

RSpec.describe "Authentication", type: :system do
  describe "signup" do
    it "visitor can sign up and is redirected into the app" do
      visit new_account_path

      fill_in "First name", with: "Jane"
      fill_in "Last name",  with: "Smith"
      fill_in "Email address", with: "jane@example.com"
      fill_in "Phone", with: "+12125551234"
      fill_in "Password", with: "password123"
      fill_in "Password confirmation", with: "password123"

      click_button "Sign up"

      expect(page).not_to have_current_path(new_account_path)
      expect(Account.count).to eq(1)
      expect(User.count).to eq(1)
    end

    it "prevents blank submission with browser validation" do
      visit new_account_path

      click_button "Sign up"

      expect(page).to have_current_path(new_account_path)
    end
  end

  describe "login" do
    let!(:user) { create(:user) }

    it "user can log in with valid credentials" do
      visit new_session_path

      fill_in "Email address", with: user.email_address
      fill_in "Password",      with: "password123"

      click_button "Sign in"

      expect(page).not_to have_current_path(new_session_path)
    end

    it "stays on login page with invalid credentials" do
      visit new_session_path

      fill_in "Email address", with: user.email_address
      fill_in "Password",      with: "wrong"

      click_button "Sign in"

      expect(page).to have_current_path(new_session_path)
    end
  end

  describe "logout" do
    let!(:user) { create(:user) }

    before do
      visit new_session_path
      fill_in "Email address", with: user.email_address
      fill_in "Password",      with: "password123"
      click_button "Sign in"
    end

    it "user can log out" do
      click_button "Sign out"
      expect(page).to have_current_path(new_session_path)
    end
  end
end
