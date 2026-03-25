require "rails_helper"

RSpec.describe Company, type: :model do
  it "can be instantiated" do
    expect(described_class.new).to be_a(described_class)
  end
end
