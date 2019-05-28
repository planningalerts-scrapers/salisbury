require "epathway_scraper"

base_url = "https://eservices.salisbury.sa.gov.au/ePathway/Production/Web"

scraper = EpathwayScraper::Scraper.new(
  "https://eservices.salisbury.sa.gov.au/ePathway/Production"
)

agent = scraper.agent

enquiry_lists_page = agent.get(scraper.base_url)
# Fake that we're running javascript by picking out the javascript redirect
redirected_url = enquiry_lists_page.body.match(/window.location.href='(.*)';/)[1]
enquiry_lists_page = agent.get(redirected_url)

enquiry_search_page = scraper.click_date_search_tab(enquiry_lists_page)
# The Date tab defaults to a search range of the last 30 days.
results_page = scraper.click_search_on_page(enquiry_search_page)

scraper.scrape_all_index_pages_with_gets(nil) do |record|
  EpathwayScraper.save(record)
end
