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
while results_page
  count += 1
  puts "Parsing the results on page #{count}."

  table = results_page.root.at_css('.ContentPanel')
  scraper.extract_table_data_and_urls(table).each do |row|
    data = scraper.extract_index_data(row)
    record = {
      'council_reference' => data[:council_reference],
      'info_url' => scraper.base_url,
      'description' => data[:description],
      'date_received' => data[:date_received],
      'address' => data[:address],
      'date_scraped' => Date.today.to_s
    }
    EpathwayScraper.save(record)
  end

  next_page_image = results_page.root.at_xpath("//td/input[contains(@src, 'nextPage')]")
  results_page = nil
  if next_page_image
    next_page_path = next_page_image['onclick'].split(',').find { |e| e =~ /.*PageNumber=\d+.*/ }.gsub('"', '').strip
    puts "Retrieving the next page: #{next_page_path}"
    results_page = agent.get "#{base_url}/GeneralEnquiry/#{next_page_path}"
  end
end
