class ApplicationMailer < ActionMailer::Base
  default from: ENV.fetch("MAIL_FROM", "no-reply@invoiceapp.local")
  layout "mailer"
end
