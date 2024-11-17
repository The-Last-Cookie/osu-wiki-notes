#!/bin/bash

BASE="/osu-wiki/wiki/"
# base path to the repo folder
# MUST NOT contain any spaces
# MUST have slash at the end

set -e # otherwise the script will exit on error

ARTICLE=""
ONLINE=false

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
  printf "Usage: [-h|-a] -p PATH [-o]"
  printf "\n"
  printf "\n"
  printf "Maintenance:"
  printf "\n"
  printf "  -h\t\tPrint this view."
  printf "\n"
  printf "\n"
  printf "Options:"
  printf "\n"
  printf "  -p\t\tThe article to retrieve."
  printf "\n"
  printf "  -o\t\tAccess the article in its online version instead."
  printf "\n"
  printf "  -a\t\tOutput every wiki path line per line."
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

  allowed_codes=("en" "ar" "be" "bg" "ca" "cs" "da" "de" "el" "es" "fi" "fil" "fr" "he" "hu" "id" "it" "ja" "ko" "lt" "nl" "no" "pl" "pt" "pt-br" "ro" "ru" "sk" "sl" "sr" "sv" "th" "tr" "uk" "vi" "zh" "zh-tw")
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

  allowed_codes=("en" "ar" "be" "bg" "ca" "cs" "da" "de" "el" "es" "fi" "fil" "fr" "he" "hu" "id" "it" "ja" "ko" "lt" "nl" "no" "pl" "pt" "pt-br" "ro" "ru" "sk" "sl" "sr" "sv" "th" "tr" "uk" "vi" "zh" "zh-tw")
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

while getopts ":hp:oa" option; do
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
