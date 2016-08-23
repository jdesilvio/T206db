import requests
import lxml.html
from lxml import html
import re
import sys
import urlparse
import time

### ~ CONSTANTS ~ ###
baseURL = "http://www.loc.gov/pictures/search/?q=t206&sp="
startURL = "http://www.loc.gov/pictures/search/?q=t206&co=bbc"
URLsuffix = "&co=bbc"

### ~ FUNCTIONS ~ ###

# Function to create a list of pages to scrape
def getCardResults():
	cardResultURLs = []
	for i in range(1, 27):
		cardResultURLs.append(baseURL + str(i) + URLsuffix)
	return cardResultURLs

# Function to get URL for each card
def getCardURLs(URL):
	doc = lxml.html.fromstring(requests.get(URL).text)
        cardPaths = [ link for link in doc.xpath('//div[@class="result_item"]//p/a/@href') ]
	cardURLs = []
	for cardPath in cardPaths:
		cardURLs.append("http:" + cardPath)
	return cardURLs

# Function to get URL for each card image
def getImgURLs(URL):
	doc = lxml.html.fromstring(requests.get(URL).text)
	try:
		frontPath = doc.xpath('//*[@id="item"]/p[2]/a[4]/@href')
	except:
		pass
	try:
		backPath = doc.xpath('//*[@id="item"]/p[4]/a[4]/@href')
	except:
		pass
	if frontPath and backPath:
		imgURLs = ["http:" + frontPath[0], "http:" + backPath[0]]
	else:
		if frontPath:
			imgURLs = ["http:" + frontPath[0]]
		else:
			imgURLs = ["http:" + backPath[0]]
	return imgURLs

# Get title for each image file
def imgTitle(URL):
	doc = lxml.html.fromstring(requests.get(URL).text)

	# Get card title
	title = doc.xpath('//h2[@id="title"]/text()')
	title = title[0].replace(", ", "_")
	title = title.replace(" ", "-")
	title = title.replace("/", "-")
	return title

# Functions to download images from URL
def getImages(URL):

	# Get card title
	title = imgTitle(URL)
	print title

	# Get image URLs
	imgURLs = getImgURLs(URL)

	# Save images
	for imgURL in imgURLs:
		r = requests.get(imgURL)
		f = open('imgDir/%s_%s' % (title, imgURL.split('/')[-1]), 'w')
		f.write(r.content)
		f.close()

### ~ MAIN ~ ###

if __name__ == "__main__":
	results = getCardResults()

	cardURLs = []
	for result in results:
		time.sleep(5)
		URLs = getCardURLs(result)
		for URL in URLs:
			cardURLs.append(URL)

	count = 0
	for cardURL in cardURLs:
		time.sleep(5)
		getImages(cardURL)
		print count
		count += 1
