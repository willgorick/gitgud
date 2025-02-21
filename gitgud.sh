#!/bin/zsh

function choose_from_menu() {
    local prompt="$1" outvar="$2"
    shift
    shift
    local options=("$@") cur=1 count=$# index=0
    local esc=$(echo -en "\033")
    echo -n "$prompt\n"
    total_rows=$#
    total_rows_with_prompt=$(($total_rows+1))
    while true
    do
        index=1
        for o in "${options[@]}"
        do
            if [[ "$index" == "$cur" ]]
                then echo -e "\033[36m[*] $o\033[0m"
                else echo "[]  $o"
            fi
            index=$(( $index+1 ))
        done
        read -s -r -k key
        if [[ $key == A ]] # move up
            then cur=$(( $cur - 1 ))
            [ "$cur" -lt 1 ] && cur=$count # wrap list
        elif [[ $key == B ]] # move down
            then cur=$(( $cur + 1 ))
            [ "$cur" -gt $count ]  && cur=1
        elif [[ "${key}" == $'\n' ]] # exit if enter pressed
            then break
        fi
        # erase all lines of selections to build them again with new positioning
        for ((i=0; i < $total_rows; i++)); do
            printf "\033[2k\r"
            printf "\033[F"
        done
    done
    # erase all lines of selection once a selection is chosen
    for ((i=0; i < $total_rows_with_prompt; i++ )); do 
        printf "\033[A\033[K"
    done
    echo -e "$prompt\033[36m${options[$cur]}\033[0m"
    # pass chosen selection to output
    eval $outvar="'${options[$cur]}'"
}

function commit() {
    delcare -a selections
    selections=(
        "feat"
        "fix"
        "docs"
        "style"
        "test"
    )

    type_prompt="What type of change are you committing: "
    scope_prompt="What is the scope of this change (press [enter] to skip): "
    commit_prompt="Short imperative message explaining what changed: "

    # $1: Prompt text, $2: output, $3: menu options
    choose_from_menu $type_prompt type "${selections[@]}"
    read "scope?$scope_prompt"
    printf "\033[A\033[K"
    echo -e "$scope_prompt\033[36m$scope\033[0m"
    read "message?$commit_prompt"
    printf "\033[A\033[K"
    echo -e "$commit_prompt\033[36m$message\033[0m"

    output="$type"
    if ! [ -z $scope ]; then 
        output=$output"("$scope")"
    fi
    output=$output": "$message

    echo -e "Commit message: \033[36m$output\033[0m"
    echo -n "Do you want to commit this message?: (y/n) "
    while true
    do
        read -s -r -k key
        if [[ "${key}" == "y" ]]; then
            echo "\nCommitting..."
            git commit -m "$output"
            break
        elif [[ "${key}" == "n" ]]; then    
            echo "\nExiting..."
            break
        fi
    done
}

function pr() {
    title_prompt="What is the title of the PR: "
    body_prompt="What is the body of the PR: "
    jira_prompt="Does this work have a corresponding Jira ID: "
    base_prompt="What is the base branch for the PR (if empty, default is main): "
    head_prompt="What is the head branch for the PR (if empty, default is current branch): "

    read "title?"$title_prompt
    printf "\033[A\033[K"
    echo -e "$title_prompt\033[36m$title\033[0m"

    read "body?"$body_prompt
    printf "\033[A\033[K"
    echo -e "$body_prompt\033[36m$body\033[0m"

    read "jira?"$jira_prompt
    printf "\033[A\033[K"
    echo -e "$jira_prompt\033[36m$jira\033[0m"
    if ! [ -z $jira ]; then
        jira="Jira=$jira\n"
    fi

    read "base?"$base_prompt
    if [ -z $base ]; then
        base="main"
    fi
    printf "\033[A\033[K"
    echo -e "$base_prompt\033[36m$base\033[0m"

    read "head?"$head_prompt
    if [ -z $head ]; then
        head=$(git branch --show-current)
    fi
    printf "\033[A\033[K"
    echo -e "$head_prompt\033[36m$head\033[0m"

    output="Title: \"$title\"\nBody: \"$body\"\nBase: \"$base\"\nHead: \"$head\""
    echo -e "PR info:"
    echo -e "\033[36m$output\033[0m"
    echo -n "Do you want to create this PR?: (y/n) "
    read -s -r -k key
    if [[ "${key}" == "y" ]]; then
        echo "\nCreating PR..."
        gh pr create --title "$title" --body "$jira$body" --base $base --head $head
    else
        echo "\nExiting..."
    fi
}

valid_params="'commit', 'pr'"

if [[ $# == 0 ]]; then
    echo "No params provided, please provide one of the following: $valid_params"
    exit 1
elif [[ $# > 2 ]]; then 
    echo "Too many params provided"
    exit 1
fi
command=$1

if [[ $command == 'commit' ]]; then
    commit
elif [[ $command == 'pr' ]]; then
    pr
else
    echo "Invalid param: valid params are: $valid_params"
fi