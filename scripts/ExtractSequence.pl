#!usr/bin/perl

## This script aims at extracting gene coding sequences from each genome sequence based on the information from the parse.out file.
## Input: 1. _parse.out file with the location and direction of the gene sequences on the genome sequences
##        2. genome sequence file where the gene sequences should be extracted from
##        3. output directory
##        4. prefix of the extracted gene sequences
## Output: each gene coding sequence is extracted from all the genome sequences and write into a fasta file in the output directory.

if(!defined($ARGV[3])){
	die "USAGE: perl $0 <_parse.out file> <genome sequence file> <output directory> <prefix of output files>\n";
}

my $outdir=$ARGV[2];	# Output directory
my $prefix=$ARGV[3];	# Output prefix

sub reverse_complement{	# Implement the reverse-complement of a sequence file
        local $seq;
        $seq=$_[0];
        $seq=~s/A/1/gi;
        $seq=~s/T/2/gi;
        $seq=~s/U/2/gi;
        $seq=~s/C/3/gi;
        $seq=~s/G/4/gi;
        $seq=~s/1/T/g;
        $seq=~s/2/A/g;
        $seq=~s/3/G/g;
        $seq=~s/4/C/g;	# Complement
	$seq = reverse $seq;	# Reverse
	return $seq;
}

my @name;	# Put the names for each gene
my @freq;	# Put the frequency of each gene's presence.

my $flag=1;
open(INPUT,$ARGV[0]) or die "Cannot open input parse.out file:$!\n";
while(<INPUT>){
        chomp;
	my @tmp=split(/\s+/);
	if($flag){
		for(my $i=1;$i<=$#tmp;$i=$i+4){
			push(@name,$tmp[$i]);	# Put gene names into the array @name
		}
		$flag=0;
	}else{
		for(my $i=1;$i<=$#tmp;$i=$i+4){
                	if($tmp[$i]>=0.45){
				$freq[($i-1)/4]++;	# Record the number of presence of each gene in all the sequences
			}
		}
	}
}
close INPUT;

open(REC,"> $outdir/$prefix.rec") or die "Cannot write to the output directory:$!\n";
for(my $j=0;$j<=$#freq;$j++){
	print REC "$j\t$name[$j]\t$freq[$j]\n";	# Output record file with the gene name and frequency
}
close REC;

my $num_seq;    # A record of the total number of sequences
my $trace;
my %sequence;	# A record of multiple fasta file
open(FASTA,$ARGV[1]) or die "Cannot open input fasta file:$!\n";
while(<FASTA>){
        chomp;
        if(/^>(\S+)/){
                $trace=$1;
		$num_seq++;
        }else{
                s/\s+//g;
                $sequence{$trace}.=$_;
        }
}
close FASTA;

open(LOG,"> $outdir/$prefix.log") or die "Cannot write to the output directory:$!\n";

open(INPUT,$ARGV[0]) or die "Cannot open input parse.out file:$!\n";
my $throw=<INPUT>;
while(<INPUT>){
	chomp;
	my @tmp=split(/\s+/);
	my $identifier=$tmp[0];
	for(my $i=1;$i<=$#tmp;$i=$i+4){
		my $cat=($i-1)/4;
		if($freq[$cat]==$num_seq){
			if($flag==0){
				print LOG "$prefix.gene$cat.fasta\n";
			}
			open(SEQ,">> $outdir/$prefix.gene$cat.fasta") or die "Cannot write to the output directory:$!\n";
			my $print=substr($sequence{$identifier},$tmp[$i+1]-1,$tmp[$i+2]-$tmp[$i+1]+1);
			if($tmp[$i+3]==-1){
				$print=&reverse_complement($print);
			}
			print SEQ ">Gene$cat|$tmp[0]|From:$tmp[$i+1]|To:$tmp[$i+2]|Direction:$tmp[$i+3]\n";
			print SEQ "$print\n";
			close SEQ;
		}
	}
	$flag=1;
}
close INPUT;
close LOG;
