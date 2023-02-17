# swartz
A simple script for scraping and monitoring webpages for content updates.

## Usage:
```
  ./swartz.sh url_to_check [-u | --update-all] [--help]
```

## Example commands and outputs:
```
$ ./swartz.sh https://j9s.io
URL added to monitoring.

$ ./swartz.sh https://cageworkorange.com
URL added to monitoring.

$ ./swartz.sh https://cageworkorange.com
URL monitored - content has not changed.

$ ./swartz.sh https://j9s.io
URL monitored - content has changed.
Content hash updated in hash_cache.

$ ./swartz.sh -u
Refreshing all cached URLs...
Refreshing https://cageworkorange.com
URL monitored - content has not changed.
Refreshing https://j9s.io
URL monitored - content has changed.
Content hash updated in hash_cache.
```
