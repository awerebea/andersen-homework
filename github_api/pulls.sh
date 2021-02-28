#! /bin/bash

# define "help" message
help=$'usage: ./pulls.sh [OPTIONS] REPO_URL
The script checks for open pull requests for the GitHub repository and displays
statistics about its contributors.
Examples:
./pulls.sh --min-num 2 --verbose https://github.com/torvalds/linux
./pulls.sh --min-num 1 https://github.com/EbookFoundation/free-programming-books
./pulls.sh -m 1 -l https://github.com/EbookFoundation/free-programming-books
./pulls.sh --labels -v -m 3 https://github.com/facebook/react

REPO_URL: required argument, URL of the GitHub repository in format
          \'https://github.com/$user/$repo\'

OPTIONS:
  -m, --min-num NUM     consider contributors with a minimum NUM of open
                        pull requests. Default 2
  -l, --labels          only count pull requests with labels
  -v, --verbose         display the progress of fetching pages with data

  -h, --help            print this help message'

# acceptable OPTIONS
options=("-m --min-num")

# define error messages
err_syntax="Syntax error. Type './pulls.sh --help' to see more info"

err_arg_miss="Error: argument missing."
err_arg_miss="$err_arg_miss Type './pulls.sh --help' to see more info"

err_arg_invalid="Error: invalid argument."
err_arg_invalid="$err_arg_invalid Type './pulls.sh --help' to see more info"

# difine default conditions
def_min_num=2 # the minimum number of open PR's to consideration the contributor

# parse input parameters
# set default values
labels=0
silent="-s"
min_num=$def_min_num
# check arguments
if [ "$#" -eq 0 ]; then
  echo "$err_arg_miss"
  exit 1
elif [ "$#" -eq 1 ]; then
# there is only one argument
  if [[ $1 == '-h' || $1 == '--help' ]]; then
    # the ony argument is 'help'
    echo "$help"
    exit 0
  else
    # the only argument is repo URL
    if [[ ! "$1" =~ ^"https://github.com/".*"/".* ]]; then
      echo $1
      echo "$err_arg_invalid"
      exit 1
    fi
    input_url=$1
  fi
elif [ "$#" -gt 1 ]; then
# args num > 1, store arguments in a array
  args=("$@")
  prev_arg_is_key=false
  ind=0
  for (( i=0;i<$#;i++)); do
  # loop for each argument
    if [ "$prev_arg_is_key" = true ]; then
    # previous arg is option identifer
      case "${args[${ind} - 1]}" in
        -m|--min-num)
          if [[ ${args[${ind}]} =~ ^[0-9]+$ ]] && \
            [ "${args[${ind}]}" -ge 1 ]; then
            min_num="${args[${ind}]}"
          else
            echo "$err_syntax"
            exit 1
          fi
          ((ind++));;
      esac
      prev_arg_is_key=false
    else
    # previous arg is option value (or current arg is the first or "--labels")
      if [[ ${args[${ind}]} == '-l' || ${args[${ind}]} == '--labels' ]]; then
        labels=1
      elif [[ ${args[${ind}]} == '-v' || ${args[${ind}]} == '--verbose' ]]; then
        silent=""
      elif [[ " ${options[@]} " =~ "${args[${ind}]}" ]]; then
      # the arg is acceptable option key
        prev_arg_is_key=true
      else
        if [ $ind -eq $(($#-1)) ]; then
          if [[ ! "${args[${ind}]}" =~ ^"https://github.com/".*"/".* ]]; then
            echo "${args[${ind}]}"
            echo "$err_arg_invalid"
            exit 1
          fi
          input_url="${args[${ind}]}"
        else
        # arg is not last in args - syntax error
          echo "$err_syntax"
          exit 1
        fi
      fi
      ((ind++))
    fi
  done
fi

# generate request url
request_url=$(echo $input_url | \
  sed 's/https:\/\/github.com/https:\/\/api.github.com\/repos/')
request_url="${request_url}/pulls?page="

# generate table with raw response
cout_of_records=4
table_raw=()
page_num=1
while [[ $cout_of_records -gt 3 ]]; do
  page_content=$(curl $silent -H "Authorization: token $gh_token" \
    "${request_url}${page_num}")
  cout_of_records=$(printf "%s\n" $page_content | wc -l)
  table_raw+=$page_content
  ((page_num++))
done

# final output
if [ "$labels" -eq 0 ]; then
  all_contributors=()
  while IFS= read -r line; do
    all_contributors+=( "$line" )
  done < <(printf "%s\n" "${table_raw[@]}" | \
    jq -r '.[].user.login' | sort | uniq -c | sort -k1gr -k2g)
  printf "Contributors with minimum %s open pull requests:\n" $min_num
  echo "--------------------------+--------------------"
  printf "%-25s | Open pull requests\n" "User login"
  echo "--------------------------+--------------------"
  for line in "${all_contributors[@]}"; do
    if [[ $(echo $line | awk '{print $1}') -ge $min_num ]]; then
      printf "%-25s |       %3s\n" \
        $(echo $line | awk '{printf $2}') $(echo $line | awk '{printf $1}')
      echo "--------------------------+--------------------"
    fi
  done
else
  # PR's with labels
  prs_with_labels=$(printf "%s\n" "${table_raw[@]}" | \
    jq -r '[.[] | select(.labels[].id != null)] | unique')
  all_contributors=()
  while IFS= read -r line; do
    all_contributors+=( "$line" )
  done < <(printf "%s\n" "${prs_with_labels[@]}" | \
    jq -r '.[].user.login' | sort | uniq -c | sort -k1gr -k2g)
  printf "Contributors with minimum %s open pull requests:\n" $min_num
  echo "--------------------------+--------------------------------"
  printf "%-25s | Open pull requests with labels\n" "User login"
  echo "--------------------------+--------------------------------"
  for line in "${all_contributors[@]}"; do
    if [[ $(echo $line | awk '{print $1}') -ge $min_num ]]; then
      printf "%-25s |          %3s\n" \
        $(echo $line | awk '{printf $2}') $(echo $line | awk '{printf $1}')
      echo "--------------------------+--------------------------------"
    fi
  done
fi
