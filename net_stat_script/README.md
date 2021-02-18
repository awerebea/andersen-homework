## tuna.sh
Script shows the names of organizations with which the PROCESS has established a connection.
### Usage
`$ ./tuna.sh [OPTIONS] [PROCESS]`
### Examples:
```
$ ./tuna.sh -m 8 -f connected chrome
$ ./tuna.sh --filter ALL --max_count 5 qbittorrent
```
### Available parameters:
```
PROCESS             the name or ID of process being processed.

-m, --max-count NUM maximum NUM of processed connections.
-f, --filter STATE  use a filter for proccessed connections STATE.

-h, --help\t\tprint this help message
```
### Available all standard TCP STATEs:
```
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
```
### Other available STATE identifiers:
```
all           all of the above states.
connected     all the states with the exception of listen and closed
synchronized  all of the connected states with the exception of syn-sent
bucket        states which are maintained as minisockets, for example time-wait and syn-recv
big           opposite to bucket state
```
### Default values (used if the script is run without parameters at all)
```
Process "firefox"
--max-count 5
--filter "all"
```
