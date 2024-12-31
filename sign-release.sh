#!/bin/bash
# Copyright (C) 2024 Daniil Baturin
#
# A script for signing all files in an S3 bucket with
# GnuPG and minisign
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

BUCKET=$1

if [ -z $BUCKET ]; then
    echo "Usage: $0 <S3 bucket with release files>"
    exit 1
fi

read -s -p 'Enter minisign password: ' MINISIGN_KEY_PW


S3_FILES=$(s3cmd ls -r $BUCKET | grep -v '.asc' | grep -v '.minisig' | grep -v 'raw' |  awk -F ' ' '{print $4}')

for s3_file in $S3_FILES; do
    s3cmd get $s3_file
    file_name=$(echo $s3_file | awk -F '/' '{print $NF}')
    gpg -ab $file_name
    MINISIGN_PASSWORD=$MINISIGN_KEY_PW minisign -SHm $file_name
    s3cmd put $file_name.asc $s3_file.asc
    s3cmd put $file_name.minisig $s3_file.minisig
    rm $file_name
    rm $file_name.asc
    rm $file_name.minisig
done
