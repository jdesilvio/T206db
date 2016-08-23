library(jsonlite)
library(stringi)
library(plyr)
library(ggplot2)

# functions

# regex function to get grades
getAttribute = function(x, phrase) { sub(paste('^.*(', phrase, '[^0-9]*[0-9.]+).*', sep=''), '\\1', x) }

# function to assign grades correctly
assignAttribute = function(x, phrase) {
  if (grepl(phrase, x)==T) {
    if (nchar(getAttribute(x, phrase)) <= 20) {
      getAttribute(x, phrase)
    } else {
      "NA"
    }
  } else {
    "NA"
  }
}

# function that assigns grades
grades = function (x) {
  if (grepl("PSA", x)==T) {
    assignAttribute(x, phrase="PSA")
  } else if (grepl("SGC", x)==T) {
    assignAttribute(x, phrase="SGC")
  } else {
    "NA"
  }
}

# import json
rea = fromJSON(txt='./auctionResults.json')
x = as.data.frame(rea[3])

# filter for all T206's
x$isT206 = grepl("T206", x$results.des)
t206 = subset(x, isT206==T)

# assign grades
t206$grade = unlist(lapply(list(t206$results.des)[[1]], function(x) grades(x)))

t206$results.close = as.numeric(unlist(lapply(list(t206$results.close)[[1]], function(x) gsub('[,$]', '', x))))
t206$results.open = as.numeric(unlist(lapply(list(t206$results.open)[[1]], function(x) gsub('[,$]', '', x))))

df = subset(t206, grade != "NA" & results.close < 10000)
ggplot(df, aes(x=as.factor(grade), y=results.close)) + geom_point()

# assign player names
player = read.csv('./cards.csv')
players = unlist(list(player$full_name))

for(i in players) {
  cat(i)
}
p = "Ty Cobb"
lapply(list(t206$results.des)[[1]], function(x) grepl(p, x))
