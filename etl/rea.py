##########################################
### ~ SCRAPE ROBERT EDWARDS AUCTIONS ~ ###
##########################################

''' Get auction results for Robert Edwards Auctions http://www.robertedwardauctions.com '''

import requests
from bs4 import BeautifulSoup
import csv
from time import strftime, strptime
import datetime
import time
import lxml.html
import re
import json

# Function to get results specifically for the Spring 2015 auction
# This should be refactored to be more generic and get any auction
def getAuctionResults():

	# The specific URL to the auction
	url = 'http://www.robertedwardauctions.com/auction/2015_spring/index.html'
	
	# Send request for URL
	r = requests.get(url).text
	doc = lxml.html.fromstring(r)

	# Get the name of the auction
	auction = doc.xpath('//div[@class="padded"]/h1/text()')

	# Get all items and item details of the auction
	auctionItems = []
	for i in doc.xpath('//div[@id="auction_table"]/table/tbody/tr'):
		itemDetails = {}
		itemDetails['lot']   = i.xpath('./td[1]/text()')[0]
		itemDetails['des']   = i.xpath('./td[2]/a/text()')[0]
		itemDetails['url']   = i.xpath('./td[2]/a/@href')[0]
		itemDetails['bids']  = i.xpath('./td[3]/text()')[0]
		itemDetails['open']  = i.xpath('./td[4]/text()')[0]
		itemDetails['close'] = i.xpath('./td[5]/text()')[0]
		auctionItems.append(itemDetails)
	
	# Turn results into JSON format
	auctionResults = {"auctionName": auction[0], "auctionURL": url, "results": auctionItems}
	auctionResults = json.dumps(auctionResults, indent=2)

	# Export reults to .json
	with(open("auctionResults.json", "w")) as f:
		f.write(auctionResults)

################
### ~ MAIN ~ ###
################

if __name__ == "__main__":
    getAuctionResults()
