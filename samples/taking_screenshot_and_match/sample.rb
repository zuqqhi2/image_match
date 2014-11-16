require 'capybara'
require 'capybara/poltergeist'
require 'image_match'
include ImageMatch

# Get current google web page image
url = 'http://google.com/'
Capybara.javascript_driver = :poltergeist
Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new app, js_errors: false
end
Capybara.default_selector = :xpath

session = Capybara::Session.new(:poltergeist)
session.driver.headers = {'User-Agent' => "Mozilla/5.0 (Macintosh; Intel Mac OS X)"}
session.visit(url)

session.save_screenshot('screenshot.png', full: true)

# Compare logo (output match result image)
if perfect_match_template('./screenshot.png', './google-logo.jpg', 0.9, true)
  puts "Same!"
else
  puts "Different..."
end
