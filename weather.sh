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
modold=210 # 3 min 30 seconds
modnew=10  # 10 seconds
modlod=180 # 3 minutes

# tmux: If .cache dir doesn't exist, make it
if [[ ! -d "$cachedir" && "$1" == "-t" ]]; then
    mkdir "$cachedir"
    touch "$cache"
    error=$?
    if [ ! "$error" -eq 0 ]; then
        echo "mkdir $cachedir failed"
        exit $error
    fi
fi

if [ "$1" == "-t" ]; then
    cachemod=$(stat -f%m "$cache") # Mod time of cache in sec since the epoch
    let diff=($time-$cachemod)     # Seconds from now since file was modified

    # First case:  weather called by tmux on startup; assumes this is the case if
    #              file hasn't been used for longer than modold
    # Second case: cache is newly created; should thus be empty
    if [[ diff > modold || diff < modnew ]]
        # TODO: maybe this is a bad idea? delays tmux twice as long
        echo "loading"
  # TODO: IF mod > 3:30 min || < 10 sec from current time
        # display loading
  # TODO: ELIF mod < 3 min
        # load cached version
        # exit
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
        -e 's/<\/b>//' -e 's/<BR \/>//' -e 's/<description>//' \
        -e 's/<\/description>//' | tr -d '\n')
else
    weather=$(curl --silent \
        "http://xml.weather.yahoo.com/forecastrss?p=$zipcode" \
        | grep -E '(Current Conditions:|F<BR)' \
        | sed -e 's/Current Conditions://' -e 's/<br \/>//' -e 's/<b>//' \
        -e 's/<\/b>//' -e 's/<BR \/>//' -e 's/<description>//' \
        -e 's/<\/description>//' | tr -d '\n')
fi
echo "$weather"

# tmux: add weather to cache file
if [ "$1" == "-t" ]; then
    echo "$weather" > "$cache"
fi

