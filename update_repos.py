import pymongo
import json
from subprocess import Popen, PIPE
import datetime
import os

client = pymongo.MongoClient(os.environ["repomeister_db_host"], int(os.environ["repomeister_db_port"]))
db_name = os.environ["repomeister_db_name"]
db = client[db_name]

repo_file = open('repo_file', 'r')

def get_stats(git_string):
    p = Popen(['./get_stats_repo.sh', git_string], stdin=PIPE, stdout=PIPE)
    output, err = p.communicate()
    rc = p.returncode

    if not err:
        try:
            stats = json.loads(output)

            if stats:
                return stats
        except ValueError, e:
            print e
    else:
        print err


for git_string in repo_file:
    stats = get_stats(git_string)

    if stats:
        print stats["name"], stats["lines_of_code"]

        stats["slug"] = git_string

        stats_already_in_db = db[db_name].find_one({"slug": stats["slug"]})

        if stats_already_in_db:
            db[db_name].update_one(
                {"slug": stats["slug"]},
                {"$set": {
                    "name": stats["name"],
                    "languages": stats["languages"],
                    "updated_on": datetime.datetime.utcnow(),
                }}
            )
        else:
            db[db_name].insert(stats);
