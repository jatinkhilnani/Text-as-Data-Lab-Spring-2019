# TA: Pedro L. Rodríguez
# Course: Text as Data
# Date: 2/28/2019
# Lab adapted from: Kevin Munger, Patrick Chester and Leslie Huang.

#QUESTIONS FROM LAST LAB:
# BOOTSTRAPPING EXAMPLE: why replace?
# TTR: why the difference
# KNITR

#----------------------------------------
# 1 Set up environment                   ---
#----------------------------------------
# clear global environment
rm(list = ls())

# set path where our data is stored
setwd("~/Drobox/GitHub/Text-as-Data-Lab-Spring-2019/W5_02_28_19/")

# load required libraries
library(quanteda)
library(quanteda.corpora)
library(dplyr)

#----------------------------------------
# ASIDE - Bootstrapping (question from last class) ---
#----------------------------------------
# try setting replace = TRUE & replace = FALSE
# for bootstrapping we need to set replace = TRUE
sample_pop <- 1:5
sample_pop_size <- length(sample_pop)
lapply(1:5, function(x) sample(sample_pop, sample_pop_size, replace = TRUE))

#----------------------------------------
# 2 Load data: conservative manifestos ---
#----------------------------------------
# read in the files
filenames <- list.files(path = "conservative_manifestos", full.names=TRUE)
cons_manifestos <- lapply(filenames, readLines)
cons_manifestos <- unlist(lapply(cons_manifestos, function(x) paste(x, collapse = " "))) # because readLines returns a vector with each elements = lines

# get the date docvar from the filename
dates <- unlist(regmatches(unlist(filenames), gregexpr("[[:digit:]]+", unlist(filenames))))

# construct tibble (a tibble is an "enhanced" data.frame)
#?tibble
manifestos_df <- tibble(year = dates, text = cons_manifestos)

#----------------------------------------
# 3 Regular expressions                  ---
#----------------------------------------

# Examples
words <- c("Washington Post", "NYT", "Wall Street Journal", "Peer-2-Peer", "Red State", "Cheese", "222", ",")

# Exploring by character type
#?grep
grep("\\w", words, value = T)  # Elements that have alphanumeric characters
grep("\\w{7}", words, value = T)  # Elements that have words that are at least 7 characters long
grep("\\d", words, value = T)  # Elements that contain numbers
grep("\\W", words, value = T)  # Elements that contain nonword characters (Including white space)

# note that  grep returns the full element that matched the pattern

words2 <- c("voting", "votes", "devoted", "vote")

grep("^vot", words2) # Returns the index of matching items in the vector
grep("^vot", words2, value = T) # Returns the elements of the vector that matched the pattern
grepl("^vot", words2)  # Returns a logical vector indicating whether or not the component containes the expression

# you can use the indices to select elements from the original vector that you want
words2[grepl("^vot", words2)]

presidents <- c("Roosevelt-33", "Roosevelt-37", "Obama-2003")

# Use gsub to replace patterns with a string
gsub("(\\w+)-(\\d{2})", "\\1-19\\2", presidents) # Parentheses can identify components that can later be referenced by \\1 - \\2
gsub("(\\w+)-(\\d{2})$", "\\1-19\\2", presidents) # We want to use the $ to indicate that the pattern should come at the end of the word, to avoid the mismatch in Obama-192003

# Note that regex expressions in R are similar to those in other languages but there are some key differences

# Resources:
# other packages to work with regular expressions: stringr, stringi
# cheatsheet for regex: https://www.rstudio.com/wp-content/uploads/2016/09/RegExCheatsheet.pdf
# https://rstudio-pubs-static.s3.amazonaws.com/74603_76cd14d5983f47408fdf0b323550b846.html
# http://r4ds.had.co.nz/strings.html#matching-patterns-with-regular-expressions

#----------------------------------------
# 4 Selecting Features from DFM using Regular Expressions ---
#----------------------------------------

# Using simple texts

testText <- "The quick brown fox named Seamus jumps over the lazy dog also named Seamus, with the newspaper from a a boy named Seamus, in his mouth."

print(dfm(testText, select = "s$", valuetype = "regex")) # keep only words ending in "s"

testTweets <- c("2 + 2 = 4 #1984",
                "I thought you said the park? Why are we at the vet? #QuestionsFromPets",
                "Holy freeway #flooding Batman! #californiastorms taking their toll.")

print(dfm(testTweets, select="^#", valuetype = "regex"))  # keep only hashtags i.e. expressions starting with a pound sign

# Selecting features from a corpus

data("data_corpus_irishbudget2010")

irishbudgets_dfm <- dfm(data_corpus_irishbudget2010, select=c("tax|budg|^auster"), 
                        valuetype = "regex") # valuetype = "regex" ensures that the select input will be interpreted as a regular expression

# You can pass a list of words to the "select" parameter in dfm, but using regular expressions can enable you to get all variants of a word
View(irishbudgets_dfm)

#----------------------------------------
# 5 Dictionaries                         ---
#----------------------------------------
# Here, dictionary = list of words, not the data structure.
# Python users: there is no dictionary object in R :( :( :( (Note: you can create dictionary-like objects using lists)

mytexts <- c("The new law included a capital gains tax, and an inheritance tax.",
             "New York City has raised a taxes: an income tax and a sales tax.")

mydict <- c("tax", "income", "capital", "gains", "inheritance")

print(dfm(mytexts, select = mydict))

# Example: Laver Garry dictionary
# https://rdrr.io/github/kbenoit/quanteda.dictionaries/man/data_dictionary_LaverGarry.html
# https://provalisresearch.com/products/content-analysis-software/wordstat-dictionary/laver-garry-dictionary-of-policy-position/
lgdict <- dictionary(file = "LaverGarry.cat", format = "wordstat")

# What's in this thing?
lgdict

# Run the conservative manifestos through this dictionary
manifestos_lg <- dfm(manifestos_df$text, dictionary = lgdict)

# how does this look
as.matrix(manifestos_lg)[1:5, 1:5]
featnames(manifestos_lg)

# plot it
plot(manifestos_df$year, 
     manifestos_lg[,"CULTURE.SPORT"],
     xlab="Year", ylab="SPORTS", type="b", pch=19)

plot(manifestos_df$year, 
     manifestos_lg[,"VALUES.CONSERVATIVE"],
     xlab="Year", ylab="Conservative values", type="b", pch=19)

plot(manifestos_df$year, 
     manifestos_lg[,"INSTITUTIONS.CONSERVATIVE"] - manifestos_lg[,"INSTITUTIONS.RADICAL"],
     xlab="Year", ylab="Net Conservative Institutions", type="b", pch=19)

# RID Dictionary--Regressive Imagery Dictionary
# https://www.kovcomp.co.uk/wordstat/RID.html
rid_dict <- dictionary(file = "RID.cat", format = "wordstat")

data("data_corpus_sotu")

sotus_texts <- texts(data_corpus_sotu)

# Get the docvars from the corpus object
year <- (data_corpus_sotu$documents$Date)
pres <- (data_corpus_sotu$documents$President)

sotu_rid_dfm <- dfm(data_corpus_sotu, dictionary = rid_dict)

# Look at the categories
featnames(sotu_rid_dfm)

# Inspect the results graphically
plot(year, 
     sotu_rid_dfm[,"PRIMARY.REGR_KNOL.NARCISSISM"],
     xlab="Year", ylab="Narcissism", type="b", pch=19)

plot(year, 
     sotu_rid_dfm[,"PRIMARY.ICARIAN_IM.FIRE"] + sotu_rid_dfm[,"PRIMARY.ICARIAN_IM.ASCEND"] +sotu_rid_dfm[,"PRIMARY.ICARIAN_IM.DESCENT"] +
       sotu_rid_dfm[,"PRIMARY.ICARIAN_IM.DEPTH"] + sotu_rid_dfm[,"PRIMARY.ICARIAN_IM.HEIGHT"] + sotu_rid_dfm[,"PRIMARY.ICARIAN_IM.WATER"],
     xlab="Year", ylab="Icarian-ness", type="b", pch=19)

