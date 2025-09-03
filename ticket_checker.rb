# gem install nokogiri httparty mail
require 'httparty'
require 'nokogiri'
require 'mail'

BOOKMYSHOW_URL = "https://in.bookmyshow.com/cinemas/hyderabad/pvr-nexus-mall-kukatpally-hyderabad/buytickets/PVFS/20250904"
TARGET_DAY     = "04"
TARGET_MONTH   = "Sep"

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

def tickets_live?
  response = HTTParty.get(BOOKMYSHOW_URL, follow_redirects: true)
  doc = Nokogiri::HTML(response.body)

  # find all date blocks
  date_blocks = doc.css("div.sc-h5edv-0")
  p date_blocks
  target_block = date_blocks.find do |div|
    day   = div.at_css("span.sc-h5edv-2")&.text&.strip
    month = div.at_css("span.sc-h5edv-3")&.text&.strip
    day == TARGET_DAY && month == TARGET_MONTH
  end

  if target_block.nil?
    puts "⚠️ Could not find target date #{TARGET_DAY} #{TARGET_MONTH}"
    return false
  end

  # detect if it's disabled (look for "disabled" in parent div or class)
  if target_block["class"]&.include?("disabled") ||
     target_block.ancestors.any? { |a| a["class"].to_s.include?("disabled") }
    puts "ℹ️ Date #{TARGET_DAY} #{TARGET_MONTH} found but still disabled"
    return false
  end

  # if the movie title exists → tickets are live
  if doc.text.match(/Conjuring.*Last Rites/i)
    return true
  else
    puts "ℹ️ Date #{TARGET_DAY} #{TARGET_MONTH} active but movie not listed yet"
    return false
  end
end

def send_alert
  Mail.deliver do
    to ENV['GMAIL_USER']
    from ENV['GMAIL_USER']
    subject "🎟️ Tickets LIVE at PVR Nexus Mall Kukatpally 4DX!"
    body "The Conjuring: Last Rites tickets for #{TARGET_DAY} #{TARGET_MONTH} are live. Book now: #{BOOKMYSHOW_URL}"
  end
end

if tickets_live?
  puts "✅ Tickets are live!"
  send_alert
else
  puts "❌ Not yet..."
end
