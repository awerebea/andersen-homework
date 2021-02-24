## volatility.sh
The script downloads the database of historical quotes for EUR/RUB pair since late November 2014 and shows the value of the minimum volatility for the selected month for years in the range starting from selected year.
### Info
The `jq` utility was used to parse JSON database.
### Usage
`$ ./volatility.sh [OPTIONS] [DATABASE]`
### Examples:
```
./volatility.sh -m 03 -2015 quotes.json
./volatility.sh --year 2017 --month 11 \'../quotes.json\'
```
### Available parameters:
```
DATABASE: relative path of DATABASE file being processed.

OPTIONS:
  -m, --month MM    month in MM format.
  -y, --year NUM    year in YYYY format.

  -h, --help        print this help message'
```
### Default values (used if the script is run without parameters at all)
```
Database relative path "quotes.json"
--month 03
--year 2015
```

## Addition requirement for the subject:
```
- remove the `grep -oP '\d+\.\d+'` part, do the same thing without any pattern matching
```
I suggest to use `sed -n 'n;p'` instead, to filter the output of only even lines.
Changed one-liner would be:
```sh
jq -r '.prices[][]' quotes.json | sed -n 'n;p' | tail -n 14 | awk -v mean=0 '{mean+=$1} END {print mean/14}'
```
