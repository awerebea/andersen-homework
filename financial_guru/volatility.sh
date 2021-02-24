#! /bin/bash

# define "help" message

# difine conditions
db_name="quotes.json"   # name of JSON database file
min_year=2015           # start year of statistical calculations
month=03                # select month

# create table with raw 'jq' output
raw_table=()
while IFS= read -r line; do
  raw_table+=( "$line" )
done < <( jq -r '.prices[][]' $db_name )

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

# calculate min, mean and max values for selected month of each year
for year in "${years[@]}"; do
  stats[$year]=$(filter_month)
  mean[$year]=0
  count=0
  if [[ ${#stats[$year]} -gt 0 ]]; then
    # calculate min, mean and max values in month
    while IFS= read -r line; do
      if [ $count -eq 0 ]; then
        min[$year]=$line
        max[$year]=$line
      else
        if (( $(echo "$line < ${min[$year]}" | bc) )); then
          min[$year]=$(echo "$line" | awk '{printf "%.4f", $0}')
        fi
        if (( $(echo "$line > ${max[$year]}" | bc) )); then
          max[$year]=$(echo "$line" | awk '{printf "%.4f", $0}')
        fi
      fi
      mean[$year]=$(echo ${mean[$year]} + $line | bc)
      ((count++))
    done < <( printf '%s\n' "${stats[${year}]}" | awk '{print $2}' )
    mean[$year]=$(echo "scale=4; ${mean[$year]} / $count" | bc)
    # DEBUG print
    # printf "$year.$month  min %s\tmean %s\tmax %s\n" \
    #   ${min[$year]} ${mean[$year]} ${max[$year]}
  fi
done

# calculate volatility for selected month of each year, and get min of them
min_volatility=0
min_volatility_year=0
count=0
for year in "${years[@]}"; do
  if [[ ${#stats[$year]} -gt 0 ]]; then
    volatility[$year]=$(echo "scale=4; ((${mean[$year]} - ${min[$year]}) + \
      (${max[$year]} - ${mean[$year]})) / 2" | bc | awk '{printf "%.4f", $0}')
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

# DEBUG print
# printf "min_volatility %s in year %s\n" $min_volatility $min_volatility_year

# final output
printf "The %s with min volatility (%s) was in %s\n" \
  $(LC_ALL=us_EN.utf8 date -d "1900-$month-01" +"%B") \
  $min_volatility $min_volatility_year
