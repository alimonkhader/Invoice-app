# Nilam Invoice

## Invoice Delivery

The app supports invoice delivery from the invoice detail page:

- **Send Email**: sends invoice PDF attachment to the customer's email.
- **Send WhatsApp**: opens WhatsApp with a prefilled message and invoice PDF link.

## Required Environment Variables

- `APP_HOST` (example: `localhost` in development, your domain in production)
- `APP_PORT` (development only, usually `3000`)
- `MAIL_FROM` (example: `billing@yourdomain.com`)

## Email Setup (SMTP)

Configure Action Mailer SMTP settings for your environment (`development.rb` / `production.rb`), for example using Gmail/SendGrid/SES.

Without SMTP configuration, email buttons will queue mail but actual delivery may fail or be skipped depending on environment settings.
