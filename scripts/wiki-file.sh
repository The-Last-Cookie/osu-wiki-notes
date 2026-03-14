#!/bin/bash

BASE="/osu-wiki/wiki/"
# base path to the repo folder
# MUST NOT contain any spaces
# MUST have slash at the end

set -e # otherwise the script will exit on error

ARTICLE=""
ONLINE=false

COUNTRIES_EN=()
COUNTRIES_DE=()

allowed_codes=("en" "ar" "be" "bg" "ca" "cs" "da" "de" "el" "es" "fi" "fil" "fr" "he" "hu" "id" "it" "ja" "ko" "lt" "nl" "no" "pl" "pt" "pt-br" "ro" "ru" "sk" "sl" "sr" "sv" "th" "tr" "uk" "vi" "zh" "zh-tw")

grep_color () {
  # https://stackoverflow.com/a/4332530
  local bold_red=$(tput setaf 1 bold)
  local normal=$(tput sgr0)

  local haystack="$1"
  local needle="$2"

  local colored_needle="${bold_red}${needle}${normal}"
  echo "${haystack//$needle/$colored_needle}"
}

# https://stackoverflow.com/a/71600549
containsElement () {
  local match="$1"
  local e
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

help () {
  printf "Quickly access a folder or file in the osu! wiki by tab-completing the path."
  printf "\n"
  printf "Usage: [-h|-a] [-p <path>] [-o] [-c <mode>] [-s <query>]"
  printf "\n"
  printf "\n"
  printf "Maintenance:"
  printf "\n"
  printf "  -h\t\tPrint this view."
  printf "\n"
  printf "\n"
  printf "File operations:"
  printf "\n"
  printf "  -p <path>\tThe article to retrieve."
  printf "\n"
  printf "  -o\t\tAccess the article in its online version instead."
  printf "\n"
  printf "  -c <mode>\tUse a converter for the selected file. <mode> can be 'date' or 'country'."
  printf "\n"
  printf "\n"
  printf "Search mode:"
  printf "\n"
  printf "  -a\t\tOutput every wiki path line per line."
  printf "\n"
  printf "  -s <query>\tSearch wiki paths with basic full-text matching (case-sensitive)."
  printf "\n"
}

local_mode () {
  # Todo: offer alternatives to code editor

  if [[ "${ARTICLE}" = *"/" ]] || [[ "${ARTICLE}" != *"/"* ]]; then
    code "${BASE}${ARTICLE}"
    return
  fi

  # https://linuxsimply.com/bash-scripting-tutorial/string/split-string/
  local lang="${ARTICLE##*/}"
  local valid_path="${ARTICLE%/*}"

  if containsElement "${lang}" "${allowed_codes[@]}"; then
    code "${BASE}${valid_path}/${lang}.md"
    return
  fi

  echo "Language is not valid. Opening parent folder."
  code "${BASE}${valid_path}"
}

online_mode () {
  # TODO: offer other browsers as alternative

  local domain="https://osu.ppy.sh/wiki/"

  if [[ "${ARTICLE}" = *"/" ]] || [[ "${ARTICLE}" != *"/"* ]]; then
    firefox "${domain}${ARTICLE}"
    return
  fi

  # https://linuxsimply.com/bash-scripting-tutorial/string/split-string/
  local lang="${ARTICLE##*/}"
  local valid_path="${ARTICLE%/*}"

  if containsElement "${lang}" "${allowed_codes[@]}"; then
    firefox "${domain}${lang}/${valid_path}"
    return
  fi

  echo "Language is not valid. Opening parent folder."
  code "${domain}${valid_path}"
}

get_all_wiki_links () {
  mapfile -t paths < <( find "${BASE}" -mindepth 1 -type d ! -name img | sort )
  local len_base="${#BASE}"
  for path in "${paths[@]}"; do
      echo "${path:len_base}"
  done
}

convert_date () {
  # https://www.gnu.org/software/sed/manual/html_node/Regular-Expressions.html
  # https://www.gnu.org/software/sed/manual/html_node/Extended-regexps.html
  local file="$1"
  sed 's/\([0-9]\{4\}\)-\([0-9]\{2\}\)-\([0-9]\{2\}\)/\3.\2.\1/g' -i $file

  # TODO: diff view?
}

convert_countries () {
  local file="$1"

  local pwd="${0%/*}"
  mapfile -t COUNTRIES_EN < "${pwd}/en.txt"
  mapfile -t COUNTRIES_DE < "${pwd}/de.txt"

  local max_index=$((${#COUNTRIES_EN[@]}-1))
  for i in $(seq 0 $max_index); do
    local country="${COUNTRIES_EN[$i]:0:-1}"
    local country_de="${COUNTRIES_DE[$i]:0:-1}"
    sed "s/::{ flag=\([A-Z]\{2\}\) }:: $country/::{ flag=\1 }:: $country_de/g" -i $file
  done
}

convert_mode () {
  local mode="$1"
  local abs_path=""

  # https://linuxsimply.com/bash-scripting-tutorial/string/split-string/
  local lang="${ARTICLE##*/}"
  local valid_path="${ARTICLE%/*}"

  if containsElement "${lang}" "${allowed_codes[@]}"; then
    abs_path="${BASE}${valid_path}/${lang}.md"
  else
    echo "Valid language not found. The syntax for the -p argument is {Article}/{language code}."
    exit
  fi

  case $mode in
    "date") convert_date $abs_path ;;
    "country") convert_countries $abs_path ;;
    *) echo "Unknown mode '$mode'. Refer to the documentation for usage details." ;;
  esac
}

search () {
  local query="$1"
  local paths=$(get_all_wiki_links)

  local result=$(echo "$paths" | grep --fixed-strings -e "${query}")
  local colored_match=$(grep_color "${result[*]}" "${query}")
  echo "${colored_match}"
}

while getopts ":hp:oac:s:" option; do
  case $option in
    h)
        help
        exit;;
    p)
        ARTICLE="${OPTARG}"
        ;;
    o)
        ONLINE=true
        ;;
    a)
        get_all_wiki_links
        exit;;
    c)
        convert_mode "${OPTARG}"
        exit;;
    s)
        search "${OPTARG}"
        exit;;
    \?)
        echo "Error: Invalid option"
        exit;;
    :)
        echo "Option -$OPTARG requires an argument." >&2
        exit 1
        ;;
   esac
done

if [ -z "${ARTICLE}" ]; then
  echo "No parameter -p found. Redirecting to the root folder."
fi

if $ONLINE; then
  online_mode
  exit 0
fi

local_mode
