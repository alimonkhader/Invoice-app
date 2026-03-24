require "net/http"
require "json"
require "openssl"

class RazorpayClient
  class Error < StandardError; end

  API_BASE_URL = "https://api.razorpay.com".freeze

  def self.configured?
    ENV["RAZORPAY_KEY_ID"].present? && ENV["RAZORPAY_KEY_SECRET"].present?
  end

  def self.key_id
    ENV["RAZORPAY_KEY_ID"].to_s
  end

  def self.key_secret
    ENV["RAZORPAY_KEY_SECRET"].to_s
  end

  def self.checkout_enabled?
    configured?
  end

  def create_order(amount_subunits:, currency:, receipt:, notes: {})
    raise Error, "Razorpay is not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET." unless self.class.configured?

    request_json(
      Net::HTTP::Post,
      "/v1/orders",
      {
        amount: amount_subunits,
        currency: currency,
        receipt: receipt,
        notes: notes
      }
    )
  end

  def verify_payment_signature(order_id:, payment_id:, signature:)
    expected_signature = OpenSSL::HMAC.hexdigest(
      "SHA256",
      self.class.key_secret,
      "#{order_id}|#{payment_id}"
    )

    ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature.to_s)
  rescue ArgumentError
    false
  end

  private

  def request_json(request_class, path, payload)
    uri = URI.join(API_BASE_URL, path)
    request = request_class.new(uri)
    request.basic_auth(self.class.key_id, self.class.key_secret)
    request["Content-Type"] = "application/json"
    request.body = payload.to_json

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      http.request(request)
    end

    body = response.body.present? ? JSON.parse(response.body) : {}
    return body if response.is_a?(Net::HTTPSuccess)

    raise Error, body["error"]&.dig("description") || "Razorpay request failed with status #{response.code}."
  rescue JSON::ParserError
    raise Error, "Unable to parse Razorpay response."
  rescue StandardError => e
    raise Error, e.message if e.is_a?(Error)

    raise Error, "Unable to connect to Razorpay: #{e.message}"
  end
end
