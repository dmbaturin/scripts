#!/bin/sh

# Try to find out system installation date

# WARNING: it isn't a forensic tool or something,
# as there aren't really immutable entities in
# any system, so any attempt to determine
# installation date is no more than a guess.
#
# It was written for fun and research purposes
# and the only valid use for it is to check
# how old a system running on a dusty server
# in a closet is before shutting it down forever.

# Copyright (C) 2012 Daniil Baturin <daniil at baturin dot org>
#
# Permission is hereby granted, free of charge,
# to any person obtaining a copy of this software
# and associated documentation files (the "Software"),
# to deal in the Software without restriction,
# including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense,
# and/or sell copies of the Software, and to permit persons
# to whom the Software is furnished to do so, subject
# to the following conditions:
#
# The above copyright notice and this permission notice
# shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
# IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
# DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
# TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
# OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

if [ -n "$1" ]; then
    DATE_FORMAT="$1"
else
    DATE_FORMAT="%F"
fi

if [ "$USER" != "root" ]; then
    echo "Some checks require root privileges!"
    exit 1
fi

# Defaults
INSTALL_DATE=Unknown
SOURCE=None

OS=`uname`

result() {
    echo "Installation date: $INSTALL_DATE"
    echo "Information source: $SOURCE"
    exit
}

case "$OS" in
    Linux)
        ## First try "good", distribution
        ## specific methods (installer logs mostly)

        # Debian-based
        if [ -d "/var/log/installer" ]; then
            RAW_DATE=`stat --format "%y" /var/log/installer/`
            INSTALL_DATE=`date -d "$RAW_DATE" +"$DATE_FORMAT"`
            SOURCE="Installer log"
            result
        fi

        # RedHat-based
        if [ -f "/root/install.log" ]; then
           RAW_DATE=`stat --format "%y" /root/install.log`
           INSTALL_DATE=`date -d "$RAW_DATE" +"$DATE_FORMAT"`
           SOURCE="Installer log"
           result
        fi

        ## No luck with good methods.
        ## Try to find out root filesystem creation date,
        ## most likely it's the same to installation date.

        ROOT_DEV=`mount | grep " / " | awk -F' ' '{print $1}'`
        ROOT_OPT=`mount | grep $ROOT_DEV`
        ROOT_FS=`echo $ROOT_OPT | awk -F' ' '{print $5}'`

        if [ ! -z `echo $ROOT_FS | grep "ext"` ]; then
            # ext2/ext3/ext4
            RAW_DATE=`tune2fs -l $ROOT_DEV | grep "Filesystem created" | sed -e 's/Filesystem created:\s\+//'`
            INSTALL_DATE=`date -d "$RAW_DATE" +"$DATE_FORMAT"`
            SOURCE="Filesystem creation date"
            result
        elif [ ! -z `echo $ROOT_FS | grep "jfs"` ]; then
            # JFS
            RAW_DATE=`jfs_tune -l $ROOT_DEV | grep "Filesystem creation" | sed -e 's/Filesystem creation:\s\+//'`
            INSTALL_DATE=`date -d "$RAW_DATE" +"$DATE_FORMAT"`
            SOURCE="Filesystem creation date"
            result
        fi
        ;;

    FreeBSD)
        # Apparently /home -> /usr/home symlink is
        # never changed under normal circumstances,
        # so should be as old as the system itself

        RAW_DATE=`stat -f%m /home`
        INSTALL_DATE=`date -j -f "%s" $RAW_DATE  +"%F"`
        SOURCE="/home symlink"
        result
        ;;

    Darwin)
        # Mac OS X, actually

        if [ -r "/private/var/db/.AppleSetupDone" ]; then
            RAW_DATE=`stat -f%m /private/var/db/.AppleSetupDone`
            INSTALL_DATE=`date -j -f "%s" "$RAW_DATE" +"$DATE_FORMAT"`
            SOURCE=".AppleSetupDone"
            result
        fi
        ;;

    SunOS)
         # SUNWsolnm contains /etc/release and apparently
         # is never updated, so its installation date 
         # should represent system installation date too.

        INSTALL_DATE=`pkginfo -l SUNWsolnm | grep INSTDATE | sed -e 's/\s*INSTDATE:\s*//'`
        SOURCE="SUNWsolnm package"
        result
        ;;

    *)
        echo "Sorry, operating system $OS is not supported"
        exit 1
esac
