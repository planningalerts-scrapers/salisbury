require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

def extract_from_p(contents, name)
	contents.at('p:contains("'+name+'")').inner_text.split(name).last.strip
end

def scrape_page(page)
	contents = page.search('div.span6')
	record = {
		"info_url" => page.uri.to_s,
		"council_reference" => contents.search('h1').inner_text,
		"comment_url" => page.uri.to_s,
		"applicatant" => extract_from_p(contents,"Applicant:"),
		"description" => contents.at('p:contains("Location:")').next_element.inner_text,
		"address" => extract_from_p(contents,"Location:"),
		"date_scraped" => Date.today.to_s,
		"date_closing" => extract_from_p(contents,"Advertising closes ")
	}

	if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
		ScraperWiki.save_sqlite(['council_reference'], record)
	else
		puts "Skipping already saved record " + record['council_reference']
	end
end


# Load summary page.
url = "http://www.salisbury.sa.gov.au/Build/Planning_Building_and_Forms/Advertised_Development_Applications"
page = agent.get(url)

#get links to new developments

apps_links = []

links = page.search('a')
links.each do |link|
	href = link['href']

	if (href and href.start_with?("http://www.salisbury.sa.gov.au/Build/Planning_Building_and_Forms/Advertised_Development_Applications/") )
		apps_links << href
	end
end

apps_links.each_with_index do |app_url,index|
	puts "Scraping application #{index} of #{apps_links.length} ..."
	app = agent.get(app_url)
	scrape_page(app);
end



