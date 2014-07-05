#!/usr/bin/perl

# One-time pad generator

# Copyright (c) 2011 Daniil Baturin <daniil@baturin.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies
# or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
# INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
# PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
# FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
# ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

use Getopt::Long;
use MIME::Base64;

###################### Settings ############################
############################################################

# The following settings define page look,
# feel free to change them

#################### LaTeX settings ########################

# Text inserted after any data line
$TEX_LINE_BREAK = " \\\\\n";

# Text inserted before new page
$TEX_PAGE_BREAK = "\\pagebreak\n";

# Page tempate
# _SERIAL_ is replaced with page serial number,
# _DATA_ is replaced with key data
$TEX_PAGE = <<END;
\\begin{center}
SERIAL: _SERIAL_ \\\\
\\ \\\\
_DATA_
\\ \\\\
DESTROY IMMEDIATELY AFTER USE
\\end{center}

END

# Text inserted before all generated data
$TEX_BEGIN = <<END;
\\documentclass[a4paper,10pt]{article}
\\usepackage[utf8x]{inputenc}

\\begin{document}
\\pagestyle{empty}
\\ttfamily

END

# Text inserted after all data
$TEX_END = <<END;

\\end{document}
END

#################### Plaintext settings #####################

$TXT_LINE_BREAK = "\n";

$TXT_PAGE_BREAK = "-------------\n";

$TXT_PAGE = <<END;
SERIAL: _SERIAL_

_DATA_

DESTROY IMMEDIATELY AFTER USE

END

$TXT_BEGIN = "";

$TXT_END = "";

##################### Other settings #######################

# Whether to use insecure deletion command (rm)
$USE_RM = 0;

############################################################

$help = <<END;
Usage: $0 --in=<FILE> --out=<FILE> --group-width=<NUM> --page-width=<NUM> 
          --page-height=<NUM> --pages=<NUM> --plain-text --keep-source

--in=<FILE>           File to be used as randomness source. On Linux typically /dev/random (secure)
                      or /dev/urandom (insecure).
                      Default is /dev/urandom.

--out=<FILE>          Output file name
                      If --plain-text option is not specified
                      .pdf extension will be added automatically.
                      This option is mandatory.

--group-width=<NUM>   Size of numbers group. Default is 5.

--page-width=<NUM>    Page width in groups. Default is 8.

--page-height=<NUM>   Page height in lines. Default is 16.

--pages=<NUM>         Number of pages. Default is 100.

--plain-text          Produce plaintext output instead of PDF
                      (does not require pdflatex).
                      Default is to use LaTeX.

--keep-source         Do not remove LaTeX source before quit.

Report bugs and suggestions to daniil\@baturin.org
Distributed under terms of MIT license.
END

## Check options and dependencies

if ($#ARGV < 0) { # No arguments given
    print $help;
    exit(0);
}

GetOptions(
    "in=s"             => \$inputFile,
    "out=s"            => \$outputFile,
    "group-width=s"    => \$groupWidth,
    "page-width=s"     => \$pageWidth,
    "page-height=s"    => \$pageHeight,
    "pages=s"          => \$pages,
    "plain-text"       => \$plaintext,
    "keep-source"      => \$keepsource,
    "debug"            => \$debug
);

# Check options

die("Error: Input file $inputFile does not exist or is not readable!\n") unless !defined($inputFile) || (-r $inputFile);
die("Error: Output file $outputFile is not writable!\n") if (-e $outputFile && !-w $outputFile);
if (!defined($plaintext)) {
    # LaTeX uses file.tex if both file.tex and file exist
    die("Error: Output file $outputFile.tex already exists!\n") if (-e $outputFile.".tex");
}
die("Error: Group width is not a positive number!") unless !defined($groupWidth) || ($groupWidth > 0);
die("Error: Page width is not a positive number!") unless !defined($pageWidth) || ($pageWidth > 0);
die("Error: Page height is not a positive number!") unless !defined($pageWidth) || ($pageHeight > 0);
die("Error: Number of pages is not positive!") unless !defined($pages) || ($pages > 0);

# Set defaults

$inputFile = "/dev/urandom" unless defined $inputFile;

if (!defined($groupWidth)) {
    $groupWidth = 5;
}

if (!defined($pageWidth)) {
    $pageWidth = 8;
}

if (!defined($pageHeight)) {
    $pageHeight = 16;
}

if (!defined($pages)) {
    $pages = 100;
}

# Check for OpenSSL binary
system("which openssl 2>&1 >/dev/null");
die("Error: OpenSSL is not installed or is not in your PATH!") unless $? == 0;

# Check for pdflatex
system("which pdflatex 2>&1 >/dev/null");
if ($? != 0) {
    die("Error: pdflatex is not installed or is not in your PATH!") unless defined($plaintext);
}

# Check for shred
system("which shred 2>&1 >/dev/null");
if ($? != 0) {
  print "Warning: secure deletion tool (shred) is not available!";
  $USE_RM = 1;
}

# Set output templates
if ($plaintext) {
    $LINE_BREAK = $TXT_LINE_BREAK;
    $PAGE_BREAK = $TXT_PAGE_BREAK;
    $PAGE = $TXT_PAGE;
    $BEGIN = $TXT_BEGIN;
    $END = $TXT_END;
} else {
    $LINE_BREAK = $TEX_LINE_BREAK;
    $PAGE_BREAK = $TEX_PAGE_BREAK;
    $PAGE = $TEX_PAGE;
    $BEGIN = $TEX_BEGIN;
    $END = $TEX_END;
}

## Obtain random data

if ($inputFile eq "/dev/urandom") {
    print "Warning: Using insecure random number generator! \
    \
    /dev/urandom is fast, but potentially insecure. \
    If you need nearly perfect security you should use /dev/random that \
    produces truly random numbers gathered from external sources such as \
    disk, keyboard or mouse usage so generation process may take hours or \
    even days depending on data size.\n\n";
}

# Add $pages extra lines to pick page serial numbers from
$size = ($groupWidth * $pageWidth * $pageHeight * $pages) + $pages; 
print "Random data size: ".$size."\n" if $debug;

# Make a key for AES
$key = encode_base64(`dd if=$inputFile bs=42 count=1 2>/dev/null`);
print "Key: ".$key."\n" if $debug;

# Read random bytes and pass them through AES to improve
# statistical uniformity of the sequence
print "Obtaining random numbers.\n";
$random = `dd if=$inputFile bs=1 count=$size 2>/dev/null | openssl enc -aes256 -pass pass:$key`;
die ("Error: coult not obtain random numbers!") unless $? == 0;

# OpenSSL precedes encrypted text with "Salted__" string so we need to remove it
$random =~ s/Salted__//;

print "Raw random data: ".encode_base64($random)."\n" if $debug;

# Turn random data string into digits
@randomArray = split(//, $random);
$randomDigits = "";
foreach (@randomArray) {
    $randomDigits .= ord($_);
};

print $randomDigits."\n" if $debug;

# Split random digits into space delimited groups
$randomDigits =~ s/(\d{$groupWidth})/$1 /g;

## Split into lines
$randomDigits =~ s/((\d{$groupWidth} ){$pageWidth})/$1\n/g;

# Cut out extra lines
$lines = ($pageHeight * $pages) + $pages;
print "Lines: $lines\n" if $debug;
$randomDigits =~ m/(((((\d{$groupWidth} ){$pageWidth})\n)){$lines})/;
$randomDigits = $1;

# Split into pages
@randomLines = split(/\n/, $randomDigits);
$position = 0;
$pageNumber = 1;
$pagesData = "";

while ($pageNumber <= $pages) {
    $randomLines[$position] =~ m/(\d{$groupWidth})/;
    $serial = $1;
    $position++;

    $pageLine = 1;
    $pageText = "";

    while ($pageLine <= $pageHeight) {
        $pageText = $pageText . $randomLines[$position] . $LINE_BREAK;
        $pageLine++;
        $position++;
    }

   $pageLine = 1;
   $page = $PAGE;
   $page =~ s/_SERIAL_/$serial/;
   $page =~ s/_DATA_/$pageText/;
   $pagesData = $pagesData . $page . $PAGE_BREAK ."\n";
   $pageNumber++;
}

$output = $BEGIN . $pagesData . $END;

# Write generated data to file
open(HANDLE, ">$outputFile");
print "Writing output file.\n";
print HANDLE $output or die("Error: Could not write to $outputFile!\n");
close(HANDLE);

if (!$plaintext) {
    print "Compiling the PDF.\n";
    system("pdflatex $outputFile 2>&1 >/dev/null");
    die("Error: Could not compile a PDF!") unless $? == 0;

    if (!defined($keepsource)) {
       print "Cleaning up LaTeX source and logs.\n";
       if (!$USE_RM) {
            system("shred -zu $outputFile"); 
       } else {
            system("rm -f $outputFile");
       }
       system("rm -f $outputFile.log $outputFile.aux");
    }
}

print "Done!\n";
exit(0);
