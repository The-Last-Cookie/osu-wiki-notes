#!/bin/bash

# remove .sh extension when using script on path

# resources:
# https://www.redhat.com/sysadmin/arguments-options-bash-scripts

# TODO Exclude: filter can be implemented on different layers
# (filter file list [list based], filter the matches grep found [match based], filter files independently from the matches [file based])
# Filter the matches grep found: -e $(grep --include="*\\en.md" -R ./osu-wiki/wiki -e "Music theory" | grep -v "Main article" | sort)
# (mind the missing -l here)
# danach müssen die Dateipfade manuell rausgefischt werden
# ist so eine Anwendung sinnvoll?

BASE="" # base path to the wiki
LANGUAGE="en" # default language

QUERY=""
VERBOSE=false
EXCLUDE=()
REGEX=false
CASE=false
RESULTS=false

set -e # otherwise the script will exit on error

# https://stackoverflow.com/questions/16956810/find-all-files-containing-a-specific-text-string-on-linux
substring () { case $2 in *$1* ) return 0;; *) return 1;; esac ;}

# https://stackoverflow.com/a/71600549
containsElement () {
  local match="$1"
  local e
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

# https://stackoverflow.com/a/69960043
strpos () {
  haystack="$1"
  needle="$2"
  x="${haystack%%"$needle"*}"
  [[ "$x" = "$haystack" ]] && { echo -1; return 1; } || echo "${#x}"
}

help () {
  printf "Search for file contents in the osu! wiki."
  printf "\n"
  printf "Usage: [-h] [-v] [-l <lang>] [-i] [-r] [-e <exclude>] [-c] -q \"QUERY\""
  printf "\n"
  printf "\n"
  printf "Maintenance:"
  printf "\n"
  printf "  -h\t\tPrint this view."
  printf "\n"
  printf "\n"
  printf "Search options:"
  printf "\n"
  printf "  -l [language]\tUse language other than the default one."
  printf "\n"
  printf "\t\tValid language codes are listed in the article styling criteria."
  printf "\n"
  printf "  -r [regex]\tSearch with a regex pattern."
  printf "\n"
  printf "  -i\t\tIgnore case distinctions in the search query."
  printf "\n"
  printf "\t\tDoes NOT color output compared to normal output."
  printf "\n"
  printf "\n"
  printf "Output options:"
  printf "\n"
  printf "  -c\t\tShow comprehensive results for each match."
  printf "\n"
  printf "  -e [query]\tExclude any path from the results which contains [query]."
  printf "\n"
  printf "\t\tDoes NOT use regex pattern matching."
  printf "\n"
  printf "  -v\t\tDisplay the absolute path to found files."
  printf "\n"
}

build_grep () {
  # final command: grep --include="*\\en.md" -Rl "$BASE" -e "$QUERY" | sort
  local cmd=(
    --include="$1"
    -R
    "$BASE"
  )

  if $REGEX; then
    cmd+=(-G)
    cmd+=("$QUERY")
  else
    cmd+=(-e)
    cmd+=("$QUERY")
  fi

  if ! $RESULTS; then
    cmd+=(-l)
  fi

  if $CASE; then
    cmd+=(-i)
  fi

  echo "${cmd[@]}"
}

grep_color () {
  # https://stackoverflow.com/a/4332530
  local bold_red=$(tput setaf 1 bold)
  local normal=$(tput sgr0)

  local haystack="$1"
  local needle="$2"

  local match_start=$(strpos "${haystack}" "${needle}")
  local match_end=$((match_start + "${#needle}"))

  echo "${haystack:0:match_start}${bold_red}${needle}${normal}${haystack:match_end}"
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

  grep_cmd=( grep $(build_grep "${file_type}") )
  # echo "${grep_cmd[@]}"

  # Map results from grep command to array
  # Normal array syntax () can't be used because detailed results have spaces in them
  mapfile -t matches < <( "${grep_cmd[@]}" | sort )

  if [ ! -z $EXCLUDE ]; then
    # TODO: Does not read great
    mapfile -t matches < <( exclude "${matches[@]}" )
  fi

  len_base=${#BASE}
  for match in "${matches[@]}"; do
    local edited_match="${match}"
    if ! $VERBOSE; then
      edited_match="${edited_match:len_base}"
    fi

    if ! $RESULTS; then
      printf "${edited_match}\n"
      continue
    fi

    local delimiter_pos=$(strpos "${edited_match}" ":")
    ((delimiter_pos++)) # move one to the right
    local file_path="${edited_match:0:delimiter_pos}"
    local paragraph="${edited_match:delimiter_pos}"

    printf "${file_path}\n"

    # TODO: Coloring doesn't work with -i due to strpos not supporting this
    if $CASE; then
      echo "${paragraph}"
      printf "\n"
      continue
    fi

    # Using printf would return error on - at the start of the line
    # printf "%q" would print the color codes instead of the colored text
    local colored_match=$(grep_color "${paragraph}" "$QUERY")
    echo "${colored_match}"
    printf "\n"
  done

  printf "\nNumber of matches: ${#matches[@]}\n"
}

while getopts ":hvil:q:cre:" option; do
  case $option in
    h)
        help
        exit;;
    l)
        allowed_codes=("en" "ar" "be" "bg" "ca" "cs" "da" "de" "el" "es" "fi" "fil" "fr" "he" "hu" "id" "it" "ja" "ko" "lt" "nl" "no" "pl" "pt" "pt-br" "ro" "ru" "sk" "sl" "sr" "sv" "th" "tr" "uk" "vi" "zh" "zh-tw")
        if containsElement "$OPTARG" "${allowed_codes[@]}"; then
	  LANGUAGE="$OPTARG"
	else
	  printf "Language is not valid. Using default language.\n\n"
	fi
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
    i)
	CASE=true
	;;
    c)
	RESULTS=true
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
