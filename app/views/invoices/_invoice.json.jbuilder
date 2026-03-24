json.extract! invoice, :id, :invoice_number, :date, :customer_id, :total, :created_at, :updated_at
json.url invoice_url(invoice, format: :json)
