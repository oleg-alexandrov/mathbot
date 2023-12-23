# Run a job
toolforge jobs run afd --command "$(pwd)/afd.sh $(pwd)"  \
  --image tool-pywikibot/pywikibot-scripts-stable:latest \
  -o $(pwd)/afd.out -e $(pwd)/afd.err

toolforge jobs run afd --command "$(pwd)/afd.sh $(pwd)"  \
  --image tool-pywikibot/pywikibot-scripts-stable:latest \
  -o $(pwd)/afd.out -e $(pwd)/afd.err

# List jobs
toolforge jobs list

$ENV{'PYTHONPATH'} = '/shared/pywikibot/core:/shared/pywikibot/core/externals/httplib2:/shared/pywikibot/core/scripts';
$ENV{'PYWIKIBOT_DIR'} = '/data/project/mathbot';

$ENV{'PYTHONIOENCODING'} = 'utf8'; # to make Python print unicode on screen

export PYTHONPATH=/shared/pywikibot/core:/shared/pywikibot/core/externals/httplib2:/shared/pywikibot/core/scripts
export PYWIKIBOT_DIR=/data/project/mathbot
export PYTHONIOENCODING=utf8

toolforge jobs run --image tool-pywikibot/pywikibot-scripts-stable:latest \
  --command "$(pwd)/afd.sh $(pwd)" afd2

# Follow instructions at
# https://wikitech.wikimedia.org/wiki/Help:Toolforge/Running_Pywikibot_scripts_(advanced)

# Run it hourly
toolforge jobs run afd --command "$HOME/public_html/wp/afd/afd.sh" --image python3.11 \
  --schedule "@hourly"

toolforge jobs list
