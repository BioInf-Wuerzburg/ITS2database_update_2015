#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long;

my ($removed, $genebank) = (undef, undef);

GetOptions(
    '--removed=s' => \$removed,
    '--genbank=s' => \$genebank
    );

# first read the list of removed entries and store them inside a hash
my %removed_gis = ();

open(FH, "<", $removed) || die "Unable to open file '$removed': $!\n";
while (<FH>)
{
    # a line contains the gi and a flag indicating 0->not removed or 1->was removed
    chomp;

    my ($gi, $flag) = split(/\s+/, $_);

    $removed_gis{$gi} = $flag;
}
close(FH) || die "Unable to close file '$removed': $!\n";

# second parse the genebank entries
open(FH, "<", $genebank) || die "Unable to open file '$genebank': $!\n";
my $record = "";
while (<FH>)
{
    if ($_ =~ /^\/\//)
    {
	# parse the record
	$record =~ /^(LOCUS.*)$/m;
	my (undef, $acc, $len, undef, $type, $format, $division, $update) = split(/\s+/, $1);
	$record =~ /^VERSION\s+(\S+)\s+GI:(\d+)/m;
	$acc = $1;
	my $gi = $2;
	
	# is the gi in the list of deleted gis?
	unless (exists $removed_gis{$gi})
	{
	    warn("Error with entry $gi! Missing entry in removed hash");
	}
	my $deleted = $removed_gis{$gi};
	
	# was the sequence replaced, but expect not replaced
	my $replaced = 0;
	if ($record =~ /COMMENT\s+\[WARNING\] On .+ this sequence was replaced by/)
	{
	    $replaced = 1;
	}
	
	# does the entry belong to a not scanned division?
	my $wrong_division = 0;
	unless (grep {$division eq uc($_)} qw(env inv mam pln pri rod sts una vrt nc))
	{
	    $wrong_division = 1;
	}
	
	print join("\t", ($gi, $acc, $len, $division, $update, $wrong_division*4+$replaced*2+$deleted)), "\n";
	$record = "";
    } else {
	$record .= $_;
    }   # a line contains the gi and a flag indicating 0->not removed or 1->was removed
}
close(FH) || die "Unable to close file '$genebank': $!\n";
