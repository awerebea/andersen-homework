#! /bin/bash

# define "help" message
help=$'usage: ./volatility.sh [OPTIONS] [DATABASE]
Download the DATABASE if the file does not exist in the path.
Show the value of the minimum volatility of the euro for the selected MONTH for
years in the range starting from YEAR.
Examples:
./volatility.sh -m 3 -y 2015 quotes.json
./volatility.sh --year 2017 --month 11 \'../quotes.json\'

DATABASE: relative path of DATABASE file being processed. Default "quotes.json"

OPTIONS:
  -m, --month NUM   month in num [0]1-12 format. Default 3
  -y, --year NUM    year in YYYY format. Default 2015

  -h, --help        print this help message'

# acceptable OPTIONS
options=("-m --month -y --year")

# define syntax error message
error="Syntax error. Type './volatility.sh --help' to see more info"

# difine default conditions
def_db_path="quotes.json"   # name of JSON database file
def_min_year=2015           # start year of statistical calculations
def_month=03                # select month

# parse input parameters
# set default values to avoid errors if no arguments passed
db_path=${def_db_path}
min_year=${def_min_year}
month=${def_month}
# check count of arguments
if [ "$#" -eq 1 ]; then
# there is only one argument
  if [[ $1 == '-h' || $1 == '--help' ]]; then
    # the ony argument is 'help'
    echo "$help"
    exit 0
  else
    # the ony argument is db_path
    db_path=$1
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
        -m|--month)
          if [[ ${args[${ind}]} =~ ^[0-9]+$ ]] && \
            [ "${args[${ind}]}" -ge 1 ] && [ "${args[${ind}]}" -le 12 ]; then
            month=$(echo "${args[${ind}]}" | awk '{printf "%02d\n", $0}')
          else
            echo "Date error: month ${args[${ind}]}"
            exit 1
          fi
          ((ind++));;
        -y|--year)
          if [[ ${args[${ind}]} =~ ^[0-9]+$ && ${#args[${ind}]} -eq 4 ]];
          then
            min_year="${args[${ind}]}"
          else
            echo "$error"
            exit 1
          fi
          ((ind++));;
      esac
      prev_arg_is_key=false
    else
    # previous arg is option value (or current arg is the first)
      if [[ " ${options[@]} " =~ "${args[${ind}]}" ]]; then
      # the arg is acceptable option key
        prev_arg_is_key=true
      else
        if [ $ind -eq $(($#-1)) ]; then
        # last arg may be db_path
          proc="${args[${ind}]}"
        else
        # arg is not last in args - syntax error
          echo "$error"
          exit 1
        fi
      fi
      ((ind++))
    fi
  done
fi

# check if db file exist and download it if not
if [[ ! -f "$db_path" ]]; then
  curl -s https://yandex.ru/news/quotes/graph_2000.json > $db_path
fi

# create table with raw 'jq' output
raw_table=()
while IFS= read -r line; do
  raw_table+=( "$line" )
done < <( jq -r '.prices[][]' $db_path | awk 'NR%2 {$1 = $1/1000} {print}' )
# DEBUG print
# printf '%s\n' "${raw_table[@]}"

# create table with dates in human readable format
dates_table=()
while IFS= read -r line; do
  tmp_table+=( "$line" )
done < <(printf '%s\n' "${raw_table[@]}'" | awk 'NR%2 {print $1}' | jq todate)
# DEBUG print
# printf '%s\n' "${dates_table[@]}"

# chage date lines in the table to human readable
i=0
j=0
for line in "${raw_table[@]}"; do
  if [ $((i % 2)) -eq 0 ]; then
    raw_table[i]=${tmp_table[j]}
    ((j+=1))
  fi
  ((i+=1))
done

# table 'date value'
table=()
while IFS= read -r line; do
  table+=( "$line" )
done < <( printf '%s\n' "${raw_table[@]}" | \
  awk '{if (e) {print p" "$0;} else {p=$0;} e=!e;}' )
# DEBUG print
# printf '%s\n' "${table[@]}"

# get years from db starting from `min_year`
years=()
while IFS= read -r line; do
  if [ $((line)) -ge $((min_year)) ]; then
    years+=( "$line" )
  fi
done < <(printf '%s\n' "${table[@]}'" | awk '{print substr($1,2,4)}' | sort -u)
# DEBUG print
# printf '%s\n' "${years[@]}"

# # calculate pair 'year volatility' with min volatility
# min_volatility_pair=$( for year in "${years[@]}"; do
#   stddev_tmp=$(printf '%s\n' "${table[@]}'" | \
#     awk "/\"$year-$month/ {print \$2}")
#       if  [[ ! -z $stddev_tmp ]]; then
#         volatility=$(printf '%s\n' "$stddev_tmp'" | \
#           awk '{x+=$0;y+=$0^2}END{print sqrt(y/NR-(x/NR)^2)*sqrt(252/12)}' | \
#           awk '{printf "%.4f\n", $1}')
#         printf '%s %s\n' "$year" "$volatility"
#       fi
#     done | LC_ALL=C sort -rg -k2 | tail -n 1 )
# # DEBUG print
# # echo $min_volatility_pair

# # final output
# printf "The %s with min volatility (%s) was in %s\n" \
#   $(LC_ALL=us_EN.utf8 date -d "$month/01" +"%B") \
#   $(echo $min_volatility_pair | awk '{printf $2}') \
#   $(echo $min_volatility_pair | awk '{printf $1}')

# calculate table with pairs 'year volatility'
volatility_table=()
for year in "${years[@]}"; do
  stddev_tmp=$(printf '%s\n' "${table[@]}'" | \
    awk "/\"$year-$month/ {print \$2}")
      if  [[ ! -z $stddev_tmp ]]; then
        volatility=$(printf '%s\n' "$stddev_tmp'" | \
          awk '{x+=$0;y+=$0^2}END{print sqrt(y/NR-(x/NR)^2)*sqrt(252/12)}' | \
          awk '{printf "%.4f\n", $1}')
        volatility_table+=( "$year $volatility" )
        if [ $year -eq $min_year ]; then
          volatility_min=$volatility
          volatility_min_year=$year
        elif [ $(bc <<< "$volatility < $volatility_min") -eq 1 ]; then
          volatility_min=$volatility
          volatility_min_year=$year
        fi
      fi
done
# DEBUG print
# printf '%s\n' "${volatility_table[@]}"

# final output
printf "Volatility for $(tput bold)$(tput setaf 3)%s$(tput sgr0) by years:\n" \
  $(LC_ALL=us_EN.utf8 date -d "$month/01" +"%B")
for line in "${volatility_table[@]}"; do
  if [ $(echo $line | awk '{print $1}') -eq $volatility_min_year ]; then
    printf "$(tput bold)$(tput setaf 2)%s - %s$(tput sgr0)\n" \
      $(echo $line | awk '{printf $1}') $(echo $line | awk '{printf $2}')
  else
    printf "%s - %s\n" \
      $(echo $line | awk '{printf $1}') $(echo $line | awk '{printf $2}')
  fi
done
