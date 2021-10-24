#!/usr/bin/python

"""
A set of Python utilities which read some instructions from disk,
talk to Wikipedia via pywikibot, then write their outputs back to
disk. These are used by Perl bots.

Set these two vars before running the tool:

export PYTHONPATH=/data/project/shared/pywikibot/stable:/data/project/shared/pywikibot/stable/scripts
export PYWIKIBOT_DIR=/data/project/mathbot

Do this to ensure python can print in a terminal:

export PYTHONIOENCODING=utf8

Before using this tool, login with:

python3 /data/project/shared/pywikibot/stable/scripts/login.py

Do not use the BotPassword option, it does not work.

"""

import sys, os, re
import pywikibot

def fetch_articles_and_cats(site, category_name):
  
  """
  Fetch the articles and subcategories in given category.
  """
  # Initialize the category object
  cat = pywikibot.Category(site, category_name)

  # Articles in this cateogry
  articles_set  = set(cat.articles(recurse=False))
  
  # Categories in this category
  cats_set  = set(cat.subcategories())

  articles = []
  cats = []
  
  for article in articles_set:
    articles.append(article.title())

  for subcat in cats_set:
      cats.append(subcat.title())

  articles.sort()
  cats.sort()

  return (articles, cats)

# Main program

if len(sys.argv) < 2:
  print("The job task must be specified.\n")
  sys.exit(1)

site      = pywikibot.Site()
job_name  = sys.argv[1]

# Parse the job
with open(job_name, encoding='utf-8', mode = "r") as f:
  for line in f:
    m = re.match("article name: (.*?)\n", line)
    if m:
      article_name = m.group(1)
    m = re.match("file name: (.*?)\n", line)
    if m:
      file_name = m.group(1)
    m = re.match("task: (.*?)\n", line)
    if m:
      task = m.group(1)
    m = re.match("category name: (.*?)\n", line)
    if m:
      category_name = m.group(1)
    m = re.match("edit summary: (.*?)\n", line)
    if m:
      edit_sum = m.group(1)

if task == "fetch":
  
  # Fetch existing text
  page = pywikibot.Page(site, article_name)
  
  # Save the result to disk
  with open(file_name, encoding='utf-8', mode = "w") as f:
    f.write(page.text)

elif task == "submit":
  
  # Fetch existing text
  page = pywikibot.Page(site, article_name)
  
  # Overwite the text with what is stored locally on disk
  with open(file_name, encoding='utf-8', mode = "r") as f:
    page.text = f.read()

    # Submit to Wikipedia
    page.save(edit_sum)

elif task == "list_cat":

  # Fetch the articles and subcategories in given category. Save them
  # to disk in a json-like format.

  (articles, cats) = fetch_articles_and_cats(site, category_name)

  with open(file_name, encoding='utf-8', mode = "w") as f:
    
    f.write("articles:\n")
    for article in articles:
      f.write("  " + article + "\n")
      
    f.write("subcategories:\n")
    for cat in cats:
      f.write("  " + cat + "\n")
  
else:
  print("Unknown task: ", task)
  sys.exit(1)

# Return success
sys.exit(0)

