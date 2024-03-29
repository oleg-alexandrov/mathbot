#!/usr/bin/python

"""
A set of Python utilities which read some instructions from disk,
talk to Wikipedia via pywikibot, then write their outputs back to
disk. These are used by Perl bots.

See documentation at: 
https://wikitech.wikimedia.org/wiki/User:Russell_Blau/Using_pywikibot_on_Labs

Use python3 instead of python when following that page.

python3 /shared/pywikibot/core/pywikibot/scripts/generate_user_files.py

Default user directory is /data/project/mathbot

See the file /data/project/mathbot/user-config.py. It points to the
passwords, saved in

/data/project/mathbot/passwords.txt

Do:

chmod 600 /data/project/mathbot/passwords.txt

Set these two vars before running the tool:

export PYTHONPATH=/shared/pywikibot/core:/shared/pywikibot/core/externals/httplib2:/shared/pywikibot/core/scripts:$PYTHONPATH
export PYWIKIBOT_DIR=/data/project/mathbot

Do this to ensure python can print in a terminal:

export PYTHONIOENCODING=utf8

Thse are set in perlwikipedia_utils.pl, before running pywikibot from the perl bot.

Before using this tool, login with:

python3 /shared/pywikibot/core/pywikibot/scripts/login.py 

Do not use the BotPassword option, it does not work.

"""

import sys, os, re, time
import pywikibot

def fetch_articles_and_cats(site, category_name):
  
  """
  Fetch the articles and subcategories in given category.
  """

  # Wipe the initial "Category:"
  m = re.match("^Category:(.*?)$", category_name, re.IGNORECASE)
  if m:
    category_name = m.group(1)
  
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

def fetch_articles_in_cats(site, input_cats):
  """
  Fetch articles and identify new categories in given list of input categories.
  """
  
  input_cats_set = set()
  for input_cat in input_cats:
    input_cats_set.add(input_cat)

  new_articles = []
  new_cats = []
  new_cats_set = set()
  new_articles_set = set()
  
  # Look in all input categories
  for input_cat in input_cats:

    (local_articles, local_cats) = fetch_articles_and_cats(site, input_cat)

    for local_cat in local_cats:
      if local_cat in input_cats_set or local_cat in new_cats_set:
        continue
      
      new_cats_set.add(local_cat)
      new_cats.append(local_cat)
    
    for local_article in local_articles:

      m = re.match("^.*?:", local_article)
      if m:
        # Ignore any aritcle having a column. It is likely a portal.
        # TODO(oalexan1): This is not good logic.
        continue 

      if local_article in new_articles_set:
        continue

      new_articles_set.add(local_article)
      new_articles.append(local_article)

  new_articles.sort()
  new_cats.sort()

  return (new_articles, new_cats)

def write_articles_and_cats(file_name, articles, cats):
  
  with open(file_name, encoding='utf-8', mode = "w") as f:
    
    f.write("articles:\n")
    for article in articles:
      f.write("  " + article + "\n")
      
    f.write("subcategories:\n")
    for cat in cats:
      f.write("  " + cat + "\n")

# Main program

if len(sys.argv) < 2:
  print("The job task must be specified.\n")
  sys.exit(1)

site      = pywikibot.Site()
job_name  = sys.argv[1]

# Parse the job. There are two kinds of text. One is "name: val". The second is
# "name:" followed by many lines having value for that name, with each line
# starting with spaces.
multi_dict = {}
multi_key = ""

with open(job_name, encoding='utf-8', mode = "r") as f:

  for line in f:

    m = re.match("^article name: (.*?)\n", line)
    if m:
      article_name = m.group(1)
      continue
    
    m = re.match("^file name: (.*?)\n", line)
    if m:
      file_name = m.group(1)
      continue

    m = re.match("^task: (.*?)\n", line)
    if m:
      task = m.group(1)
      continue

    m = re.match("^category name: (.*?)\n", line)
    if m:
      category_name = m.group(1)
      continue

    m = re.match("^edit summary: (.*?)\n", line)
    if m:
      edit_sum = m.group(1)
      continue

    # A key followed by many values on subsequent lines
    m = re.match("^([^\s].*?):\n", line)
    if m:
      multi_key = m.group(1)
      multi_dict[multi_key] = []
      continue

    m = re.match("^\s+([^\s].*?)\n", line)
    if m:
      val = m.group(1)
      
      if multi_key == "" or (multi_key not in multi_dict):
        print("Error: found an invalid key.")
        sys.exit(1)
        
      multi_dict[multi_key].append(val)
      continue

if task == "fetch":
  
  # Fetch existing text
  page = pywikibot.Page(site, article_name)
  
  # Save the result to disk
  with open(file_name, encoding='utf-8', mode = "w") as f:
    f.write(page.text)

elif task == "fetch_many":
  # Fetch many articles at once

  if 'article_names' not in multi_dict:
    print("Not given articles to fetch.")
    sys.exit(1) 

  if 'article_files' not in multi_dict:
    print("Not given files to which to write the fetched articles.")
    sys.exit(1)

  article_names = multi_dict['article_names']
  article_files = multi_dict['article_files']

  if len(article_names) != len(article_files):
    print("Need to have as many article files as article names.")
    sys.exit(1)

  for count in range(len(article_names)):
    # Fetch existing text
    page = pywikibot.Page(site, article_names[count])
    time.sleep(1) # to not hog the server
    
    # Save the result to disk
    with open(article_files[count], encoding='utf-8', mode = "w") as f:
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
  write_articles_and_cats(file_name, articles, cats)
  
elif task == "list_cats":
  
  if 'categories' not in multi_dict:
    print("Not given categories to list.")
    sys.exit(1) 

  input_cats = multi_dict['categories']

  (new_articles, new_cats) = fetch_articles_in_cats(site, input_cats)
  write_articles_and_cats(file_name, new_articles, new_cats)

else:
  print("Unknown task: ", task)
  sys.exit(1)

# Return success
sys.exit(0)

