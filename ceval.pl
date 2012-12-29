#!/usr/bin/env perl

use strict;
use warnings;

my $CC = "gcc -x c -lm";
my $TMP_DIR = "/tmp/";

my $template = <<EOL;
#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <complex.h>

int main(void)
{
     __PLACEHOLDER__;
     return(0);
}

EOL

if( $#ARGV < 0 )
{
     print "I see no point in evaluating empty string.\n";
     exit(1);
}
elsif( $#ARGV > 0)
{
     print "Too many arguments\n";
     exit(1);
}

my $input = $ARGV[0];

# Join timestamp and a random number in hope
# it gives a unique file name
my $file_name = $TMP_DIR . time() . int(rand(1000));
my $src_file_name = $file_name . ".c";

my $code = $template;
$code =~ s/__PLACEHOLDER__/$input/;

open( HANDLE, ">$src_file_name" );
print HANDLE $code;
close( HANDLE );

my $cc_output = `$CC -o $file_name $src_file_name`;
unlink($src_file_name);
print "$cc_output";

if( $? == 0 )
{
     my $output = `$file_name`;
     print "$output\n";
     unlink($file_name);
     exit(0);
}
else
{
     exit(1);
}

