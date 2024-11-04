# put in /etc/bash_completion.d/wiki-file-completion (no .sh)

# inspired by:
# https://web.archive.org/web/20190328055722/https://debian-administration.org/article/316/An_introduction_to_bash_completion_part_1
# https://web.archive.org/web/20140405211529/http://www.debian-administration.org/article/317/An_introduction_to_bash_completion_part_2
# https://linuxsimply.com/bash-scripting-tutorial/string/split-string/

BASE="/osu-wiki/wiki/"

_wiki_completion()
{
  local cur prev opts
  COMPREPLY=()
  cur="${COMP_WORDS[COMP_CWORD]}"
  prev="${COMP_WORDS[COMP_CWORD-1]}"

  local root="${BASE}"

  # TODO: \\! issue

  if [[ ${cur} != *"/"* ]]; then
    # first layer where no slashes are present
	  root="${BASE}"
  elif [[ ${cur} == */ ]]; then
	  # whole folder name with / is given in cur
	  #temp="${cur/"\\"/'\'}"
    root="${BASE}${cur}"
  else
	  # only part of folder name is given
	  # remove last folder fragment for find command
	  current_path="${cur%/*}"
	  root="${BASE}${current_path}/"
  fi

  local directories=( $(find "${root}" -mindepth 1 -maxdepth 1 -type d ! -name img | sort) )
  local len_base="${#BASE}"
  for i in "${!directories[@]}"; do
    directories[$i]="${directories[$i]:len_base}"
  done

  opts="${directories[*]}"

  COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
  return 0
}

complete -o nospace -o filenames -S / -F _wiki_completion wiki-file
