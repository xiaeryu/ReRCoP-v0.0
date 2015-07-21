#!usr/bin/perl

## This script aims at extracting necessary information from blast output file.
## Input: 1. query sequence of the blast search
##        2. fasta file for building the blast database
##        3. blast output file
##        4. output file

if(!defined($ARGV[3])){
	die "USAGE: perl $0 <input query sequence> <input database> <blast output file> <output file>\n";
}

my %sequence;
my $count=0;
system("grep \'>\' $ARGV[0] \| awk \'{print \$1}\' > tmp.file");
open(TMP,"tmp.file") or die "Cannot open tmp file:$!\n";
while(<TMP>){
	chomp;
	if(/^>(\S+)/){
		$sequence{$1}=$count;
		$count++;
	}
}
close TMP;
system("rm tmp.file");

open(OUT,"> $ARGV[3]") or die "Cannot write to the defined output file:$!\n";

my %database;
my %length;
my $count_again=0;
my $trace;
open(LIST,$ARGV[1]) or die "Cannot open input database:$!\n";
while(<LIST>){
	chomp;
	if(/^>(\S+)/){
		$trace=$1;
		$database{$trace}=$count_again;
		$count_again++;	
	}else{
		s/\s+//g;
		$length{$trace}+=length($_);
	}
}
close LIST;

my @cat;
open(INPUT,$ARGV[2]) or die "Cannot open input file:$!\n";
while(<INPUT>){
	chomp;
	if(!/#/){
		my @tmp=split(/\t/);
                my $score=2*$tmp[3]*0.01*$tmp[2]/($length{$tmp[1]}+$tmp[3]);
		my $direction;
		if($tmp[8]>$tmp[9]){
			$direction=-1;
		}else{
			$direction=1;
		}
		$score=sprintf("%.2f",$score);
		if(defined($cat[$sequence{$tmp[0]}][$database{$tmp[1]}])){
			my $here=(split(/\t/,$cat[$sequence{$tmp[0]}][$database{$tmp[1]}]))[0];
			if($score>$here){
				$cat[$sequence{$tmp[0]}][$database{$tmp[1]}]=$score."\t".$tmp[6]."\t".$tmp[7]."\t".$direction;
			}
		}else{
			$cat[$sequence{$tmp[0]}][$database{$tmp[1]}]=$score."\t".$tmp[6]."\t".$tmp[7]."\t".$direction;
		}
	}
}
close INPUT;

print OUT "TEXT";
foreach my $key(sort keys %database){
	print OUT "\t$key\tfrom\tto\tdirection";
}
print OUT "\n";

foreach my $skey(sort keys %sequence){
	print OUT "$skey";
	foreach my $dkey(sort keys %database){
		if(defined($cat[$sequence{$skey}][$database{$dkey}])){
			printf OUT ("\t%s",$cat[$sequence{$skey}][$database{$dkey}]);
		}else{
			print OUT "\t0.00\t0\t0\t0";
		}
	}
	print OUT "\n";
}

close OUT;
