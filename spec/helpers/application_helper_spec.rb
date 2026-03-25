require "rails_helper"

RSpec.describe ApplicationHelper, type: :helper do
  it "loads the helper module" do
    expect(helper).to be_a(ActionView::Base)
  end
end
