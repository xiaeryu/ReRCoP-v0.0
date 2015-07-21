#!usr/bin/perl

## This script aims at concatenating the gene sequences of each sample to form one concatenated sequence for each isolate.
## Input: 1. log file recording which files to concatenate
##        2. directory to all aligned sequences
##        3. output file

if(!defined($ARGV[2])){
	die "USAGE: perl $0 <log file of ExtractSequence.pl> <directory to all MSA aligned sequences> <output file>\n";
}

my @gene;
open(LIST,"$ARGV[0]") or die "Cannot open the log file:$!\n";
while(<LIST>){
	chomp;
	if(/\w+/){
		push(@gene,$_);
	}
}
close LIST;

open(OUT,"> $ARGV[2]") or die "Cannot write to the output file:$!\n";
open(LOG,"> $ARGV[2].log") or die "Cannot write to the log file:$!\n";

my %all;
my $trace;
my @order;

my $previous;
for(my $i=0;$i<=$#gene;$i++){
	my $count=0;
	open(INPUT,"$ARGV[1]/aligned.$gene[$i]") or die "Cannot open an aligned.fasta file:$!\n";
	while(<INPUT>){	
		if(/>Gene\d+\|(.+)\|From/){
                        if($count==1){
				printf LOG ("%s\t%d\t%d\n",$gene[$i],$previous+1,length($all{$trace}));
				$previous=length($all{$trace});
			}
			$count++;
			$trace=$1;
			if($i==0){
				push(@order,$trace);
			}
                }elsif(/.+/){
                        s/\s+//;
                        $all{$trace}.=$_;
                }
	}
	close INPUT;
}

for(my $i=0;$i<=$#order;$i++){
	print OUT ">$order[$i]\n$all{$order[$i]}\n";
}

close OUT;
close LOG;
