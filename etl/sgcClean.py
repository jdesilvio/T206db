import csv
import json
from operator import itemgetter
import re

with open('output.txt', 'rb') as tsv_file:
    tsv_reader = csv.DictReader(tsv_file, delimiter='\t')
    for row in tsv_reader:
        data = [row for row in tsv_reader]

# Remove duplicate header columns
data = [d for d in data if d['Set Name'] != "Totals"]
data = [d for d in data if d['Set Name'] != "Set Name"]

# Remove T205 cards
data = [d for d in data if d['Card #'] != "T205"]

# Split `Set Name` into `Year` and `Brand`
for d in data:
    d['Year'] = d['Set Name'].split(" ")[0]
    d['Brand'] = " ".join([i for i in d['Set Name'].split(" ")[1:] if i != ""])

# Remove `Card #` since it is irrelevant at this point
data = [{key: value for key, value in i.items() if key != "Card #"} for i in data]

#print json.dumps(data[11], indent=2)

setNames = list(set([d['Set Name'] for d in data]))
descs = list(set([d['Description'] for d in data]))
players = list(set([d['Player'] for d in data]))
years = list(set([d['Year'] for d in data]))
brands = list(set([d['Brand'] for d in data]))

x = [i['Player'] + " - " + i['Description'] for i in data]
for i in sorted(list(set(x))):
    print i
print len(sorted(list(set(x))))
