#! /bin/bash

# define "help" message
help=$'usage: ./tuna.sh [OPTIONS] [PROCESS]
Show the names of organizations with which the PROCESS has established a connection.
Examples:
./tuna.sh -m 8 -f connected chrome
./tuna.sh --filter ALL --max_count 5 qbittorrent

PROCESS:\tname or ID of PROCESS being processed. Default "firefox"

OPTIONS:
  -m, --max-count NUM\tmaximum NUM of processed connections. Default 5
  -f, --filter STATE\tuse a filter for proccessed connections STATE. Default "all"

  -h, --help\t\tprint this help message

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
  all\t\tall of the above states.
  connected\tall the states with the exception of listen and closed
  synchronized\tall of the connected states with the exception of syn-sent
  bucket\tstates which are maintained as minisockets, for example time-wait and syn-recv
  big\t\topposite to bucket state'

# difine default parameters
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

# set default values to avoid errors if no arguments passed
proc=${def_proc}
num=${def_num}
state=${def_state}
# check count of arguments
if [ "$#" -eq 1 ]; then
# there is only one argument
  if [[ $1 == '-h' || $1 == '--help' ]]; then
    # the ony argument is 'help'
    echo "$help"
    exit 0
  else
    # the ony argument is PROCESS name or ID
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
    # previous arg is option identifer
      case "${args[${ind} - 1]}" in
        -m|--max-count)
          num="${args[${ind}]}"
          ((ind++));;
        -f|--filter)
          if [[ " ${states[@]} " =~ " ${args[${ind}]} " ]]; then
            state="${args[${ind}]}"
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
        # last arg may be process name or ID
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

sudo ss -tunap state "$state" | awk "/$proc/ {print \$6}" | cut -d: -f1 | sort | uniq -c | sort | tail -n"${num}" | grep -oP '(\d+\.){3}\d+' | while read IP ; do whois $IP | awk -F':' '/^Organization/ {print $2}' ; done
