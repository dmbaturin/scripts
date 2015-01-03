#!/bin/sh

# In the perfect world, all academic papers 
# are in standards-compliant PDF with proper metadata.
# In practice they come in all sizes and shapes:
# PostScript, DVI, or gzipped versions of those.
# This script homogenizes a directory with papers
# by converting them all to PDFs
#
# This file is public domain.

convert_all()
{
    SUFFIX=$1
    CONVERTOR=$2

    PATTERN="s/\.$SUFFIX$/\.pdf/"

    find . -type f -name "*.$SUFFIX" -print0 | while read -d $'\0' FILENAME; do
        PDFNAME=$(echo $FILENAME | sed -e $PATTERN)
        echo "$FILENAME -> $PDFNAME"
        $CONVERTOR $FILENAME $PDFNAME
    done

    find . -type f -name "*.$SUFFIX" -delete
}

find . -type f -name "*.gz" | xargs gunzip

convert_all ps ps2pdf
convert_all dvi dvipdf
