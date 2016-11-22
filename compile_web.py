#!/usr/bin/env python

from jinja2 import Environment, FileSystemLoader
import pymongo
import sys
import os

client = pymongo.MongoClient(os.environ["repomeister_db_host"], int(os.environ["repomeister_db_port"]))
db_name = os.environ["repomeister_db_name"]
db = client[db_name]

saveToDir = "dist/";

def round_up_severely(number):
    last_two_digits = int(str(number)[2:])

    if last_two_digits != 00:
        difference = 100 - last_two_digits
        number += difference

    return number

repos = db[db_name].find({"$query": {"display": True}, "$orderby": {"lines_of_code": 1}})

max_lines = db[db_name].find_one({"$query": {"display": True}, "$orderby": {"lines_of_code": -1}})
max_lines_of_code = round_up_severely(max_lines["lines_of_code"])

env = Environment(loader=FileSystemLoader('templates'))
template = env.get_template("index.html")
output_from_parsed_template = template.render(repos=repos, max_lines=max_lines_of_code)


if not os.path.exists(saveToDir):
    os.makedirs(saveToDir)

# to save the results
with open(saveToDir + "/index.html", "wb") as fh:
    fh.write(output_from_parsed_template)
print "HTML compilation done"
