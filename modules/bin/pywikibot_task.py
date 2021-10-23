#!/usr/bin/python

"""
A set of Python utilities which read some instructions from disk,
talk to Wikipedia via pywikibot, then write their outputs back to
disk. These are used by Perl bots.

Set these two vars before running the tool:

export PYTHONPATH=/data/project/shared/pywikibot/stable:/data/project/shared/pywikibot/stable/scripts
export PYWIKIBOT_DIR=/data/project/mathbot

Do this to ensure can printto a terminal:

export PYTHONIOENCODING=utf8

Before using this tool, login with:

python3 /data/project/shared/pywikibot/stable/scripts/login.py

Do not use the BotPassword option, it does not work.

"""

import sys, os, re
import pywikibot

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
  # fetch existing text
  page = pywikibot.Page(site, article_name) 
  # Save the result to disk
  with open(file_name, encoding='utf-8', mode = "w") as f:
    f.write(page.text)

elif task == "submit":
  # fetch existing text
  page = pywikibot.Page(site, article_name) 
  # Overwite the text with what is stored locally on disk
  with open(file_name, encoding='utf-8', mode = "r") as f:
    page.text = f.read()

    # submit
    page.save(edit_sum)

elif task == "articles_in_cat":
  vals = set(pywikibot.Category(site, category_name).articles(recurse=False))
  
else:
  print("Unknown task: ", task)
  sys.exit(1)

# Return success
sys.exit(0)

