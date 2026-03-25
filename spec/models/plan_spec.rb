require "rails_helper"

RSpec.describe Plan, type: :model do
  describe "validations" do
    it "requires core attributes" do
      plan = described_class.new(name: nil, code: nil, price: -1)

      expect(plan).not_to be_valid
      expect(plan.errors[:name]).to include("can't be blank")
      expect(plan.errors[:code]).to include("can't be blank")
      expect(plan.errors[:price]).to include("must be greater than or equal to 0")
    end

    it "validates numeric fields" do
      plan = build(:plan, price: -1, duration_months: -1, invoice_limit: 0)

      expect(plan).not_to be_valid
      expect(plan.errors[:price]).to include("must be greater than or equal to 0")
      expect(plan.errors[:duration_months]).to include("must be greater than or equal to 0")
      expect(plan.errors[:invoice_limit]).to include("must be greater than 0")
    end
  end

  describe ".active_first" do
    it "returns active plans ordered by position and price" do
      higher = create(:plan, active: true, position: 2, price: 200)
      lower = create(:plan, active: true, position: 1, price: 100)
      create(:plan, active: false, position: 0, price: 1)

      expect(described_class.active_first).to eq([lower, higher])
    end
  end

  describe ".ordered" do
    it "orders by position, price, and name" do
      third = create(:plan, position: 2, price: 200, name: "Third")
      first = create(:plan, position: 1, price: 100, name: "First")
      second = create(:plan, position: 1, price: 100, name: "Second")

      expect(described_class.ordered).to eq([first, second, third])
    end
  end

  describe "#unlimited_invoices?" do
    it "is true when invoice_limit is nil" do
      expect(build(:plan, invoice_limit: nil)).to be_unlimited_invoices
    end

    it "is false when invoice_limit exists" do
      expect(build(:plan, invoice_limit: 10)).not_to be_unlimited_invoices
    end
  end

  describe "#duration_label" do
    it "returns the trial label" do
      expect(build(:plan, duration_months: 0).duration_label).to eq("Trial")
    end

    it "returns a singular month label" do
      expect(build(:plan, duration_months: 1).duration_label).to eq("1 month")
    end

    it "returns a plural month label" do
      expect(build(:plan, duration_months: 3).duration_label).to eq("3 months")
    end
  end
end
