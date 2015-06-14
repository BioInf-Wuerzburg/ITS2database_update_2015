#!/usr/bin/perl
use strict;
use warnings;
use NCBI::Taxonomy;

#USAGE: perl analyze_taxid_changes.pl gi_taxid_joined

open(IN, "<$ARGV[0]") or die "$!";
while(<IN>)
     {
	 my @F = split(/\s+/);
	 my $node1=$NCBI::Taxonomy::nodes->[$F[1]];
	 my $node2=$NCBI::Taxonomy::nodes->[$F[2]];
	 if (exists $node1->{merged_with} || exists $node2->{merged_with})
	    {
		if (exists $node2->{merged_with} && !exists $node1->{merged_with}) 
		   {
		       if($node2->{merged_with} == $F[1]){
			   print "ReverseMerged\t$_";
		       }
		       else{
			   print "Different ReverseMerge\t$_";
		       }
		       next;
		   }	
		if (exists $node2->{merged_with} && exists $node1->{merged_with}){
		    if($node1->{merged_with} == $node2->{merged_with}){
			   print "BothMerged\t$_";
		       }
		       else{
			   print "Different BothMerge\t$_";
		       }
		       next;
		}
		if(exists $NCBI::Taxonomy::nodes->[$node1->{merged_with}]->{merged_with})
	           {					 
		       warn "Merged into a re-merged node - this should not happen";
		   }					 
		if ($node1->{merged_with} == $F[2])
		   {
		       print "Merged\t$_";
		   } 
		else 
		   {
		       print "Different Merge\t$_";
		   }
	    } 
	 elsif ($F[1] != $F[2]) 
	    {
		print "Different\t$_";
	    }
	 else 
	    {
		print "Same\t$_";
	    }
     }
close IN or die "$!";
