#! /bin/bash

# define "help" message
help=$'usage: ./volatility.sh [OPTIONS] [DATABASE]
Download the DATABASE if the file does not exist in the path.
Show the value of the minimum volatility of the euro for the selected MONTH for
years in the range starting from YEAR.
Examples:
./volatility.sh -m 03 -2015 quotes.json
./volatility.sh --year 2017 --month 11 \'../quotes.json\'

DATABASE: relative path of DATABASE file being processed. Default "quotes.json"

OPTIONS:
  -m, --month MM    month in MM format. Default 03
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
          if [[ ${args[${ind}]} =~ ^[0-9]+$ && ${#args[${ind}]} -eq 2 ]];
          then
            month="${args[${ind}]}"
          else
            echo "$error"
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
done < <( jq -r '.prices[][]' $db_path )

# DEBUG print
# printf '%s\n' "${raw_table[@]}"

# save data in hashmap
i=0
declare -A values_map
for line in "${raw_table[@]}"; do
  if [ $((i % 2)) -eq 0 ]; then
    v_date=$(date --date=@$((line / 1000)) +%Y%m%d)
  elif [ $((i % 2)) -eq 1 ]; then
    values_map[$v_date]=$line
  fi
  ((i+=1))
done

# get years from db starting from `min_year`
years=()
while IFS= read -r line; do
  if [ $((line)) -ge $((min_year)) ]; then
    years+=( "$line" )
  fi
done < <((for v_date in "${!values_map[@]}"
do
  echo "$v_date ${values_map[$v_date]}"
done;) | awk '{print substr($1,1,4)}' | sort -u)

# DEBUG print
# printf '%s\n' "${years[@]}"

# filter month
filter_month () {
  stat_month=()
  while IFS= read -r line; do
    stat_month+=( "$line" )
    echo $line
  done < <(for v_date in "${!values_map[@]}"
do
  echo "$v_date ${values_map[$v_date]}"
done;) | grep ${year}${month} | sort
}

# calculate mean values for selected month of each year
for year in "${years[@]}"; do
  stats[$year]=$(filter_month)
  mean[$year]=0
  count=0
  if [[ ${#stats[$year]} -gt 0 ]]; then
    # calculate min, mean and max values in month
    while IFS= read -r line; do
      mean[$year]=$(echo ${mean[$year]} + $line | bc)
      ((count++))
    done < <( printf '%s\n' "${stats[${year}]}" | awk '{print $2}' )
    mean[$year]=$(echo "scale=4; ${mean[$year]} / $count" | bc)
    # DEBUG print
    printf "$year.$month  mean %s\n" ${mean[$year]}
  fi
done

# calculate standard deviation
for year in "${years[@]}"; do
  std_deviation[$year]=0
  count=0
  if [[ ${#stats[$year]} -gt 0 ]]; then
    # calculate min, mean and max values in month
    while IFS= read -r line; do
      sq_deviation_day=$(echo "scale=4; $line - ${mean[$year]}" | bc)
      # DEBUG print
      # printf "$year.$month  day value $line  mean ${mean[$year]}  \
      #   deviation day $sq_deviation_day\n"
      std_deviation[$year]=$(echo "scale=4; ${std_deviation[$year]} + \
        $sq_deviation_day ^ 2" | bc)
      ((count++))
    done < <( printf '%s\n' "${stats[${year}]}" | awk '{print $2}' )
    # DEBUG print
    # printf "$year.$month count $count std deviation $year \
    #   ${std_deviation[$year]}\n"
    std_deviation[$year]=$(echo "scale=4; sqrt ( ${std_deviation[$year]} / \
      $count )" | bc)
    # DEBUG print
    # printf "$year.$month  standart deviation %s\n" ${std_deviation[$year]}
  fi
done

# calculate historical volatility for selected month of each year
# and get min of them
min_volatility=0
min_volatility_year=0
count=0
for year in "${years[@]}"; do
  if [[ ${#stats[$year]} -gt 0 ]]; then
    volatility[$year]=$(echo "scale=4; sqrt ( 252 / 12 ) * \
      ${std_deviation[$year]}" | bc)
    if [ $count -eq 0 ]; then
      min_volatility=${volatility[$year]}
      min_volatility_year=$year
    else
      if (( $(echo "${volatility[$year]} < $min_volatility" | bc) )); then
        min_volatility=${volatility[$year]}
        min_volatility_year=$year
      fi
    fi
    # DEBUG print
    # printf "$year.$month  volatility %s\n" ${volatility[$year]}
  fi
  ((count++))
done

# final output
printf "The %s with min volatility (%s) was in %s\n" \
  $(LC_ALL=us_EN.utf8 date -d "1900-$month-01" +"%B") \
  $min_volatility $min_volatility_year
