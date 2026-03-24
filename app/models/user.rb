class User < ApplicationRecord
  ROLES = %w[admin account_admin].freeze

  attr_accessor :password

  belongs_to :plan, optional: true
  has_many :plan_purchases, dependent: :destroy

  before_validation :normalize_email
  before_validation :apply_password_digest, if: :password_present?
  before_validation :apply_plan_snapshot, on: :create, if: :account_admin?
  before_validation :assign_plan_dates, on: :create, if: :assign_plan_dates?

  validates :name, :email, :role, :password_salt, :password_digest, presence: true
  validates :email, uniqueness: true
  validates :role, inclusion: { in: ROLES }
  validates :company_name, presence: true, if: :account_admin?
  validates :phone, presence: true, if: :account_admin?
  validates :plan, presence: true, if: :account_admin?
  validates :password, presence: true, on: :create

  scope :active, -> { where(active: true) }
  scope :admins, -> { active.where(role: "admin") }
  scope :account_admins, -> { includes(:plan).where(role: "account_admin").order(created_at: :desc) }
  scope :active_account_admins, -> { active.includes(:plan).where(role: "account_admin").order(created_at: :desc) }

  def authenticate(submitted_password)
    expected_digest = self.class.digest_password(submitted_password, password_salt)
    ActiveSupport::SecurityUtils.secure_compare(password_digest, expected_digest)
  rescue ArgumentError
    false
  end

  def admin?
    role == "admin"
  end

  def account_admin?
    role == "account_admin"
  end

  def activate_plan_access!
    apply_plan_snapshot
    self.active = true
    self.status = "active"
    self.started_on = Date.current
    self.expires_on = plan&.duration_months.to_i.positive? ? started_on.advance(months: plan.duration_months) : nil
    save!
  end

  def self.digest_password(password, salt)
    Digest::SHA256.hexdigest("#{salt}--#{password}")
  end

  private

  def normalize_email
    self.email = email.to_s.strip.downcase
  end

  def password_present?
    password.present?
  end

  def apply_password_digest
    self.password_salt = SecureRandom.hex(16)
    self.password_digest = self.class.digest_password(password, password_salt)
  end

  def apply_plan_snapshot
    return unless plan

    self.plan_price = plan.price
    self.invoice_limit = plan.invoice_limit
    self.excel_reports_enabled = plan.excel_reports
    self.status ||= active? ? "active" : "payment_pending"
  end

  def assign_plan_dates?
    account_admin? && active?
  end

  def assign_plan_dates
    self.started_on ||= Date.current
    self.expires_on ||= plan.duration_months.positive? ? started_on.advance(months: plan.duration_months) : nil
  end
end
