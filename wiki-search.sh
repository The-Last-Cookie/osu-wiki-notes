#!/bin/bash

# inspired by:
# https://www.redhat.com/sysadmin/arguments-options-bash-scripts
# https://stackoverflow.com/questions/16956810/find-all-files-containing-a-specific-text-string-on-linux

BASE="" # base path to the wiki
LANGUAGE="en"
QUERY=""

help () {
  echo "print help"
}

search () {
  local file_type="*\\${LANGUAGE}.md"
  local matches=$(grep --include=${file_type} -Rl "$BASE" -e "$QUERY" | sort)
  echo "$matches"
}

while getopts ":hl:q:" option; do
  case $option in
    h)
        help
        exit;;
    l)
        echo "lang"
        LANGUAGE=$OPTARG
        ;;
    q)
        echo "query"
        QUERY=$OPTARG
        ;;
    \?)
        echo "Error: Invalid option"
        exit;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
   esac
done

if [ -z "$QUERY" ]; then
  echo "Query is empty. Exiting."
  exit 0
fi

search

# Search for file contents in the osu! wiki.
#
# Usage: [OPTIONS] QUERY
#
# Maintenance:
#   -h, --help                   Print this view.
#   -s, --set [link]             Set the link to the wiki.
#
# Search options:
#   -d, --dirs                   Search only in directory names.
#                                Notice: On Windows, you need to use '\' if you want to search via
#                                folder paths.
#   -l, --language [language]    Set specific language. Can be any
#                                language the wiki supports (two-letter country code).
#   -r, --regex [regex]          Search with a regex pattern.
#
# Output options:
#   -e, --exclude [query]        Exclude a query from the search. Use
#                                this parameter several times if you want to exclude several terms.
#                                If the -r argument is set, the value here must be valid regex.
#                                Notice: On Windows, you need to use '\' if you want to exclude
#                                specific folder paths.
#   -v, --verbose                Output of the entire link to found
#                                files.
