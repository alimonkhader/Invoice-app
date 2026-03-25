require "rails_helper"

RSpec.describe ApplicationRecord, type: :model do
  it "is an abstract class" do
    expect(described_class).to be_abstract_class
  end
end
