require "rails_helper"

RSpec.describe HomeController, type: :controller do
  describe "#current_plan_downgrade_window_open?" do
    it "returns true for free plans" do
      user = build(:user, plan: build(:plan, price: 0))
      controller.instance_variable_set(:@current_plan_user, user)

      expect(controller.send(:current_plan_downgrade_window_open?)).to be(true)
    end

    it "returns true when the expiry is blank" do
      user = build(:user, expires_on: nil)
      controller.instance_variable_set(:@current_plan_user, user)

      expect(controller.send(:current_plan_downgrade_window_open?)).to be(true)
    end

    it "checks whether the expiry is within seven days" do
      user = build(:user, expires_on: Date.current + 6.days)
      controller.instance_variable_set(:@current_plan_user, user)

      expect(controller.send(:current_plan_downgrade_window_open?)).to be(true)
    end
  end
end
