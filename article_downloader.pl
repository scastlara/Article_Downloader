#!/usr/bin/perl
#
# Article_downloader.pl - This script takes a list of PMIDs and downloads medline 
#                         records foreach one. Then, it creates a tabular file that
#						  contains useful information from the medline records. 
#                         Finally, it downloads the corresponding PubMed abstracts 
#                         and PubMedCentral articles (if available at PMC).
#
#			Arguments: 	  A file with PMIDs
#
# 			Requirements: You need to run the code inside a folder that contains 
#               		  the following directories:
#							- epubs/
#							- abstracts/
#							- medline/
#
#********************************************************************************


use warnings;
use strict;
use LWP::Simple;
use LWP::UserAgent;
use Getopt::Std;


#********************************************************************************
# VARIABLES 
#********************************************************************************

my %options = ();
getopts("af", \%options);
	# -a : download only abstracts
	# -f : force download of all PMIDs (even already downloaded ones)


my $file    = shift @ARGV;
my $abs     = 0;
my @PMIDs   = "";
my $ua      = LWP::UserAgent->new();
		    $ua->agent('Mozilla/5.0');
		    $ua->timeout(30);


#********************************************************************************
# MAIN LOOP 
#********************************************************************************

print STDERR "####\n#### STARTING PROGRAM...\n####\n";

open (TAB, "> medline.tbl"); # This erases medline.tbl if it exists.

close (TAB);

@PMIDs = &read_PMID(\$file);

&filter_ids(\@PMIDs) unless ($options{f});

&MEDLINE_download(\@PMIDs);

print STDERR "\n####\n#### MEDLINE INFO SAVED AS MEDLINE.tbl\n####\n";
print STDERR "\n####\n#### STARTING EPUBS AND ABSTRACTS DOWNLOAD...\n####\n";

&article_downloader(\%options);

print STDERR "####\n#### PROGRAM FINISHED.\n\n";


#********************************************************************************
# FUNCTIONS 
#********************************************************************************

#********************************************************************************
sub read_PMID {
	
	my $file = shift @_;  # remember $file is a reference!
	my @PMIDs;
	
	open (FILE, $$file) or die "Can't open PMID file!\n";
	
	while (<FILE>) {
		
		chomp;
		next if $_ !~ /\d/; # skips empty lines
		push (@PMIDs, $_);	
	
	}; # while

	close (FILE);
	
	return @PMIDs;

}; # read_PMID


#********************************************************************************
sub filter_ids {
	
	my $id_array   = shift;
	my %downloaded = ();

	open my $cmd, 'ls epubs/ abstracts/ epubabs/ |'
		or die "Can't run ls command : $!\n";

	while (<$cmd>) {
		
		chomp;
		$downloaded{$1} = undef if (m/PMID_(\d+)_/g);

	}

	@$id_array = grep { !exists $downloaded{$_} } @$id_array;

	return;

} # filter_ids


#********************************************************************************
sub MEDLINE_download {

	my $PMIDs = shift @_; # remember $PMIDs is a reference to the array!
	my $i     = 0;
	
	foreach my $ID (@$PMIDs) {
		
		if ($i == 25) {
			
			print STDERR "Waiting 3 seconds... :-)\n\n";
			sleep(3);
			$i = 0;

		} # i = 25

		my $MEDLINE = get("http://www.ncbi.nlm.nih.gov/pubmed/$ID?report=medline&format=text");
		print STDERR "Downloading $ID medline record...\n";
		
		open(MEDLINE, "> medline/${ID}.medline");
		
		print MEDLINE"$MEDLINE";
		
		close(MEDLINE);

		print STDERR "Saved as $ID.medline.\n\n";
		&medline_to_tabular(\$MEDLINE, $ID);
		$i++;

	}; # foreach

}; # MEDLINE_download


#********************************************************************************
sub medline_to_tabular {
	
	my $MEDLINE          = shift @_; # remember $MEDLINE is a reference to the actual text!
	my $PMID             = shift @_;
	my @medline_lines    = split (/\n/, $$MEDLINE);
	my $previouskey      = "nothing yet";
	my @interesting_keys = qw (AB FAU JT PMC);
	my %data             = map {$_, "-"} @interesting_keys;

	foreach my $line (@medline_lines) {

		$line =~ s/-//g;
		
		next if (substr ($line, 0, 1) eq "<");
		
		my @columns = split /\s+/, $line;
		my $key     = $columns[0];
		
		if ($key eq "AB" or $previouskey eq "AB" and substr ($line, 0, 1) =~ /\s/) {
		
			$data{AB} = $data{AB} . " " . (join ' ', @columns[1..$#columns]);
			chomp $data{AB};
		
		} elsif (exists $data{$key}) {
			
			my $field   = join ' ', @columns[1..$#columns];
			$field      =~ s/ /_/g;
			$data{$key} = $field;

		} # if 
		
		# set current key as "previous" for the next iteration if condition
		
		if (substr ($line, 0, 1) !~ /\s/) {
			
			$previouskey = $key;
		
		} # if
		
	} # foreach line
	
	$data{AB} =~ s/-//g;
	$data{AB} =~ s/^\s//; # remove first character
	
	open (TAB,">> medline.tbl") or die "Can't open medline.tbl!\n";
		
	print TAB "$PMID\t$data{FAU}\t$data{JT}\t$data{PMC}\t$data{AB}\n";

	close (TAB);

} # sub medline_to_tabular


#********************************************************************************
sub article_downloader {
	
	my $options_hsh = shift;
	open (TBL, "medline.tbl") or die "\nCan't open tbl file...";
	my $i = 0;

	while (<TBL>) {

		my ($PMID, $autor, $journal, $PMC, @abstract) = split /\t/, $_; 
		$autor =~ s/[^A-Z0-9_]//ig; #delete commas

		if ($PMC =~ m/-/ or defined $options_hsh->{a}) {

			print STDERR "\n# $PMID:\nSaving $PMID abstract as PMID_${PMID}_${autor}_abstract.txt...\n";
			open (ABS, ">abstracts/PMID_${PMID}_${autor}_abstract.txt");
			print ABS "@abstract\n";

		} else {
			
			if ($i == 25) {
			
				print STDERR "Waiting 3 seconds... :-)\n\n";
				sleep(3);
				$i = 0;

			} # i = 25

			print STDERR "\n#$PMID:\nDownloading $PMID epub...\n";		
			my $url      = "http://www.ncbi.nlm.nih.gov/pmc/articles/${PMC}/epub";
			my $response = $ua->get($url);
			my $content  = $response->decoded_content;

			no warnings;
			
			open my $fh, ">", "epubs/PMID_${PMID}_${autor}.epub";
			
			print {$fh} $content;

			open (ABS, ">epubabs/PMID_${PMID}_${autor}_abstract.txt");
			print ABS "@abstract\n";
			
			use warnings;

			if ($response->is_success) {

				print STDERR"epub saved as PMID_${PMID}_${autor}.epub at 'epubs/'\n";
				print STDERR"abstract saved as PMID_${PMID}_${autor}_abstract.txt at 'epubabs/'\n";
				$i++;

			} else {

				print STDERR"Can't download PMID_${PMID}_${autor}.epub! (probably not available at PMC)\n";
				print STDERR "Don't worry! Saving $PMID abstract as PMID_${PMID}_${autor}_abstract.txt...\n";
				open (ABS, ">abstracts/PMID_${PMID}_${autor}_abstract.txt");
				print ABS "@abstract\n";
			
			}			
	
		} # if

	} # while

} # article_downloader