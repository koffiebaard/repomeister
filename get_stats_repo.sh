#!/bin/bash

current_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
git_string=$1
repos_dir="repos"
SLOC="sloccount"

repo_name=$(echo $git_string | sed 's/\// /' | awk '{print $2}' | sed s/\.git//)

if [ "$git_string" ] && [ "$repo_name" ]; then
    if [ -d $current_dir/$repos_dir ]; then

        cd $current_dir/$repos_dir

        # checkout repo
        if [ -d $repo_name ]; then
            cd $repo_name
            git pull &> /dev/null # silent b/c we'll parse stdout as json later
            cd ../
        else
            git clone $git_string &> /dev/null # silent b/c we'll parse stdout as json later
        fi

        # proceed w/ business logic
        if [ -d $repo_name ]; then
            cd $repo_name

            while read third_party_dir; do
                if [ -d $third_party_dir ]; then
                    rm -rf $third_party_dir
                fi
            done <$current_dir/ignorefile

            # The Business©
            sloc=$($SLOC .)

            # total # lines of code and breakdown of languages
            total_loc=$(echo "${sloc}" | grep "(SLOC)" | cut -d "=" -f2 | tr -d "," | xargs)
            breakdown=$(echo "${sloc}" | grep "Totals grouped by language" -n5 | egrep '[0-9.]+%' | cut -d'-' -f2)

            # output json
            echo -e "{"
                echo -e "\"name\":\"${repo_name}\","
                echo -e "\"lines_of_code\":${total_loc},"

                echo -e "\"languages\": ["
                    IFS=$'\n'
                    first=true
                    for breakdown_item in $breakdown
                    do

                        # just to place the fucking comma in a JSON compliant way. Fuck you, bash.
                        if [ $first == false ]; then
                            echo -e ","
                        fi

                        if [ $first ]; then
                            first=false
                        fi

                        language=$(echo $breakdown_item | awk '{print $1}' | cut -d ":" -f1)
                        lines_actual=$(echo $breakdown_item | awk '{print $2}' | tr -d ",")
                        lines_percentage=$(echo $breakdown_item | awk '{print $3}' | tr -d "()")

                        echo -e "{"
                            echo -e "\"language\":\"$language\","
                            echo -e "\"lines_actual\":$lines_actual,"
                            echo -e "\"lines_percentage\":\"$lines_percentage\""
                        echo -e "}"

                    done
                echo -e "]"
            echo -e "}"

            # remove repo. optional, mainly to save disk space
            # cd $current_dir
            # rm -rf $repos_dir/$repo_name

            exit 0
        fi
    fi
fi

exit 1
