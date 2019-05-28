require "epathway_scraper"

EpathwayScraper::Scraper.scrape_and_save(
  "https://eservices.salisbury.sa.gov.au/ePathway/Production",
  list_type: :last_30_days, with_gets: true
)
