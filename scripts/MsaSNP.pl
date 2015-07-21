#!usr/bin/perl

# This script takes in a aligned multiple fasta file and summarize the statistics.
# Output file: #(Total bases)	#Consensus	%Consensus	#SNP	%SNP	#Uncovered	%Uncovered

use File::Basename;

if(!defined($ARGV[0])){
	die "USAGE: perl $0 <multiple fasta file>\n";
}

my $name=basename $ARGV[0];
my %seq;	# All the sequences in the fasta file
my $trace;
open(INPUT,"$ARGV[0]") or die "Cannot open input fasta file:$!\n";
while(<INPUT>){
	chomp;
	if(/^>/){
		$trace=$_;
	}else{
		s/\s+//g;
		my $text=uc($_);
		$seq{$trace}.=$text;
	}
}
close INPUT;

my $consensus;	# Number of consensus sites
my $uncover;	# Number of uncovered sites
my $snp;	# Number of SNP sites
my @site;	# 0 for consensus, 1 for SNP sites, 2 for uncovered. 

## Use the last sequence put in as the reference sequence.
my @ref=split(//,$seq{$trace});
for(my $j=0;$j<=$#ref;$j++){
	unless($ref[$j]=~m/[ATCG]/){
		$site[$j]=2;
	}else{
		$site[$j]=0;
	}
}

## Compare each sequence with the reference sequence.
foreach my $key(keys %seq){
	my @tmp=split(//,$seq{$key});
	for(my $i=0;$i<=$#ref;$i++){
		unless($tmp[$i]=~/[ATCG]/){
			$site[$i]=2;
		}elsif(($tmp[$i] ne $ref[$i]) && (!$site[$i])){
			$site[$i]=1;
		}
	}
}

## Summarize the statistics.
for(my $i=0;$i<=$#ref;$i++){
	if($site[$i]==0){
		$consensus++;
	}elsif($site[$i]==1){
		$snp++;
	}else{
		$uncover++;
	}
}

my $total=$#ref+1;
printf ("%s\t%d\t%d\t%.3f\t%d\t%.3f\t%d\t%.3f\n",$name,$total,$consensus,$consensus/$total,$snp,$snp/$total,$uncover,$uncover/$total);
