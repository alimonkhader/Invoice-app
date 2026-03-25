require "rails_helper"

RSpec.describe RazorpayClient do
  around do |example|
    original_id = ENV["RAZORPAY_KEY_ID"]
    original_secret = ENV["RAZORPAY_KEY_SECRET"]
    example.run
  ensure
    ENV["RAZORPAY_KEY_ID"] = original_id
    ENV["RAZORPAY_KEY_SECRET"] = original_secret
  end

  describe ".configured?" do
    it "is true only when both keys are present" do
      ENV["RAZORPAY_KEY_ID"] = "key"
      ENV["RAZORPAY_KEY_SECRET"] = "secret"
      expect(described_class.configured?).to be(true)

      ENV["RAZORPAY_KEY_SECRET"] = nil
      expect(described_class.configured?).to be(false)
    end
  end

  describe ".key_id and .key_secret" do
    it "return environment values as strings" do
      ENV["RAZORPAY_KEY_ID"] = "key"
      ENV["RAZORPAY_KEY_SECRET"] = "secret"

      expect(described_class.key_id).to eq("key")
      expect(described_class.key_secret).to eq("secret")
      expect(described_class.checkout_enabled?).to be(true)
    end
  end

  describe "#create_order" do
    it "raises when not configured" do
      ENV["RAZORPAY_KEY_ID"] = nil
      ENV["RAZORPAY_KEY_SECRET"] = nil

      expect {
        described_class.new.create_order(amount_subunits: 100, currency: "INR", receipt: "r1")
      }.to raise_error(RazorpayClient::Error, /Razorpay is not configured/)
    end

    it "returns parsed json on success" do
      ENV["RAZORPAY_KEY_ID"] = "key"
      ENV["RAZORPAY_KEY_SECRET"] = "secret"
      response = instance_double(Net::HTTPSuccess, body: '{"id":"order_1"}')
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      http = instance_double(Net::HTTP)
      allow(http).to receive(:request).and_return(response)
      allow(Net::HTTP).to receive(:start).and_yield(http)

      body = described_class.new.create_order(amount_subunits: 100, currency: "INR", receipt: "r1", notes: { plan: "basic" })

      expect(body).to eq("id" => "order_1")
    end

    it "raises a razorpay error description on non-success responses" do
      ENV["RAZORPAY_KEY_ID"] = "key"
      ENV["RAZORPAY_KEY_SECRET"] = "secret"
      response = instance_double(Net::HTTPResponse, body: '{"error":{"description":"bad request"}}', code: "400")
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)
      http = instance_double(Net::HTTP)
      allow(http).to receive(:request).and_return(response)
      allow(Net::HTTP).to receive(:start).and_yield(http)

      expect {
        described_class.new.create_order(amount_subunits: 100, currency: "INR", receipt: "r1")
      }.to raise_error(RazorpayClient::Error, "bad request")
    end

    it "raises a parse error for invalid json" do
      ENV["RAZORPAY_KEY_ID"] = "key"
      ENV["RAZORPAY_KEY_SECRET"] = "secret"
      response = instance_double(Net::HTTPSuccess, body: "not-json")
      allow(response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)
      http = instance_double(Net::HTTP)
      allow(http).to receive(:request).and_return(response)
      allow(Net::HTTP).to receive(:start).and_yield(http)

      expect {
        described_class.new.create_order(amount_subunits: 100, currency: "INR", receipt: "r1")
      }.to raise_error(RazorpayClient::Error, "Unable to parse Razorpay response.")
    end

    it "wraps unexpected exceptions as connection errors" do
      ENV["RAZORPAY_KEY_ID"] = "key"
      ENV["RAZORPAY_KEY_SECRET"] = "secret"
      allow(Net::HTTP).to receive(:start).and_raise(StandardError, "boom")

      expect {
        described_class.new.create_order(amount_subunits: 100, currency: "INR", receipt: "r1")
      }.to raise_error(RazorpayClient::Error, /Unable to connect to Razorpay: boom/)
    end
  end

  describe "#verify_payment_signature" do
    it "returns true for a matching signature" do
      ENV["RAZORPAY_KEY_SECRET"] = "secret"
      signature = OpenSSL::HMAC.hexdigest("SHA256", "secret", "order|payment")

      expect(described_class.new.verify_payment_signature(order_id: "order", payment_id: "payment", signature: signature)).to be(true)
    end

    it "returns false when compare raises" do
      allow(ActiveSupport::SecurityUtils).to receive(:secure_compare).and_raise(ArgumentError)

      expect(described_class.new.verify_payment_signature(order_id: "order", payment_id: "payment", signature: "sig")).to be(false)
    end
  end
end
