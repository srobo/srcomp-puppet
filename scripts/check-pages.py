#!/usr/bin/env python3

import argparse
import sys

import urllib.request
from bs4 import BeautifulSoup

DEFAULT_URL = 'http://localhost:8080'
FAIL = '\033[91m'
ENDC = '\033[0m'

parser = argparse.ArgumentParser()
parser.add_argument(
    'url',
    nargs='?',
    default=DEFAULT_URL,
    help="The root url of the vm to check (default: %(default)s)",
)
args = parser.parse_args()

try:
    html_page = urllib.request.urlopen(args.url)
except Exception as e:
    print(FAIL, "Failed to load index page:", e, ENDC)
    exit(1)

soup = BeautifulSoup(html_page, 'html.parser')

fail_count = 0
for link in soup.findAll('a'):
    desc = link.contents[0]
    href = link.get('href')
    print("Checking {0}...".format(desc), end=' ')
    sys.stdout.flush()
    try:
        urllib.request.urlopen(args.url + href)
    except Exception as e:
        print(FAIL, e, ENDC)
        fail_count += 1
    else:
        print("PASS")

print("You should also check that the pages can be seen from another machine!")

exit(fail_count)
