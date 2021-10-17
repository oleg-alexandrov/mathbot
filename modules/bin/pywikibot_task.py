#!/usr/bin/python

# Read text from a given file and submit it to Wikipedia overwriting a given article.

# Set these two vars before running the tool
# export PYTHONPATH=/data/project/shared/pywikibot/stable:/data/project/shared/pywikibot/stable/scripts
# export PYWIKIBOT_DIR=/data/project/mathbot

# Before using this tool, login with
# python3 /data/project/shared/pywikibot/stable/scripts/login.py
# Do not use the BotPassword option, it does not work.

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
    m = re.match("edit summary: (.*?)\n", line)
    if m:
      edit_sum = m.group(1)

# First fetch the existing text
page = pywikibot.Page(site, article_name)

if task == "fetch":
  # Save the result to disk
  with open(file_name, encoding='utf-8', mode = "w") as f:
    f.write(page.text)

elif task == "submit":
  # Overwite the text with what is stored locally on disk
  with open(file_name, encoding='utf-8', mode = "r") as f:
    page.text = f.read()

    # submit
    page.save(edit_sum)

else:
  print("Unknown task: ", task)
  sys.exit(1)

# Return success
sys.exit(0)

