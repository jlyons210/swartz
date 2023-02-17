#!/usr/bin/env bash

## swartz.sh - Did a webpage change? Named after Aaron Swartz.
## This script will poll a specified URL and do its very best to strip as much
## markup as possible, and create a SHA256 checksum on first poll. On
## subsequent polls, it will compare the new checksum against the cached
## checksum, and report whether or not there is a difference since the prior
## check, finally updating the cache.

## Check dependencies
if ! ./util-check-dependency.sh curl sha256sum basename; then exit 1; fi

## Set globals
LOGFILE="$(basename -- "${0%.*}").log"

## Check that a URL is provided
if [[ $# -eq 0 || "$1" == "--help" ]]; then

    >&2 echo "Usage:"
    >&2 echo "  $0 url_to_check [-u] [-r url_to_remove] [--help]"
    exit 1

fi

## Check all cached URLs
if [[ "$1" == "-u" ]]; then

    echo "Refreshing all cached URLs..."
    echo -e "$(date -uI's')|updateall|*" >> $LOGFILE

    for url in $(cat hash_cache | cut -f2); do
    
        echo "Refreshing $url"
        $0 $url
    
    done

    exit 0

fi

## Remove URL from cache
if [[ "$1" == "-r" ]]; then

    if [[ "$2" == "" ]]; then

        >&2 echo "Must provide a URL to remove when using the -r argument."
        exit 1

    else

        url=$2
        echo "Removing URLs from cache..."
        grep -i $url hash_cache | cut -f2
        grep -v $url hash_cache >> hash_cache.updated
        rm hash_cache
        mv hash_cache.updated hash_cache
        echo "$(date -uI's'|remove|$url" >> $LOGFILE
        exit 0

    fi

fi

## Validate URL
regex_url='(https?|ftp|file)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'
url=$1
if ! [[ $url =~ $regex_url ]]; then

    >&2 echo "URL is invalid"
    exit 1

fi

## Import user agent from config file
user_agent=$(grep -i user_agent config | cut -d= -f2)
strip_markup=$(grep -i strip_markup config | cut -d= -f2)

## curl the webpage, get hash - strip markup if configured to
if [[ "$strip_markup" == "yes" ]]; then

    page_text=$(curl -sA $user_agent $url | sed -E 's/<[^>]*>//g' | tr -d "\r")

else

    page_text=$(curl -sA $user_agent $url | tr -d "\r")

fi

page_hash=$(echo $page_text | sha256sum | tr -d "\n *-")
echo "$(date -uI's'|query|$url" >> $LOGFILE

## Check for previous page lookup in hash_cache
cache_hit=$(grep -i $url hash_cache 2> /dev/null)

if [[ "$cache_hit" == "" ]]; then

    ## Cache miss
    echo -e "$page_hash\t$url" >> hash_cache
    >&2 echo "URL added to monitoring."
    echo "$(date -uI's'|add|$url" >> $LOGFILE
    exit 0

else

    ## Cache hit
    cache_hash=$(echo $cache_hit | cut -d' ' -f1)

    if [[ "$page_hash" == "$cache_hash" ]]; then
    
        ## URL content hash equals cached hash
        >&2 echo "URL monitored - content has not changed."
        exit 0

    else
    
        >&2 echo "URL monitored - content has changed."
        
        ## Update cache
        grep -v $url hash_cache >> hash_cache.updated
        echo -e "$page_hash\t$url" >> hash_cache.updated
        rm hash_cache
        mv hash_cache.updated hash_cache
        echo "$(date -uI's'|update|$url" >> $LOGFILE

        >&2 echo "Content hash updated in hash_cache."
        exit 0

    fi

fi