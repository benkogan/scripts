#!/usr/bin/env bash

# By Ben Kogan, http://benkogan.com
# Usage:
#       weather [-t] [-c]
#
# [-t]  for tmux -- uses cache file
# [-c]  check in Celcius; default is Fahrenheit

cachedir="$HOME/scripts/.cache"
cache="$HOME/scripts/.cache/weather.log"
time=$(date +%s)
modold=210 # 03 minutes 30 seconds
modmid=180 # 03 minutes
modnew=10  # 10 seconds

# TODO: fix 2 issues:
#       1. if clauses for mod- aren't working
#       2. read isn't working

if [[ "$1" == "-t" ]]; then

    # tmux: If .cache dir doesn't exist, make it
    if [[ ! -d "$cachedir" ]]; then
        echo "TEST: cache dir created"
        mkdir "$cachedir"
        touch "$cache"
        error=$?
        if [ ! "$error" -eq 0 ]; then
            echo "mkdir $cachedir failed"
            exit $error
        fi
    fi

    cachemod=$(stat -f%m "$cache") # Mod time of cache in sec since the epoch
    let diff=($time - $cachemod)   # Seconds from now since file was modified
    echo "TEST: time is $time, cachemod is $cachemod, diff is $diff seconds"

    # Load cached version
    if [[ diff < modmid ]]; then
        echo "TEST: cache loaded, should exit"
        read weather < $cache
        echo "w: $weather"
        exit $?

    # First case:  on tmux startup; assumes this is the case if cache file
    #              hasn't been used for longer than modold
    # Second case: cache is newly created; should thus be empty
    elif [[ diff > modold || diff < modnew ]]; then
        # TODO: maybe this is a bad idea? delays loading twice as long
        echo "loading"
   fi
fi

# Get zipcode
zipcode=$(curl --silent "http://ipinfo.io/" | grep -E '(postal|})' \
    | sed -e 's/"postal": "//' -e 's/}//' -e 's/"//' | tr -d '\n  ')

# Get weather
if [[ "$2" == "-c" || "$1" == "-c" ]]; then
    weather=$(curl --silent \
        "http://xml.weather.yahoo.com/forecastrss?p=$zipcode&u=c" \
        | grep -E '(Current Conditions:|C<BR)' \
        | sed -e 's/Current Conditions://' -e 's/<br \/>//' -e 's/<b>//' \
        -e 's/<\/b>//' -e 's/C<BR \/>/ºC/' -e 's/<description>//' \
        -e 's/<\/description>//' | tr -d '\n')
else
    weather=$(curl --silent \
        "http://xml.weather.yahoo.com/forecastrss?p=$zipcode" \
        | grep -E '(Current Conditions:|F<BR)' \
        | sed -e 's/Current Conditions://' -e 's/<br \/>//' -e 's/<b>//' \
        -e 's/<\/b>//' -e 's/F<BR \/>/°F/' -e 's/<description>//' \
        -e 's/<\/description>//' | tr -d '\n')
fi
echo "$weather"

# tmux: add weather to cache file
if [ "$1" == "-t" ]; then
    echo "TEST: stores"
    echo "$weather" > "$cache"
fi

