#!/bin/bash

# remove .sh extension when using script on path

# inspired by:
# https://www.redhat.com/sysadmin/arguments-options-bash-scripts
# https://stackoverflow.com/questions/16956810/find-all-files-containing-a-specific-text-string-on-linux

# TODO: directly show result from specific file? argument -r 1

BASE="" # base path to the wiki
LANGUAGE="en" # default language

QUERY=""
VERBOSE=false
EXCLUDE=()
REGEX=false


substring() { case $2 in *$1* ) return 0;; *) return 1;; esac ;}

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
  printf "\t-l [language]\tUse language other than the default one."
  printf "\n"
  printf "\t-r [regex]\tSearch with a regex pattern."
  printf "\n"
  printf "\n"
  printf "Output options:"
  printf "\n"
  printf "\t-e [query]\tExclude any path from the results which contains [query]. Does NOT use regex pattern matching."
  printf "\n"
  printf "\t-v\t\tDisplay the absolute path to found files."
  printf "\n"
}

exclude () {
  local all_matches=("$@")
  for match in "${all_matches[@]}"; do
    local disabled=false
    for disallowed in "${EXCLUDE[@]}"; do
        if substring "$disallowed" "$match"; then
          # Skip match entirely
          disabled=true
          break
      fi
    done

    if ! $disabled; then
      echo "${match}"
    fi
  done
}

search () {
  local file_type="*\\${LANGUAGE}.md"

  if $REGEX; then
    local matches=( $(grep --include=${file_type} -Rl "$BASE" -G "$QUERY" | sort) )
  else
    local matches=( $(grep --include=${file_type} -Rl "$BASE" -e "$QUERY" | sort) )
  fi

  if [ ! -z $EXCLUDE ]; then
    matches=( $(exclude "${matches[@]}") )
  fi

  len_base=${#BASE}
  for match in "${matches[@]}"; do
    if $VERBOSE; then
      echo $match
    else
      # cut base url from each string
      echo ${match:len_base}
    fi
  done

  printf "\nNumber of matches: ${#matches[@]}\n"
}

while getopts ":hvl:q:re:" option; do
  case $option in
    h)
        help
        exit;;
    l)
        LANGUAGE="$OPTARG"
        ;;
    q)
        QUERY="$OPTARG"
        ;;
    r)
        REGEX=true
        ;;
    v)
        VERBOSE=true
        ;;
    e)
        EXCLUDE+=("$OPTARG")
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
