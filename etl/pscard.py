import requests
import lxml.html
import re
import time

BASE_URL    = "http://www.psacard.com/Pop/T206"
PLAYER_INFO = "http://www.psacard.com/Pop/T206/GetT206PartialBySubject?firstName=%s&lastName=%s&variety=%s&isPSADNA=%s"

def parse_table_row(tr, aggregate=False):
    """
    """
    # get all available texts from a row, 
    # some are in divs so there're two calls 
    name = " ".join(tr.xpath("./td/text()")).strip()
    vals = " ".join(tr.xpath("./td/div/text()"))

    ln = (name + vals).strip()

    # split line just before 'Grade' word
    # head could be player name or data_variety
    # depends on row (is it from ajax call or not)
    head, rest = re.split(r".(?=Grade)", ln)
    
    if aggregate:
        head = "aggregate values"

    rest = rest.split(" ")
        
    grade  = " ".join(rest[0:3])
    auth   = " ".join(rest[3:6])
    pr     = " ".join(rest[6:9])
    fr     = " ".join(rest[9:12])
    good   = " ".join(rest[12:15])
    vg     = " ".join(rest[15:18])
    vg_ex  = " ".join(rest[18:21])
    ex     = " ".join(rest[21:24])
    ex_mt  = " ".join(rest[24:27])
    nm     = " ".join(rest[27:30])
    nm_mt  = " ".join(rest[30:33])
    mint   = " ".join(rest[33:36])
    gem_mt = " ".join(rest[36:39])
    total  = " ".join(rest[39:42])
        
    return "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s" % (
        head, grade, auth, pr, fr, good, vg, vg_ex, 
        ex, ex_mt, nm, nm_mt, mint, gem_mt, total
    )


def get_player_data_per_brand(firstname, lastname, data_variety, psadna):
    """
    Makes 'AJAX call'. 

    If player is Ty Cobb, data-variety portrait-green and ispsadna true, 
    site will make ajax call to this address: 

    http://www.psacard.com/Pop/T206/GetT206PartialBySubject?firstName=TY&lastName=COBB&variety=PORTRAIT-GREEN&isPSADNA=True
    
    As you can see, it's just an html which will be inserted into the DOM.
    We will just parse it here and write to a file later.
    """
    url = PLAYER_INFO % (firstname, lastname, data_variety, psadna)
    r = requests.get(url).text
    doc = lxml.html.fromstring(r)
    
    variety = data_variety or "NULL"
    return [ "%s\t%s\t%s\t%s" % ( firstname, lastname, variety, parse_table_row(tr) ) for tr in doc.xpath("//tr") ]


def get_players():
    """
    Visit http://www.psacard.com/Pop/T206 and scrape all basic data from html:
      - player first name
      - player last name
      - data_variety field

    Players are split in two tables (kinds of table to be more precise,
    since there's table per player if you check the html): 
      - one where data-ispsadna attrubute set to false
      - other where it's true
    """

    result = []

    doc = lxml.html.fromstring(requests.get(BASE_URL).text)
    
    players = [ (p, False) for p in doc.xpath('//table[@data-ispsadna="False"]/thead/tr') ] +\
              [ (p, True ) for p in doc.xpath('//table[@data-ispsadna="True"]/thead/tr')  ]

    for player, psadna in players:
        firstname  = player.get("data-firstname")
        lastname   = player.get("data-lastname")
        data_variety = player.get("data-variety")
        
        if [ firstname, lastname, data_variety ] != [ None, None, None ]:

            variety = data_variety or "NULL" # can be empty string

            print "Scraping data for: %s %s, %s" % (firstname, lastname, variety)

            # scrape aggregate data, player stats you can see on the page without clicking
            result.append( "%s\t%s\t%s\t%s" % ( firstname, lastname, variety, parse_table_row(player, True) ) )

            try:
                result += get_player_data_per_brand(firstname, lastname, data_variety, psadna)
                time.sleep(5) # just to be a good web citizens :)
            except:
                # when name is clickable but there's no data
                # For examples check the last big tabel it starts with Beck Fred, Bender Chief...
                # we scrape only aggregate values in that case
                pass

    with(open("output.csv", "w")) as f:
        f.write("\n".join(result))
        

if __name__ == "__main__":
    get_players()
