#! /bin/bash

# define "help" message
help=$'usage: ./pulls.sh [OPTIONS] REPO_URL
The script checks for open pull requests for the GitHub repository and displays
its top contributors.
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

  -t, --token TOKEN     GitHub personal TOKEN for authentication and increasing
                        the API request limit from 60 to 5000 per hour.
                        For more info visit:
                        https://docs.github.com/en/rest/guides/getting-started-with-the-rest-api#authentication
                        https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting

  -h, --help            print this help message'

# acceptable OPTIONS
options=("-m --min-num -t --token")

# define error messages
err_syntax="Syntax error. Type './pulls.sh --help' to see more info"

err_arg_miss="Error: Argument missing."
err_arg_miss="$err_arg_miss Type './pulls.sh --help' to see more info"

err_arg_invalid="Error: Invalid argument."
err_arg_invalid="$err_arg_invalid Type './pulls.sh --help' to see more info"

err_api_rate_limit="Error: API rate limit exceeded. Type './pulls.sh --help'"
err_api_rate_limit="$err_api_rate_limit and note '--token' option"

err_bad_credentials="Error: Bad credentials. Check your personal token."
err_bad_credentials="$err_bad_credentials https://docs.github.com/rest"

err_rep_not_found_start="Error: Repository \""
err_rep_not_found_end="\" not found."

# define default conditions
def_min_num=2 # the minimum number of open PR's to consideration the contributor

# function to print errors to stderr
print_err() {
  printf "%s\n" "$*" >&2;
}

# parse input parameters
# set default values
labels=0
silent="-s"
min_num=$def_min_num
# check arguments
if [ "$#" -eq 0 ]; then
  print_err $err_arg_miss
  exit 1
elif [ "$#" -eq 1 ]; then
# there is only one argument
  if [[ $1 == '-h' || $1 == '--help' ]]; then
    # the only argument is 'help'
    echo "$help"
    exit 0
  else
    # the only argument is repo URL
    if [[ ! "$1" =~ ^"https://github.com/".*"/".* ]]; then
      print_err $1
      print_err $err_arg_invalid
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
    # previous arg is option identifier
      case "${args[${ind} - 1]}" in
        -m|--min-num)
          if [[ ${args[${ind}]} =~ ^[0-9]+$ ]] &&
            [ "${args[${ind}]}" -ge 1 ]; then
            min_num="${args[${ind}]}"
          else
            print_err $err_syntax
            exit 1
          fi
          ((ind++));;
        -t|--token)
          token="${args[${ind}]}"
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
            print_err "${args[${ind}]}"
            print_err $err_arg_invalid
            exit 1
          fi
          input_url="${args[${ind}]}"
        else
        # arg is not last in args - syntax error
          print_err $err_syntax
          exit 1
        fi
      fi
      ((ind++))
    fi
  done
fi

# generate request URL
request_url=$(echo $input_url |
  sed 's/https:\/\/github.com/https:\/\/api.github.com\/repos/')
request_url="${request_url}/pulls?page="

# generate table with raw response
num_of_records=1
table_raw=()
page_num=1
while [[ $num_of_records -gt 0 ]]; do
  if [[ ! -z $token ]]; then
    page_content=$(curl $silent -H "Authorization: token $token" \
      "${request_url}${page_num}")
    if [[ "$(echo "${page_content}" | jq '.[]')" =~ ^"\"Bad credentials".* ]]
    then
      print_err $err_bad_credentials
      exit 1
    fi
    if [[ $(echo "${page_content}" | jq '.[]') =~ ^"\"Not Found\"" ]]; then
      print_err ${err_rep_not_found_start}${input_url}${err_rep_not_found_end}
      exit 1
    fi
    if [[ "$(echo "${page_content}" | jq '.[]')" =~ \
      ^"\"API rate limit exceeded".* ]]
    then
      print_err $err_api_rate_limit
      exit 1
    fi
  else
    page_content=$(curl $silent "${request_url}${page_num}")
    if [[ $(echo "${page_content}" | jq '.[]') =~ ^"\"Not Found\"" ]]; then
      print_err ${err_rep_not_found_start}${input_url}${err_rep_not_found_end}
      exit 1
    fi
    if [[ "$(echo "${page_content}" | jq '.[]')" =~ \
      ^"\"API rate limit exceeded".* ]]
    then
      print_err $err_api_rate_limit
      exit 1
    fi
  fi
  num_of_records=$(echo "$page_content" | jq '. | length' )
  table_raw+=$page_content
  ((page_num++))
done

# print result table function
print_result_table() {
  all_contributors=()
  while IFS= read -r line; do
    all_contributors+=( "$line" )
  done < <(printf "%s\n" "$1" | \
    jq -r '.[].user.login' | sort | uniq -c | sort -k1gr -k2g)
  printf "Contributors with at least %s open pull requests:\n" $min_num
  echo $separator_line
  printf "%-25s | $pr_column_label\n" "User login"
  echo $separator_line
  for line in "${all_contributors[@]}"; do
    if [[ $(echo $line | awk '{print $1}') -ge $min_num ]]; then
      printf "%-25s | $spacer%2s\n" \
        $(echo $line | awk '{printf $2}') $(echo $line | awk '{printf $1}')
        echo $separator_line
    fi
  done
}

# final output
if [ "$labels" -eq 0 ]; then
  separator_line="--------------------------+------"
  pr_column_label="PR's"
  spacer=""
  print_result_table "${table_raw[@]}"
else
  # PR's with labels
  separator_line="--------------------------+------------------"
  pr_column_label="PR's with labels"
  spacer="    "
  prs_with_labels=$(printf "%s\n" "${table_raw[@]}" |
    jq -r '[.[] | select(.labels[].id != null)] | unique')
  print_result_table "${prs_with_labels[@]}"
fi
