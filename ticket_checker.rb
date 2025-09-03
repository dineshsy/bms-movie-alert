require 'playwright'
require 'mail'

# 🎯 Config
BOOKMYSHOW_URL = "https://in.bookmyshow.com/cinemas/hyderabad/pvr-nexus-mall-kukatpally-hyderabad/buytickets/PVFS/20250904"
TARGET_DATE    = ENV['TARGET_DATE'] || "04 Sep"   # can override via env

# 📧 Gmail SMTP config
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

def send_alert
  Mail.deliver do
    to ENV['GMAIL_USER']   # <-- replace with your email
    from ENV['GMAIL_USER']
    subject "🎟️ Tickets LIVE at PVR Nexus Mall Kukatpally 4DX!"
    body "The Conjuring: Last Rites tickets just went live for #{TARGET_DATE}. Book now: #{BOOKMYSHOW_URL}"
  end
end

def tickets_live?
  Playwright.create(playwright_cli_executable_path: `which npx`.strip) do |playwright|
    browser = playwright.chromium.launch(headless: true)
    page = browser.new_page
    page.goto(BOOKMYSHOW_URL)

    # Wait until at least one date block is visible
    page.wait_for_selector('div.sc-h5edv-0', timeout: 15000)

    # Extract all dates
    dates = page.query_selector_all('div.sc-h5edv-0').map do |el|
      el.inner_text.gsub("\n", " ").strip
    end

    puts "👉 Found dates: #{dates.inspect}"

    browser.close

    # Return true if target date is available
    dates.any? { |d| d.include?(TARGET_DATE) }
  end
end

# 🚀 Run check
if tickets_live?
  puts "✅ Tickets for #{TARGET_DATE} are live!"
  send_alert
else
  puts "❌ Tickets not yet available for #{TARGET_DATE}..."
end
