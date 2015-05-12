#!/usr/bin/env python

import os
import argparse
import fnmatch
import sys
import time
import shapefile as shp
import csv

# Readable directory function
def readable_dir(prospective_dir):
  if not os.path.isdir(prospective_dir):
    raise Exception("{0} is not a valid path".format(prospective_dir))
  if os.access(prospective_dir, os.R_OK):
    return prospective_dir
  else:
    raise Exception("{0} is not a readable dir".format(prospective_dir))

# Progress reporting
def progress(count, total, suffix=''):
    bar_len = 60
    filled_len = int(round(bar_len * count / float(total)))

    percents = round(100.0 * count / float(total), 1)
    bar = '=' * filled_len + '-' * (bar_len - filled_len)

    sys.stdout.write('[%s] %s%s ...%s\r' % (bar, percents, '%', suffix))
    sys.stdout.flush()

# Arguments for the script
parser = argparse.ArgumentParser(description='Parse CSV files to Shapefile')
parser.add_argument('-d', '--directory', help='Input directory to check')
parser.add_argument('-o', '--output', help='Output location', default='converted')
parser.add_argument('-r', '--recursive', action='store_true', help="Set to look for CSV files recursively")

args = parser.parse_args()

# Validate input directory
args.directory = readable_dir(os.path.abspath(args.directory) if args.directory is not None else os.getcwd())

# Collect all CSV files in question
csv_files = []

if args.recursive:
    for root, directories, filenames in os.walk(args.directory):
        for filename in fnmatch.filter(filenames, '*.csv'):
            csv_files.append(os.path.join(root, filename))
else:
    for item in fnmatch.filter(os.listdir(args.directory), '*.csv'):
        if os.path.isfile(os.path.join(args.directory, item)):
            csv_files.append(os.path.join(args.directory, item))

count = len(csv_files)

if count == 0:
    print "Found no CSV files, exiting"
    sys.exit(0)

print "Found " + str(count) + " CSV files"
print "Starting parsing into " + args.output

# Crime conversion table
crimes = {'Other crime': 'other-crime', 'Violent crime': 'violent-crime', 'Vehicle crime': 'vehicle-crime',
'Shoplifting': 'shoplifting', 'Robbery': 'robbery', 'Public disorder and weapons': 'public-disorder-weapons',
'Other theft': 'other-theft', 'Drugs': 'drugs', 'Criminal damage and arson': 'criminal-damage-arson',
'Burglary': 'burglary', 'Anti-social behaviour': 'anti-social-behaviour', 'All crime': 'all-crime'}

# Some sort of arbitrary weighting function for crimes (could even be per incident from source data)
weights = {'other-crime': 1, 'violent-crime': 4, 'vehicle-crime': 2, 'shoplifting': 1, 'robbery': 3, 'public-disorder-weapons': 3, 'other-theft': 2, 'drugs': 2, 'criminal-damage-arson': 3, 'burglary': 2, 'anti-social-behaviour': 1, 'all-crime': 1}

# Shape writer
w = shp.Writer(shp.POINT)
w.autobalance = 1

# Field names, from CSV structure of data.police.uk data
# Crime ID,Month,Reported by,Falls within,Longitude,Latitude,Location,LSOA code,LSOA name,Crime type,Last outcome category,Context
w.field('crime', 'C', 26)
w.field('jurisdiction', 'C', 35)
w.field('date', 'D')
w.field('weight', 'N')

for i, file in enumerate(csv_files):
    with open(file, 'rb') as csvfile:
        r = csv.reader(csvfile, delimiter=',')

        # Skip the first row (header)
        r.next()

        for _, row in enumerate(r):
            # Ignore rows with no location data
            if row[4] == '' or row[5] == '':
                continue

            w.point(float(row[4]), float(row[5]))

            # Attributes are done in a single swoop
            crime = (crimes[row[9]] if row[9] in crimes else 'all-crime')
            jurisdiction = row[3]
            date = ''.join(row[1].split('-')) + '01'
            weight = weights[crime]
            w.record(crime, jurisdiction, date, weight)

    progress(i + 1, count)

print "\nParsing done, saving files"

# Save the shapefile
w.save(args.output)

print "Conversion finished"
