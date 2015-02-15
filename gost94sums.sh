#!/bin/sh
# In Soviet Russia source code adds license headers to you!!
# Uhm, I mean, this file is public domain.

files=`find . -maxdepth 1 -name "*.*" -type f`

for i in $files; do
    file=`echo $i | awk -F '/' '{print $2}'`
    echo `openssl dgst -md_gost94 $file | awk -F ' ' '{print $2}'` $file >> gost94sums
done
