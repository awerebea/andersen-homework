## pulls.sh
The script checks for open pull requests for the GitHub repository and displays its top contributors.
### Info
The `curl` utility is used to fetch data from the GitHub API, the `jq` utility is used to parse the extracted JSON data.
### Usage
`$ ./pulls.sh [OPTIONS] REPO_URL`
### Examples:
```
./pulls.sh --min-num 4 --verbose https://github.com/torvalds/linux
./pulls.sh --min-num 1 https://github.com/EbookFoundation/free-programming-books
./pulls.sh -m 1 -l https://github.com/EbookFoundation/free-programming-books
./pulls.sh --labels -v -m 3 https://github.com/facebook/react
```
### Available parameters:
```
REPO_URL: required argument, URL of the GitHub repository in format 'https://github.com/$user/$repo'

OPTIONS:
  -m, --min-num NUM     consider contributors with a minimum NUM of open
                        pull requests. Default 2

  -l, --labels          only count pull requests with labels

  -v, --verbose         display the progress of fetching pages with data

  -t, --token TOKEN     GitHub personal TOKEN for authentication and increasing
                        the API request limit from 60 to 5000 per hour.


  -h, --help            print this help message
```
For more info about authentication and rate limits, visit:<br/>
[https://docs.github.com/en/rest/guides/getting-started-with-the-rest-api#authentication](https://docs.github.com/en/rest/guides/getting-started-with-the-rest-api#authentication)<br/>
[https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting](https://docs.github.com/rest/overview/resources-in-the-rest-api#rate-limiting)
