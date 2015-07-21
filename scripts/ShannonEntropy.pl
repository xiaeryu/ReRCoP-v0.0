#!usr/bin/perl

## This script aims at computing the Shannon entropy of each position or the avarage entropy of each gene.
## Input: 1. aligned fasta file to compute the Shannon entropy
##        2. the concatenation log indicating the gene positions
##        3. the output directory and prefix
## Output: 1. .gene.entropy file, which records the average entropy for each gene
##         2. .entropy file, which records the entropy for each position
##         3. .consensus.fasta a consensus fasta file


if(!defined($ARGV[2])){
	die "USAGE: perl $0 <input aligned fasta file> <concatenation log> <output /directory/to/prefix>\n";
}

my $prefix=$ARGV[2];

## Put the data into a matrix.
my @record;
my $sequence;
open(INPUT,$ARGV[0]) or die "Cannot open input fasta file:$!\n";
while(<INPUT>){
	chomp;
	if(/^>/){
		if(defined($sequence)){
			$sequence=uc($sequence);
			my @tmp=split(//,$sequence);
			for(my $i=0;$i<=$#tmp;$i++){
				${($record[$i])}{$tmp[$i]}++;
			}
			$sequence="";
		}
	}else{
		s/\s+//g;
		$sequence.=$_;
	}
}
my $j;
my @tmp=split(//,$sequence);
for($j=0;$j<=$#tmp;$j++){
	${$record[$j]}{$tmp[$j]}++;
}
close INPUT;

## Read in gene and region information.
my $count;
my @logInfo;
open(IN,$ARGV[1]) or die "Cannot open input concatenation log file:$!\n";
while(<IN>){
	chomp;
	my @tmp=split(/\s+/);
	$logInfo[$count][0]=$tmp[0];
	$logInfo[$count][1]=$tmp[1];
	$logInfo[$count][2]=$tmp[2];
	$count++;
}
close IN;

open(ENT,"> $prefix.entropy") or die "Cannot write to the output directory:$!\n";
open(CON,"> $prefix.consensus.fasta") or die "Cannot write to the output directory:$!\n";
open(GENE,"> $prefix.gene.entropy") or die "Cannot write to the output directory:$!\n";

## Compute relative values.
my $gene_count;
my $gene_entropy;
my @consensus;	# Put the consensus sequence.
for(my $k=0;$k<$j;$k++){
	my @stats;
	my $total;
	my $entropy;
	foreach my $key (sort {${$record[$k]}{$a} <=> ${$record[$k]}{$b}} keys %{$record[$k]}){
#	foreach my $key(keys %{$record[$k]}){
		push(@stats,${$record[$k]}{$key});
		$total+=${$record[$k]}{$key};
		if(!defined($consensus[$k])){
			$consensus[$k]=$key;
		}
	}
	for(my $i=0;$i<=$#stats;$i++){
		if($stats[$i]>0){
			my $percent=$stats[$i]/$total;
			$entropy-= $percent*(log($percent)/log(2));
		}
	}
	printf ENT ("%d\t%.4f\n",$k+1,$entropy);
	
	if($k>$logInfo[$gene_count][2]){
		$logInfo[$gene_count][3]=$logInfo[$gene_count][3]/($logInfo[$gene_count][2]-$logInfo[$gene_count][1]+1);
		$gene_count++;
	}
	$logInfo[$gene_count][3]+=$entropy;
}
$logInfo[$gene_count][3]=$logInfo[$gene_count][3]/($logInfo[$gene_count][2]-$logInfo[$gene_count][1]+1);

print CON ">Consensus sequence\n";
printf CON ("%s\n",join("",@consensus));

for(my $m=0;$m<$count;$m++){
	printf GENE ("%s\t%d\t%d\t%.6f\n",$logInfo[$m][0],$logInfo[$m][1],$logInfo[$m][2],$logInfo[$m][3]);
}

close ENT;
close CON;
close GENE;
