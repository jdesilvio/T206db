import requests
import lxml.html
import re
import time
from mechanize import Browser
from bs4 import BeautifulSoup

BASE_URL = "http://www.beckett.com/grading/set_match/3518008"
ua = 'Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/537.17 (KHTML, like Gecko) Chrome/24.0.1312.57 Safari/537.17'

def login(url):
    # Use mechanize to get the set name URLs to scrape
    br = Browser()
    br.addheaders = [('User-Agent', ua)]
    br.open(url)

    # Select the form
    for form in br.forms():
        if form.attrs['id'] == 'loginFrm':
            br.form = form
            break

    br["email"] = EMAIL # replace with email
    br["password"] = PASSWORD # replace with password

    # Submit the form
    br.submit()

    for form in br.forms():
        if form.attrs['id'] == 'pop_report_form':
            br.form = form
            break

    br['sport_id'] = ['185223']
    br['set_name'] = "T206"
    br.submit(name="search")

    # Follow link to the correct set
    br.follow_link(url="http://www.beckett.com/grading/set_match/3518008")

    return br.response().read()

# Method #1: Handoff HTML to BS4
#soup = BeautifulSoup(login(BASE_URL))
#table = soup.find('table', id="tableshorgrid")
#tds = table.find_all('td')
#for td in tds:
#    print td.text

# Method #2: Handoff HTML to lxml
doc = lxml.html.fromstring(login(BASE_URL))
print doc.xpath('//td/text()')
