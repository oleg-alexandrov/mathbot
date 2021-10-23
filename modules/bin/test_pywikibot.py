#!/usr/bin/python

"""
A little tool to test pywikibot

Set these two vars before running the tool

export PYTHONPATH=/data/project/shared/pywikibot/stable:/data/project/shared/pywikibot/stable/scripts
export PYWIKIBOT_DIR=/data/project/mathbot

Before using this tool, login with

python3 /data/project/shared/pywikibot/stable/scripts/login.py

Do not use the BotPassword option, it does not work.

"""

import sys, os, re
import pywikibot

site  = pywikibot.Site()
category_name = "Mathematics"

supercat = pywikibot.Category(site, category_name)
articles  = set(supercat.articles(recurse=False))

print("articles ", articles)
for article in articles:
  print ("name is " + article.title())


# Categories having this cateogry
#supercats  = set(supercat.categories())
#print("supercats ", supercats)

# Categories in this category
subcats  = set(supercat.subcategories())
for subcat in subcats:
  print("cat name is " + subcat.title())

print("subcats ", subcats)


