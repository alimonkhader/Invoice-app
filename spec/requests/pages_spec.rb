require "rails_helper"

RSpec.describe "Pages", type: :request do
  it "renders the about page" do
    get about_us_path

    expect(response).to have_http_status(:ok)
  end

  it "renders the terms page" do
    get terms_and_conditions_path

    expect(response).to have_http_status(:ok)
  end
end
