import requests
import lxml.html
import re
import time
from mechanize import Browser

BASE_URL = "http://www.sgccard.com/PopulationReport.aspx/"

def getSetURLs(url):
    # Use mechanize to get the set name URLs to scrape
    br = Browser()
    br.open(url)

    # Select the form
    br.select_form(name="aspnetForm")

    # Set the 'sport' to "Baseball"
    br["ctl00$FEContentPlaceHolder$SportDDL"] = ['2']

    # Set the 'set name' to "T206"
    br["ctl00$FEContentPlaceHolder$SetNameTB"] = "T206"

    # Submit the form
    br.submit()

    # From the response, get all links that appply
    URLs = []
    for link in br.links():
        # We only want links that include "T206"
        if "T206" in link.text:
            # But not if they include "Reprint" or "eTopps"
            if "Reprint" in link.text or "eTopps" in link.text:
                pass
            else:
                URLs.append("http://www.sgccard.com/" + link.url)
    return URLs

def getPop(url):
    # Send request to URL and convert HTML
    r = requests.get(url).text
    doc = lxml.html.fromstring(r)

    rows = doc.xpath('//table[@class="populationreportresulttable"]/tr')

    result = []
    for row in rows:
        rowResult = []
        for td in row.xpath('./td'):
            val = td.xpath('./text()')
            try:
                rowResult.append(val[0])
            except:
                rowResult.append("NULL")
        result.append("\t".join(rowResult))
    return result

def getAllPops(urls):
    results = []
    for url in urls:
        for result in getPop(url):
            results.append(result)
    return results

def scrapeSGC():
    results = getAllPops(getSetURLs(BASE_URL))
    with(open("output.txt", "w")) as f:
        f.write("\n".join(results))

if __name__ == "__main__":
    scrapeSGC()
