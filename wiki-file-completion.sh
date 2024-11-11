# put in /etc/bash_completion.d/wiki-file-completion (no .sh)

# inspired by:
# https://web.archive.org/web/20190328055722/https://debian-administration.org/article/316/An_introduction_to_bash_completion_part_1
# https://web.archive.org/web/20140405211529/http://www.debian-administration.org/article/317/An_introduction_to_bash_completion_part_2
# https://linuxsimply.com/bash-scripting-tutorial/string/split-string/

# Must have slash at the end
BASE="/osu-wiki/wiki/"

_remove_escape_characters()
{
    # When printing to console, ! and () must be escaped as bash would interpret the character
    # Find command however would not find folders with ! and ()
    # sed: s/ORIGINAL/REPLACEMENT/g
    echo $(echo "${1}" | sed -e 's/\\!/\!/g' -e 's/\\(/\(/g' -e 's/\\)/\)/g')
}

_wiki_completion()
{
    local cur prev opts
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    local root="${BASE}"

    if [[ ${cur} != *"/"* ]]; then
        # first layer where no slashes are present
        root="${BASE}"
    elif [[ ${cur} == */ ]]; then
        # whole folder name with / is given in cur
        local escaped_path=$( _remove_escape_characters "${cur}")
        root="${BASE}${escaped_path}"
    else
        # only part of folder name is given
        # remove last folder fragment for find command
        local current_path="${cur%/*}"
        local escaped_path=$( _remove_escape_characters "${current_path}")
        root="${BASE}${escaped_path}/"
    fi

    mapfile -t folders < <( find "${root}" -mindepth 1 -maxdepth 1 -type d ! -name img | sort )

    local len_base="${#BASE}"
    for i in "${!folders[@]}"; do
        local current_folder="${folders[$i]}"

        # cut BASE path from string
        # Variable cur contains the path without BASE
        current_folder="${current_folder:len_base}"

        # escape single quotes
        current_folder="${current_folder@Q}"

        folders[$i]="${current_folder}"
    done

    opts="${folders[*]}"

    COMPREPLY=( $(compgen -W "${opts}" -- ${cur}) )
    return 0
}

complete -o nospace -o filenames -S / -F _wiki_completion wiki-file
