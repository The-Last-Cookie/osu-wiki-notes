#!/bin/bash

# remove .sh extension when using script on path
# make the file executable with chmod +x [file]

# resources:
# https://www.redhat.com/sysadmin/arguments-options-bash-scripts

# TODO Exclude: filter can be implemented on different layers
# (filter file list [list based], filter the matches grep found [match based], filter files independently from the matches [file based])
# the first two are already in (see paramater -c)
# Filter the matches grep found: -e $(grep --include="*\\en.md" -R ./osu-wiki/wiki -e "Music theory" | grep -v "Main article" | sort)
# (mind the missing -l here)
# danach müssen die Dateipfade manuell rausgefischt werden
# ist so eine Anwendung sinnvoll?

BASE="/osu-wiki"
# base path to the repository folder
# MUST NOT contain any spaces

LANGUAGE="en"

QUERY=""
VERBOSE=false
EXCLUDE=()
CASE=false
REGEX=false
SUCCINCT=false
NEWS=false

# Print debug information
DEBUG=false

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
  printf "Usage: [-h] [-v] [-l <lang>] [-i] [-e <exclude>] [-c] [-r] -q \"QUERY\""
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
  printf "  -i\t\tIgnore case distinctions in the search query."
  printf "\n"
  printf "\t\tThe output will not be colored when using this option."
  printf "\n"
  printf "  -n\t\tSearch /news instead of /wiki."
  printf "\n"
  printf "\n"
  printf "Output options:"
  printf "\n"
  printf "  -f\t\tList files with matches instead of detailing each match."
  printf "\n"
  printf "  -r\t\tInterpret query as regular expression."
  printf "\n"
  printf "\t\tThe output will not be colored when using this option."
  printf "\n"
  printf "  -e [query]\tExclude results containing [query] in file paths or article lines."
  printf "\n"
  printf "\t\tArgument can be used multiple times to exclude several terms."
  printf "\n"
  printf "\t\tIf using the succinct file view (-f), file paths will be excluded instead."
  printf "\n"
  printf "\t\tDoes NEITHER support regex pattern matching NOR ignore case distinctions."
  printf "\n"
  printf "  -v\t\tDisplay the absolute path to found files."
  printf "\n"
}

build_grep () {
  local file_pattern="$1"
  local base_folder="$2"

  # e.g. final command: grep --include="*\\en.md" -Rl "$BASE" -e "$QUERY" | sort
  local cmd=(
    --include="${file_pattern}"
    -R
    "${base_folder}"
  )

  if $SUCCINCT; then
    cmd+=(-l)
  fi

  if ! $REGEX; then
    cmd+=(-F)
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

  local colored_needle="${bold_red}${needle}${normal}"
  echo "${haystack//$needle/$colored_needle}"
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
  local base_folder="${BASE}/wiki"

  if $NEWS; then
    file_type="*.md"
    base_folder="${BASE}/news"
  fi

  grep_cmd=( grep $(build_grep "${file_type}" "${base_folder}") )

  # Adding queries containing spaces inside build_grep is not possible
  grep_cmd+=(-e)
  grep_cmd+=("${QUERY}")

  if $DEBUG; then
    echo "${grep_cmd[@]}"
  fi

  # Map results from grep command to array
  # Normal array syntax () can't be used because detailed results have spaces in them
  mapfile -t matches < <( "${grep_cmd[@]}" | sort )

  if [ ! -z "$EXCLUDE" ]; then
    # TODO: Does not read great
    mapfile -t matches < <( exclude "${matches[@]}" )
  fi

  len_base=$((${#BASE}+6))
  # Add 6 to remove /wiki/ or /news/ as well

  for match in "${matches[@]}"; do
    local edited_match="${match}"
    if ! $VERBOSE; then
      edited_match="${edited_match:len_base}"
    fi

    if $SUCCINCT; then
      printf "${edited_match}\n"
      continue
    fi

    local delimiter_pos=$(strpos "${edited_match}" ":")
    ((delimiter_pos++)) # move one to the right
    local file_path="${edited_match:0:delimiter_pos}"
    local paragraph="${edited_match:delimiter_pos}"

    printf "${file_path}\n"

    # Supporting -i or regex search in strpos is difficult
    if $CASE || $REGEX ; then
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

while getopts ":hvil:q:rfe:n" option; do
  case $option in
    h)
        help
        exit;;
    l)
        allowed_codes=("en" "ar" "be" "bg" "ca" "cs" "da" "de" "el" "es" "fi" "fil" "fr" "he" "hu" "id" "it" "ja" "ko" "lt" "nl" "no" "pl" "pt" "pt-br" "ro" "ru" "sk" "sl" "sr" "sv" "th" "tr" "uk" "vi" "zh" "zh-tw")
        if containsElement "$OPTARG" "${allowed_codes[@]}"; then
    	  LANGUAGE="$OPTARG"
    	else
          printf "Language is not valid. Using default language '$LANGUAGE'.\n\n"
    	fi
        ;;
    q)
        QUERY="$OPTARG"
        ;;
    v)
        VERBOSE=true
        ;;
    i)
    	CASE=true
    	;;
    r)
        REGEX=true
        ;;
    f)
        SUCCINCT=true
    	;;
    e)
        EXCLUDE+=("$OPTARG")
        ;;
    n)
        NEWS="$OPTARG"
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
