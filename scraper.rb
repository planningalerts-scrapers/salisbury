require "epathway_scraper"

EpathwayScraper.scrape_and_save(
  "https://eservices.salisbury.sa.gov.au/ePathway/Production",
  list_type: :last_30_days
)
