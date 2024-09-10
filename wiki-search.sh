#!/bin/bash

# remove .sh extension when using script on path

# inspired by:
# https://www.redhat.com/sysadmin/arguments-options-bash-scripts
# https://stackoverflow.com/questions/16956810/find-all-files-containing-a-specific-text-string-on-linux

BASE="" # base path to the wiki
LANGUAGE="en" # default language

QUERY=""
VERBOSE=false
EXCLUDE=""
REGEX=false

help () {
  printf "Search for file contents in the osu! wiki."
  printf "\n"
  printf "Usage: [-h] [-v] [-l <lang>] [-r] [-e <exclude>] -q QUERY"
  printf "\n"
  printf "\n"
  printf "Maintenance:"
  printf "\n"
  printf "\t-h\t\tPrint this view."
  printf "\n"
  printf "\n"
  printf "Search options:"
  printf "\n"
  #   -d, --dirs                   Search only in directory names.
  printf "\t-l [language]\tUse language other than the default one."
  printf "\n"
  printf "\t-r [regex]\tSearch with a regex pattern."
  printf "\n"
  printf "\n"
  printf "Output options:"
  printf "\n"
  printf "\t-e [query]\tExclude any path from the results that contains query."
  printf "\n"
  printf "\t-v\t\tOutput of the entire link to found files."
}

search () {
  local file_type="*\\${LANGUAGE}.md"

  if $REGEX; then
    local matches=$(grep --include=${file_type} -Rl "$BASE" -G "$QUERY" | sort)
  else
    local matches=$(grep --include=${file_type} -Rl "$BASE" -e "$QUERY" | sort)
  fi

  if [ ! -z $EXCLUDE ]; then
    matches=$(grep -v $EXCLUDE $matches)
  fi

  if $VERBOSE; then
    echo "$matches"
    return
  fi

  # cut base url from each string
  len_base=${#BASE}
  for match in $matches; do
    echo ${match:len_base}
  done
}

while getopts ":hvl:q:re:" option; do
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
    r)
        echo "regex"
        REGEX=true
        ;;
    v)
        echo "verbose"
        VERBOSE=$OPTARG
        ;;
    e)
        echo "exclude"
        EXCLUDE=$OPTARG
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
