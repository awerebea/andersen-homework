#! /bin/bash

set -o pipefail

# define "help" message
help=$'usage: ./tuna.sh [OPTIONS] [PROCESS]
Show the names of organizations with which the PROCESS has established
a connection.
Examples:
./tuna.sh -m 8 -f connected chrome
./tuna.sh --filter ALL --max-count 5 qbittorrent

PROCESS:                name or ID of PROCESS being processed. Default "firefox"

OPTIONS:
  -m, --max-count NUM   maximum NUM of processed connections. Default 5
  -f, --filter STATE    use a filter for proccessed connections STATE.
                        Default "all"

  -h, --help            print this help message

Available all standard TCP STATEs:
  established
  syn-sent
  syn-recv
  fin-wait-1
  fin-wait-2
  time-wait
  closed
  close-wait
  last-ack
  listening
  closing

Other available STATE identifiers:
  all               all of the above states.
  connected         all the states with the exception of listen and closed
  synchronized      all of the connected states with the exception of syn-sent
  bucket            states which are maintained as minisockets,
                    for example time-wait and syn-recv
  big               opposite to bucket state'

# define default parameters
# acceptable OPTIONS
options=("-m --max-count -f --filter")

# acceptable connection STATEs
states="established syn-sent syn-recv fin-wait-1 fin-wait-2 time-wait"
states="${states} closed close-wait last-ack listening closing"
states="${states} all connected synchronized bucket big"

# process name
def_proc="firefox"

# max-count of processed connections
def_num=5

# state
def_state="all"

# define syntax error message
error="Syntax error. Type './tuna.sh --help' to see more info"

# get number of elements
ELEMENTS=${#args[@]}

# function to print errors to stderr
print_err() {
  printf "%s\n" "$*" >&2;
}

# parse input parameters
# set default values to avoid errors if no arguments passed
proc=${def_proc}
num=${def_num}
state=${def_state}
# check count of arguments
if [ "$#" -eq 1 ]; then
# there is only one argument
  if [[ $1 == '-h' || $1 == '--help' ]]; then
    # the only argument is 'help'
    echo "$help"
    exit 0
  else
    # the only argument is PROCESS name or ID
    proc=$1
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
        -m|--max-count)
          if [[ ${args[${ind}]} =~ ^[0-9]+$ ]] && [ "${args[${ind}]}" -ge 1 ]
          then
            num="${args[${ind}]}"
          else
            print_err $error
            exit 1
          fi
          ((ind++));;
        -f|--filter)
          if [[ " ${states[@]} " =~ " ${args[${ind}],,} " ]]; then
            state="${args[${ind}]}"
          else
            print_err $error
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
        # last arg may be process name or ID
          proc="${args[${ind}]}"
        else
        # arg is not last in args - syntax error
          print_err $error
          exit 1
        fi
      fi
      ((ind++))
    fi
  done
fi

# create table with raw 'ss' output
raw_table=()
while IFS= read -r line; do
  raw_table+=( "$line" )
done < <( ss -tunap state $state )

# filter raw table by "process NAME" OR pid=PID
filtered_table=()
processes_list=()
for line in "${raw_table[@]}"; do
  process=$(echo $line | awk "{print \$7}" | awk "/\".*$proc.*\"|pid=.*$proc/")
  IP=$(echo $line | awk "!/[*]/ {print \$6}")
  if [[ ! -z $process && ! -z $IP ]]; then
    filtered_table+=( "$line" )
    processes_list+=( $(echo $process | sed 's/[^"]*"\([^"]*\)".*/\1/') )
  fi
done

# create table of Peer ip addresses with connections count
ip_table=()
while IFS= read -r line; do
  ip_table+=( "$line" )
done < <( printf '%s\n' "${filtered_table[@]}" | awk "{print \$6}" |
  grep -E '.*[0-9]{1,4}(\.|\:).*' | sed 's/\(.*\)\:.*/\1/' |
  tr -d '[]' | sort | uniq -c | sort -r | head -n$num )

# final output
separator_line="--------------------------------------------------------+"
separator_line="$separator_line--------------------"
printf "Processes with a name/ID that matches the pattern \
\"$(tput bold)$(tput setaf 2)${proc}$(tput sgr0)\":\n"
printf "$(tput setaf 2)%s$(tput sgr0)\n" "${processes_list[@]}" | sort | uniq
echo $separator_line
printf "%-55s | Num of connections\n" \
  "Organization name with established connection"
echo $separator_line
for line in "${ip_table[@]}"; do
  connections_num=$(echo $line | cut -f1 -d' ')
  IP=$(echo $line | cut -f2 -d' ')
  organization=$(whois $IP |
    awk -F':' '/^[Oo]rganization|^[Oo]rganisation|^[Rr]ole/ {print $2}' |
    awk '{$1=$1};1' | tail -n1)
    echo $organization |
      awk 'length > 52{$0 = substr($0, 1, 52) "..."} {printf "%-55s", $0}'
    printf " |        %2s\n" "$(echo $connections_num)"
echo $separator_line
done
