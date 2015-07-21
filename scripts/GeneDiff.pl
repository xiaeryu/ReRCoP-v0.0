#!usr/bin/perl

if(!defined($ARGV[3])){
	die "USAGE: perl $0 <consensus.fasta file> <concatenated.fasta file> <.gene.entropy file> <output file>\n";
}

# use strict;
# use warnings;

## Read in the gene.entropy file with name/From/To/Entropy into the array @storage.

my $count;	# Count the line number to use as the array index
my @storage;	# Put in the information from the entropy file

open(ENT,$ARGV[2]) or die "Cannot open gene.entropy file:$!\n";
while(<ENT>){
	chomp;
	my @tmp=split(/\s+/);
	$storage[$count][0]=$tmp[0];
	$storage[$count][1]=$tmp[1];
	$storage[$count][2]=$tmp[2];
	$storage[$count][3]=$tmp[3];
	$count++;
}
close ENT;


## Read in the consensus.fasta file and put into the array @reference.

my @reference;	# Storage the reference sequence.

open(REF,$ARGV[0]) or die "Cannot open input consensus.fasta file:$!\n";
while(<REF>){
	chomp;
	if(!/^>/){
		@reference=split(//);	
	}
}
close REF;


## Read in the sequences and make the comparison.

my @names;	# Store the names of the sequences of the multiple fasta file.
my $col=3;	# column index to put in the @storage array.

open(INPUT,$ARGV[1]) or die "Cannot open input concatenated.fasta file:$!\n";
while(<INPUT>){
	chomp;
	if(/^>(.+)/){
		push(@names,$1);
		$col++;
	}else{
		my $gene_count;		# The number of the gene.
		my $diff_count;		# The number of differences.
		my @tmp=split(//);
		for(my $i=0;$i<=$#tmp;$i++){
			if($i>$storage[$gene_count][2]){
               			$storage[$gene_count][$col]=$diff_count/($storage[$gene_count][2]-$storage[$gene_count][1]+1);
				$gene_count++;
				$diff_count=0;
        		}
        		
			if($tmp[$i] ne $reference[$i]){
				$diff_count++;
			}
		}	
		$storage[$gene_count][$col]=$diff_count/($storage[$gene_count][2]-$storage[$gene_count][1]+1);
	}
}
close INPUT;


## Output the result.

open(OUT,"> $ARGV[3]") or die "Cannot write to the output file:$!\n";
print OUT "Name\tFrom\tTo\tEntropy";
for(my $i=0;$i<=$#names;$i++){
	print OUT "\t$names[$i]";
}
print OUT "\n";

for(my $j=0;$j<$count;$j++){
	print OUT "$storage[$j][0]\t$storage[$j][1]\t$storage[$j][2]\t$storage[$j][3]";
	for(my $m=4;$m<=$col;$m++){
		printf OUT ("\t%.4f",$storage[$j][$m]);
	}
	print OUT "\n";
}
