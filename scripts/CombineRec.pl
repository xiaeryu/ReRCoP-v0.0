#!usr/bin/perl

#use strict;
#use warnings;

if(!defined($ARGV[4])){
	die "USAGE: perl $0 <initial gene.fna file> <input .rec file> <stage1 remove log> <.gene.rate.info file> <parse.out file>\n";
}

# Calculate the lengths of the genes in the initial file.
my %length;
my $trace;
my $seqlength;
open(INPUT,$ARGV[0]) or die "Cannot open initial gene.fna file:$!\n";
while(<INPUT>){
	if(/^>(\S+)/){
		my $here=$1;
		if(defined($trace)){
			$length{$trace}=$seqlength;
		}
		$trace=$here;
		$seqlength=0;
	}else{
		s/\s+//g;
		$seqlength+=length($_);
	}
}
$length{$trace}=$seqlength;
close INPUT;


my @storage; 
# Put in all the relevant information.
# $storage[][0]: gene name
# $storage[][1]: gene length
# $storage[][2]: tag
# $storage[][3]: gene removed if the tag is "HGT_RECOMBINENT"

my $max;
open(INPUT,$ARGV[1]) or die "Cannot open input record file:$!\n";
while(<INPUT>){
	chomp;
	my @tmp=split(/\s+/);
	$max=$tmp[0];
	$storage[$tmp[0]][0]=$tmp[1];
	$storage[$tmp[0]][1]=$length{$tmp[1]};
	$storage[$tmp[0]][2]=$tmp[2];
}
close INPUT;

# Record the removed phylogenetically-irrelevent genes.
my $total;	# The total number of input genome seuqneces.
open(INPUT,$ARGV[2]) or die "Cannot open input stage1.remove.log file:$!\n";
while(<INPUT>){
	chomp;
	if(/gene(\d+)\./){
		$total=$storage[$1][2];
		$storage[$1][2]='NON-PHYLOGENETIC';
	}
}
close INPUT;

# Record the sequnece names.
my @seq_name;
open(INPUT,$ARGV[4]) or die "Cannot open input parsed.out file:$!\n";
my $remove=<INPUT>;
while(<INPUT>){
	chomp;
	my @tmp=split(/\s+/);
	push(@seq_name,$tmp[0]);
}
close INPUT;

# Record the recombinations introduced by horizontal gene transfer.
open(INPUT,$ARGV[3]) or die "Cannot open input .gene.rate.info file:$!\n";
$remove=<INPUT>;
while(<INPUT>){
	chomp;
	my @tmp=split(/\s+/);
	my $name;
	if($tmp[0]=~/gene(\d+)\./){
		$name=$1;
	}
	my @hgt;
	for(my $i=($#tmp+3)/2;$i<=$#tmp;$i++){
		if($tmp[$i]==0){
			my $here=$seq_name[$i-($#tmp+3)/2];
			push(@hgt,$here);
		}
	}
	if($#hgt>=0){
		$storage[$name][2]='HGT-RECOMB';
		$storage[$name][3]=$hgt[0];
		for(my $k=1;$k<=$#hgt;$k++){
			$storage[$name][3].=",$hgt[$k]";
		}
	}elsif($storage[$name][2]==$total){
		$storage[$name][2]='PASS';
	}
}
close INPUT;

# Output the result output file.
for(my $i=0;$i<=$max;$i++){
	if($storage[$i][2]=~/\d+/){
		$storage[$i][2]='NON-CORE';
	}
	print "$i\t$storage[$i][0]\t$storage[$i][1]\t$storage[$i][2]\t$storage[$i][3]\n";
}
