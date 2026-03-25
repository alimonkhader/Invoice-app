require "rails_helper"

RSpec.describe ApplicationCable::Channel, type: :channel do
  it "inherits from ActionCable::Channel::Base" do
    expect(described_class < ActionCable::Channel::Base).to be(true)
  end
end
