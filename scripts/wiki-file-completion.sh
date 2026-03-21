# put in /etc/bash_completion.d/wiki-file-completion (no .sh)
# source the completion script in the session where wiki-file is executed --> otherwise bash script is not loaded

# inspired by:
# https://web.archive.org/web/20190328055722/https://debian-administration.org/article/316/An_introduction_to_bash_completion_part_1
# https://web.archive.org/web/20140405211529/http://www.debian-administration.org/article/317/An_introduction_to_bash_completion_part_2
# https://linuxsimply.com/bash-scripting-tutorial/string/split-string/

# Must have slash at the end
BASE="/osu-wiki/wiki/"

_remove_escape_characters()
{
    # When printing to console, ! and () as well as single quotes must be escaped as bash would interpret the character
    # Find command however would not find folders with these escaped characters: ! () '
    # sed: s/ORIGINAL/REPLACEMENT/g
    echo $(echo "${1}" | sed -e 's/\\!/\!/g' -e 's/\\(/\(/g' -e 's/\\)/\)/g' -e 's/\\\x27/\x27/g')
}

_wiki_completion()
{
    local current="${COMP_WORDS[COMP_CWORD]}"
    local previous="${COMP_WORDS[COMP_CWORD-1]}"
    #local cursor_pos="${COMP_POINT}"

    if [[ ${previous} != "-p" ]]; then
        return 0
    fi

    local root="${BASE}"

    if [[ ${current} == *"/"* ]]; then
        # remove last folder fragment for find command
        local current_path="${current%/*}"
        local escaped_path=$( _remove_escape_characters "${current_path}")
        root="${BASE}${escaped_path}/"
    fi

    mapfile -t folders < <( find "${root}" -mindepth 1 -maxdepth 1 -type d ! -name img | sort )

    local len_base="${#BASE}"
    for i in "${!folders[@]}"; do
        local current_folder="${folders[$i]}"

        # cut BASE path from current_folder
        current_folder="${current_folder:len_base}"

        # escape single quotes in console tab completion
        current_folder="${current_folder@Q}"

        folders[$i]="${current_folder}"
    done

    local suggestions="${folders[*]}"

    COMPREPLY=( $(compgen -W "${suggestions}" -- ${current}) )
    return 0
}

complete -o nospace -o filenames -S / -F _wiki_completion wiki-file
