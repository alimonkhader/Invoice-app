require "rails_helper"

RSpec.describe User, type: :model do
  describe "validations" do
    it "requires account admin business fields" do
      user = described_class.new(
        role: "account_admin",
        email: "test@example.com",
        name: "Test",
        active: false,
        status: "payment_pending"
      )

      expect(user).not_to be_valid
      expect(user.errors[:company_name]).to include("can't be blank")
      expect(user.errors[:phone]).to include("can't be blank")
      expect(user.errors[:plan]).to include("can't be blank")
    end

    it "accepts admins without plan fields" do
      user = build(:user, :admin)

      expect(user).to be_valid
    end
  end

  describe "callbacks" do
    it "normalizes email and snapshots plan details on create" do
      plan = create(:plan, price: 300, invoice_limit: 25, excel_reports: true, duration_months: 1)
      user = create(:user, plan: plan, email: " USER@Example.COM ")

      expect(user.email).to eq("user@example.com")
      expect(user.plan_price).to eq(300)
      expect(user.invoice_limit).to eq(25)
      expect(user.excel_reports_enabled).to be(true)
      expect(user.status).to eq("active")
      expect(user.started_on).to eq(Date.current)
      expect(user.expires_on).to eq(Date.current.advance(months: 1))
      expect(user[:password_salt]).to be_present
      expect(user[:password_digest]).to be_present
    end

    it "does not assign plan dates for inactive account admins without explicit dates" do
      user = create(:user, active: false, status: "payment_pending", started_on: nil, expires_on: nil)

      expect(user.started_on).to be_nil
      expect(user.expires_on).to be_nil
    end
  end

  describe ".digest_password" do
    it "creates a deterministic digest" do
      expect(described_class.digest_password("secret", "salt")).to eq(Digest::SHA256.hexdigest("salt--secret"))
    end
  end

  describe "#valid_password?" do
    it "works with a Devise password" do
      user = create(:user, password: "password123", password_confirmation: "password123")

      expect(user.valid_password?("password123")).to be(true)
      expect(user.valid_password?("wrong")).to be(false)
    end

    it "migrates a legacy password when encrypted_password is blank" do
      plan = create(:plan)
      user = described_class.create!(
        plan: plan,
        name: "Legacy User",
        company_name: "Legacy Co",
        email: "legacy@example.com",
        phone: "9999999999",
        role: "account_admin",
        status: "active",
        active: true,
        password: "legacy-pass",
        password_confirmation: "legacy-pass"
      )
      user.update_columns(encrypted_password: "")

      expect(user.reload.valid_password?("legacy-pass")).to be(true)
      expect(user.reload.encrypted_password).to be_present
    end

    it "returns false when legacy digest is missing" do
      user = build(:user)
      user[:password_salt] = ""
      user[:password_digest] = ""
      user.encrypted_password = ""

      expect(user.valid_password?("password123")).to be(false)
    end

    it "returns false when secure compare raises" do
      user = build(:user)
      user[:password_salt] = "salt"
      user[:password_digest] = "digest"
      user.encrypted_password = ""
      allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_raise(ArgumentError)

      expect(user.valid_password?("password123")).to be(false)
    end
  end

  describe "#send_reset_password_instructions" do
    it "normalizes the email before sending instructions" do
      user = create(:user, email: " MIXED@Example.COM ")
      ActionMailer::Base.default_url_options[:host] = "example.com"

      user.send_reset_password_instructions

      expect(user.email).to eq("mixed@example.com")
      expect(user.reload.reset_password_token).to be_present
    end
  end

  describe "role helpers" do
    it "detects admin and account admin roles" do
      expect(build(:user, :admin)).to be_admin
      expect(build(:user)).to be_account_admin
    end
  end

  describe "#activate_plan_access!" do
    it "activates the plan and carries forward existing validity" do
      plan = create(:plan, price: 500, invoice_limit: 99, excel_reports: true, duration_months: 2)
      user = create(:user, plan: plan, active: false, status: "payment_pending", expires_on: Date.current + 5.days)

      user.activate_plan_access!

      expect(user.reload).to have_attributes(
        active: true,
        status: "active",
        started_on: Date.current,
        plan_price: 500,
        invoice_limit: 99,
        excel_reports_enabled: true,
        expires_on: (Date.current + 5.days).advance(months: 2)
      )
    end
  end

  describe "#next_plan_expiry_date" do
    it "returns nil when the plan has no duration" do
      user = build(:user, plan: build(:plan, duration_months: 0))

      expect(user.next_plan_expiry_date).to be_nil
    end

    it "uses the later of today or current carried validity" do
      user = build(:user, plan: build(:plan, duration_months: 1), expires_on: Date.new(2026, 4, 10))

      expect(user.next_plan_expiry_date(reference_date: Date.new(2026, 3, 25))).to eq(Date.new(2026, 5, 10))
    end

    it "starts from the reference date when the current expiry is in the past" do
      user = build(:user, plan: build(:plan, duration_months: 1), expires_on: Date.new(2026, 3, 1))

      expect(user.next_plan_expiry_date(reference_date: Date.new(2026, 3, 25))).to eq(Date.new(2026, 4, 25))
    end
  end
end
