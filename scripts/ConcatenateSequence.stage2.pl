#!usr/bin/perl

if(!defined($ARGV[2])){
	die "USAGE: perl $0 <gene.rate file> <directory to all MSA aligned sequences> <output file>\n";
}

## Record the result of gene.rate and gene.rate.info file.
my @colnames;	# Record the column names, the sequence name
my %colref;	# Reverse the colnames
my @rownames;	# Record the row names, the gene name
my @storage;	# $storage[$m][$n] shows whether to preserve the gene $m in the sequence $n (velue 1) or to desert (value 0)

open(LISTO,$ARGV[0]) or die "Cannot open input .gene.rate file:$!\n";
my $here=<LISTO>;
my @tmprec=split(/\s+/,$here);
for(my $j=4;$j<=$#tmprec;$j++){
	push(@colnames,$tmprec[$j]);
	$colref{$tmprec[$j]}=$j-4;
}
close LISTO;

my $count=0;
open(LISTT,"$ARGV[0].info") or die "Cannot open input .gene.rate.info file:$!\n";
$here=<LISTT>;
while(<LISTT>){
	chomp;
	my @tmp=split(/\s+/);
	push(@rownames,$tmp[0]);
	for(my $i=$#colnames+5;$i<=$#tmp;$i++){
		$storage[$count][$i-($#colnames+5)]=$tmp[$i];	
	}
	$count++;
}
close LISTT;

# Concatenate the sequences.
my %sequence;	# Put in all sequences.
my $trace;
my $remove;
for(my $i=0;$i<=$#rownames;$i++){
	open(INPUT,"$ARGV[1]/aligned.$rownames[$i]") or die "Cannot open an aligned.fasta file:$!\n";
	while(<INPUT>){
		chomp;
		if(/>Gene\d+\|(.+)\|From/){
			$trace=$1;
			if($storage[$i][$colref{$trace}]==0){
				$remove=1;
			}else{
				$remove=0;
			}
		}elsif(/.+/){
			s/\s+//g;
			my $line=$_;
			if($remove){
				$line=~s/\w/-/g;	# If remove is true, set all characters to '-'.
			}
			$sequence{$trace}.=$line;
		}
	}
}

# Output the sequences.
open(OUT,"> $ARGV[2]") or die "Cannot write to the output file:$!\n";
for(my $i=0;$i<=$#colnames;$i++){
	print OUT ">$colnames[$i]\n$sequence{$colnames[$i]}\n";
}
close OUT;
