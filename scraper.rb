require "epathway_scraper"

base_url = "https://eservices.salisbury.sa.gov.au/ePathway/Production/Web"

scraper = EpathwayScraper::Scraper.new(
  "https://eservices.salisbury.sa.gov.au/ePathway/Production"
)

agent = scraper.agent

enquiry_lists_page = agent.get(scraper.base_url)

enquiry_search_page = scraper.click_date_search_tab(enquiry_lists_page)
# The Date tab defaults to a search range of the last 30 days.
results_page = scraper.click_search_on_page(enquiry_search_page)

count = 0
applications = []
while results_page
  count += 1
  puts "Parsing the results on page #{count}."

  table = results_page.root.at_css('.ContentPanel')
  headers = table.css('th').collect { |th| th.inner_text.strip }
  applications += table.css('.ContentPanel, .AlternateContentPanel').collect do |tr|
    tr.css('td').collect { |td| td.inner_text.strip }
  end

  if count > 50  # safety precaution
    puts "Stopping paging after #{count} pages."
    break
  end

  next_page_image = results_page.root.at_xpath("//td/input[contains(@src, 'nextPage')]")
  results_page = nil
  if next_page_image
    next_page_path = next_page_image['onclick'].split(',').find { |e| e =~ /.*PageNumber=\d+.*/ }.gsub('"', '').strip
    puts "Retrieving the next page: #{next_page_path}"
    results_page = agent.get "#{base_url}/GeneralEnquiry/#{next_page_path}"
  end
end

# Construct development application records that can be inserted into the database.

application_records = applications.collect do |application|
  {
    'council_reference' => application[headers.index('Application Number')],
    'info_url' => "#{base_url}/default.aspx",
    'description' => application[headers.index('Application Description')],
    'date_received' => Date.strptime(application[headers.index('Lodgement Date')], '%d/%m/%Y').to_s,
    'address' => application[headers.index('Site Address')],
    'date_scraped' => Date.today.to_s
  }
end

# Insert the records into the database.

puts "Updating the database."
application_records.each do |application_record|
  EpathwayScraper.save(application_record)
end
