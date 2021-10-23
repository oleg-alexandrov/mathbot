#!/usr/bin/python

"""
A little tool to test pywikibot

Set these two vars before running the tool

export PYTHONPATH=/data/project/shared/pywikibot/stable:/data/project/shared/pywikibot/stable/scripts
export PYWIKIBOT_DIR=/data/project/mathbot

Do this to ensure can printto a terminal:

export PYTHONIOENCODING=utf8

Before using this tool, login with

python3 /data/project/shared/pywikibot/stable/scripts/login.py

Do not use the BotPassword option, it does not work.

"""

import sys, os, re
import pywikibot

site  = pywikibot.Site()
category_name = sys.argv[1]
file_name = sys.argv[2]

print("fetch cat ", category_name)

cat = pywikibot.Category(site, category_name)

# Articles in this cateogry
articles  = set(cat.articles(recurse=False))

# Categories in this category
subcats  = set(cat.subcategories())

print("Save to: ", file_name)

with open(file_name, encoding='utf-8', mode = "w") as f:
  f.write("articles:\n")
  for article in articles:
    f.write("  " + article.title() + "\n")
    
  f.write("subcategories:\n")
  for subcat in subcats:
    f.write("  " + subcat.title() + "\n")

