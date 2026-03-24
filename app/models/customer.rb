class Customer < ApplicationRecord
  belongs_to :user, optional: true
  has_many :invoices, dependent: :restrict_with_exception
end
