#!/usr/bin/env python

from __future__ import print_function

import argparse
from BeautifulSoup import BeautifulSoup
import sys
import urllib2

DEFAULT_URL = "http://localhost:8080"

parser = argparse.ArgumentParser()
parser.add_argument("url",
                    nargs='?',
                    default=DEFAULT_URL,
                    help="The root url of the vm to check (default: {0})".format(DEFAULT_URL))
args = parser.parse_args()

html_page = urllib2.urlopen(args.url)
soup = BeautifulSoup(html_page)

for link in soup.findAll('a'):
    desc = link.contents[0]
    href = link.get('href')
    print("Checking {0}...".format(desc), end=' ')
    sys.stdout.flush()
    try:
        urllib2.urlopen(args.url + href)
    except Exception as e:
        print(e)
    else:
        print("PASS")
