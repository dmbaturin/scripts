#!/bin/bash

## Mail yesterday irssi logs to watchers
#
# Copyright (c) 2012 Daniil Baturin <daniil at baturin dot org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

## Configuration, please edit

# irssi log dir (autolog_path = )
LOG_DIR="/home/jrandomhacker/.irssi/logs/netname"

# Log files, space separated (typically $channel.log)
LOG_FILES="#ircjerks.log"

# Temporary files dir
TMP_DIR=/tmp

# Watchers' email addresses, space separated
WATCHERS="jrandomhacker@example.org jcertainuser@example.net"

# Date format should match that in log_close_string
DATE_FORMAT="%b %d %Y" # Jun 4 2012


## The rest, do not edit if not sure

START=$(date -d yesterday +"$DATE_FORMAT")
END=$(date +"$DATE_FORMAT")

# Check if mutt is installed
if [ ! -x $(which mutt) ]; then
    echo "Error: mutt mail client is not installed!"
    exit 1
fi

for file in "$LOG_FILES"; do
    THIS=$LOG_DIR/$file
    START_LINE=$(cat -n "$THIS" | grep -e "$START" | awk -F ' ' '{print $1}')
    STOP_LINE=$(cat -n "$THIS" | grep -e "$END" | awk -F ' ' '{print $1}')
    LINES=$(wc -l "$THIS"|awk -F ' ' '{print $1}')
    TMP_FILE=$TMP_DIR/$file-$(date +%d%m)

    # Grab everything between yesterday and today day change line,
    # remove service messages (they start with timestamp and "-!-"
    tail -n $(($LINES-$START_LINE+1)) "$THIS" | head -n $(($STOP_LINE-$START_LINE+1)) \
    | grep -vPe '^[0-9]{2}:[0-9]{2}-\!-' > $TMP_FILE

    # Remove extension
    LOG_NAME=$(echo $file | sed -e s/\\..*//)

    for address in "$WATCHERS"; do
       mutt -s "$LOG_NAME IRC log $(date +"%b %d %Y")" $address < $TMP_FILE
    done

    rm -f $TMP_FILE
done

