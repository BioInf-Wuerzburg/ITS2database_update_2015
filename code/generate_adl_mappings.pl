#!/usr/bin/env perl

use strict;
use warnings;

use lib '/home/frf53jh/Projects/tmp/NCBI-Taxonomy/lib';

use NCBI::Taxonomy;
use Data::Dumper;
use Getopt::Long;

my ($input1, $input2) = (undef, undef);
my $rank_wanted = undef;
my $output = "output";

my %Adl_taxons = (
    33630 => 'Alveolata',
    85705 => 'Ancyromonadida',
    172820 => 'Apusomonadida',
    1401294 => 'Breviatea',
    193537 => 'Centrohelida',
    136419 => 'Cercozoa',
    33090 => 'Chloroplastida',
    28009 => 'Choanomonada',
    190322 => 'Collodictyonidae',
    3027 => 'Cryptophyceae',
    33083 => 'Dictyostelia',
    33682 => 'Discoba',
    5752  => 'Discoba',
    556282 => 'Discoba',
    29178 => 'Foraminifera',
    4751 => 'Fungi',
    38254 => 'Glaucophyta',
    2830 => 'Haptophyta',
    127916 => 'Ichthyosporea',
    339961 => 'Kathablepharidae',
    136087 => 'Malawimonadidae',
    137418 => 'Metamonada',
    207245 =>  'Metamonada',
    5719   =>  'Metamonada',
    66288 => 'Metamonada',
    33208 => 'Metazoa',
    154966 => 'Nucleariida',
    65582 => 'Polycystinea',
    2763 => 'Rhodophycea',
    1237875 => 'Rigifilida',
    33634 => 'Stramenopila',
    232264 => 'Telonema',
    555369 => 'Tubulinea'
    );

GetOptions(
    'old=s'  => \$input1,
    'new=s'  => \$input2,
    'rank=s' => \$rank_wanted,
    'out=s'  => \$output,
    );

my %result = ();

read_file(\%result, $input1, "count_old");
read_file(\%result, $input2, "count_new");

sub read_file
{
    my ($result, $inputfile, $count_id) = @_;

    open(FH, "<", $inputfile) || die "Unable to open file '$inputfile' due to: $!";
    while (<FH>)
    {
	chomp($_);
	my (undef, $taxid) = split(/\t/, $_);

	if (! exists ($result->{$taxid}))
	{
	    $result->{$taxid}{lineage}=NCBI::Taxonomy::getlineagebytaxid($taxid);
	}

	$result->{$taxid}{$count_id}++;
    }
    close(FH) || die "Unable to close file '$inputfile' due to: $!";
}

printf STDERR "Found %d different taxids\n", (keys %result)+0;

my %counts = ();
my $total_count_new = 0;
my $total_count_old = 0;
my $taxids_without = 0;

# initialize the counts hash, if we want the Adl_taxonomy
if (! defined $rank_wanted)
{
    $rank_wanted = 'Adl_taxonomy';

    foreach my $adl_taxonid (keys %Adl_taxons)
    {
	$counts{$Adl_taxons{$adl_taxonid}}{count_old} = 0;
	$counts{$Adl_taxons{$adl_taxonid}}{count_new} = 0;
    }
}

foreach my $taxid (keys %result)
{
    my @list = ();
    if ($rank_wanted ne 'Adl_taxonomy')
    {
	@list = map {$_->{name}} grep {$_->{rank} eq $rank_wanted} @{$result{$taxid}{lineage}};
    } else {
	# search for Adl taxonomy
	@list = map {$Adl_taxons{$_->{taxid}}} grep {exists $Adl_taxons{$_->{taxid}}} @{$result{$taxid}{lineage}};
    }

    if (@list == 1)
    {
	$counts{$list[0]}{count_old} += $result{$taxid}{count_old} ? $result{$taxid}{count_old} : 0;
	$counts{$list[0]}{count_new} += $result{$taxid}{count_new} ? $result{$taxid}{count_new} : 0;
	$total_count_new += $result{$taxid}{count_new} ? $result{$taxid}{count_new} : 0;
	$total_count_old += $result{$taxid}{count_old} ? $result{$taxid}{count_old} : 0;
    } elsif (@list == 0)
    {
	$counts{'others'}{count_old} += $result{$taxid}{count_old} ? $result{$taxid}{count_old} : 0;
	$counts{'others'}{count_new} += $result{$taxid}{count_new} ? $result{$taxid}{count_new} : 0;
	$taxids_without++;
    } else {
	die "Something went wrong: Got a count of neither 1 nor 0 as result for search: taxID was: $taxid, rank_wanted: $rank_wanted, Lineage: ".Dumper($result{$taxid}{lineage});
    }
}

printf "Found %d different ranks named '%s' representing %d/%d sequences and %d taxid without that rank representing %d/%d sequences\n", (grep {$_ ne 'others'} (keys %counts))+0, $rank_wanted, $total_count_old, $total_count_new, $taxids_without, $counts{others}{count_old}, $counts{others}{count_new};

my $outputfile_taxids = $output."_taxids_".$rank_wanted.".dat";
my $outputfile_gain_lost = $output."_gain_lost_".$rank_wanted.".dat";
my $outputfile_abscount = $output."_abscount_".$rank_wanted.".dat";
my $outputfile_abscount_new = $output."_abscount_new_".$rank_wanted.".dat";
my $outputfile_abscount_old = $output."_abscount_old_".$rank_wanted.".dat";
my $outputfile_change = $output."_change_".$rank_wanted.".dat";

open(TAXIDS, ">", $outputfile_taxids) || die "unable to open outputfile '$outputfile_taxids' for writing: $!";

open(GAINLOST, ">", $outputfile_gain_lost) || die "unable to open outputfile '$outputfile_gain_lost' for writing: $!";
print GAINLOST "LABELS,gain_loss\nCOLORS,#00ff00\n";

open(ABSCOUNT, ">", $outputfile_abscount) || die "unable to open outputfile '$outputfile_abscount' for writing: $!";
print ABSCOUNT "LABELS,new,old\nCOLOR,#0000ff\n";
#open(ABSCOUNTNEW, ">", $outputfile_abscount_new) || die "unable to open outputfile '$outputfile_abscount_new' for writing: $!";
#print ABSCOUNTNEW "COLOR,#0000ff\n";
#open(ABSCOUNTOLD, ">", $outputfile_abscount_old) || die "unable to open outputfile '$outputfile_abscount_old' for writing: $!";
#print ABSCOUNTOLD "COLOR,#0000ff\n";

open(CHANGE, ">", $outputfile_change) || die "unable to open outputfile '$outputfile_change' for writing: $!";
print CHANGE "LABELS,change\nCOLORS,#00ff00\n";

foreach my $taxid (sort {$a cmp $b} grep {$_ ne 'others'} keys %counts)
{
    # GAIN/LOST values
    # print a 1 for gained if count_old == 0 and count_new > 0
    # print a -1 for lost if count_old > 1 and count_new == 0
    # otherwise print 0
    my $gain_loss_val = 0; # expect no change
    if ($counts{$taxid}{count_old} == 0 && $counts{$taxid}{count_new} > 0)
    { 
	$gain_loss_val = 1;
    } elsif ($counts{$taxid}{count_old} > 0 && $counts{$taxid}{count_new} == 0)
    {
	$gain_loss_val = -1;
    }
    printf GAINLOST "%s,%d\n", $taxid, $gain_loss_val;

    # TAXIDS
    print TAXIDS "$taxid\n";

    # ABSCOUNT
    printf ABSCOUNT "%s,%.0f,%.0f\n", $taxid, 
       ($counts{$taxid}{count_new} > 0) ? (log($counts{$taxid}{count_new})/log(2)*100) : 0,
       ($counts{$taxid}{count_old} > 0) ? (log($counts{$taxid}{count_old})/log(2)*100) : 0;

    # CHANGE
    # calculate the change (increase/decrease) in percent: new/old if old == 0 set the output to 0
    my $change_val = 0;
    if ($counts{$taxid}{count_old} != 0)
    {
	$change_val = $counts{$taxid}{count_new}/$counts{$taxid}{count_old}*100-100;
    }
    
    printf CHANGE "%s,%.0f\n", $taxid, $change_val;
}

close(CHANGE) || die "unable to close outputfile '$outputfile_change' for writing: $!";
close(ABSCOUNT) || die "unable to close outputfile '$outputfile_abscount' for writing: $!";
#close(ABSCOUNTOLD) || die "unable to close outputfile '$outputfile_abscount_old' for writing: $!";
#close(ABSCOUNTNEW) || die "unable to close outputfile '$outputfile_abscount_new' for writing: $!";
close(GAINLOST) || die "unable to close outputfile '$outputfile_gain_lost' after writing: $!";
close(TAXIDS)   || die "unable to close outputfile '$outputfile_taxids' for writing: $!";


if ($rank_wanted eq 'Adl_taxonomy')
{
    my $file = $output."_counts_".$rank_wanted.".tex";
    open(FH, ">", $file) || die "Unable to open file '$file': $!";
    foreach my $taxid (sort {$a cmp $b} keys %counts)
    {
	printf FH "%s & %d & %d & %s \\\\\n", $taxid, $counts{$taxid}{count_new}, $counts{$taxid}{count_old}, (($counts{$taxid}{count_old} != 0) ? sprintf('\\SI{%+.1f}{\\percent}', ($counts{$taxid}{count_new}/$counts{$taxid}{count_old}-1)*100) : 'n.d.');
    }
    close(FH) || die "Unable to close file '$file': $!";
}
