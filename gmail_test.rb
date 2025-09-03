require 'mail'
p ENV['GMAIL_USER']
p ENV['GMAIL_PASS']
Mail.defaults do
  delivery_method :smtp, {
    address: "smtp.gmail.com",
    port: 587,
    user_name: ENV['GMAIL_USER'],
    password: ENV['GMAIL_PASS'],
    authentication: "plain",
    enable_starttls_auto: true
  }
end

Mail.deliver do
  to "your_email@example.com"
  from ENV['GMAIL_USER']
  subject "✅ Gmail SMTP Test"
  body "If you see this, Gmail App Password setup works!"
end
