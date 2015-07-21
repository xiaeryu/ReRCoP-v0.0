## Copyright (C) 2015 Xia Eryu (xiaeryu@u.nus.edu).
##
## This program is free software; you can redistribute it and/or
## modify it under the terms of the GNU General Public License
## as published by the Free Software Foundation; either version 3
## of the License, or (at your option) any later version.

## This program is distributed in the hope that it will be useful,
## but WITHOUT ANY WARRANTY; without even the implied warranty of
## MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
## GNU General Public License for more details.

## You should have received a copy of the GNU General Public License
## along with this program; if not, see 
## http://www.opensource.org/licenses/gpl-3.0.html

## ReRCoP.sh
## --------------------------------
## Please report bugs to:
## xiaeryu@u.nus.edu


#!/bin/bash

if [[ $# -lt 1 ]]; then
        echo "USAGE: `basename $0`"
	echo "	-s	*genome sequence file, in multiple-fasta format"
	echo "	-g 	*gene coding sequence file, in multiple-fasta format"
	echo "	-o	output directory, please specify an unexisting directory [default: ./ReRCoP]"
	echo "	-p	prefix of output files [default: default]"
	echo "	-t	number of threads to use [default: 6]"
	echo "	* are required input"
        exit 1
fi

## Paremeters with default value
prefix="default"
outdir="./ReRCoP"
thread=6
dir=`dirname $0`
dir=$dir/scripts

## Parse arguments
while getopts s:g:o:p:t:h opt
do
        case $opt in
                s) seq=$OPTARG
                echo "Input genome sequence file: $seq";;

		g) cds=$OPTARG
		echo "Input coding sequence file: $cds";;

                o) outdir=$OPTARG
                echo "Output directory: $outdir";;

                p) prefix=$OPTARG
                echo "Output prefix: $prefix";;

		t) thread=$OPTARG
		echo "Number of threads to use: $thread";;

		h)
		echo "USAGE: `basename $0`"
	        echo "  -s      *genome sequence file, in multiple-fasta format"
        	echo "  -g      *gene coding sequence file, in multiple-fasta format"
	        echo "  -o      output directory, please specify an unexisting directory [default: ./ReRCoP]"
        	echo "  -p      prefix of output files [default: default]"
        	echo "  -t      number of threads to use [default: 6]"
	        echo "  * are required input"
                exit 1;;

                \?) echo "ERROR: Unknown option $OPTARG"
                exit 1;;

                :) echo "ERROR: No argument value for option $OPTARG"
                exit 1;;

        esac
done

######################################################
# Variables
######################################################
# seq	-input genome sequence file
# cds	-input gene coding sequence file
# outdir	-output directory
# prefix	-output prefix
# thread	-number of threads to use
# dir	-directory to scripts
######################################################

######################################################
# Checkpoint: prerequisites and input
######################################################

echo
echo "Checking prerequisites..."

##### Verify prerequisite software ###################
## Check necessary perl packages
perl $dir/CheckPerlPackage.pl
if [[ $? != 0 ]]; then
        echo "ERROR: Please check the installation of necessary perl packages!"
        exit 1
fi

## Check necessary R packages
rpack=`Rscript $dir/CheckRPackage.r | awk '{print $2}'`
if [[ $rpack -ne 1 ]]; then
        echo "ERROR: Please check the installation of necessary R pacakges!"
        exit 1
fi

## Check blast installation
if [[ ! -f `which makeblastdb` ]]; then
        echo "ERROR: Please check the installation of makeblastdb!"
        exit 1
fi

if [[ ! -f `which blastn` ]]; then
        echo "ERROR: Please check the installation of blastn!"
	exit 1
fi

## Check clustalo installation
if [[ ! -f `which clustalo` ]]; then
        echo "ERROR: Please check the installation of clustalo!"
        exit 1
fi

##### Verify existance of input files and directories#
if [[ ! -f $seq ]]; then
	echo "ERROR: Cannot find input genome sequence file!"
	exit 1
fi

if [[ ! -f $cds ]]; then
        echo "ERROR: Cannot find input coding sequence file!"
	exit 1
fi

if [[ -d $outdir ]]; then
	echo "ERROR: Please specify an unexisting directory!"
	exit 1
fi

mkdir $outdir

##### Verify the validity of the naming of the input files.
judge=`grep '>' $seq | sed 's/> */>/g' | awk '{print $1}' | sort | uniq -c | awk '{if($1>1) print}' | wc -l`
if [[ $judge -gt 0 ]]; then
	echo "ERROR: Fail the name validity check in genome sequence file: $seq"
	cat -n $seq | grep '>' | sed 's/> */>/g' | sort -k2 | awk '{if($2 == VALUE) print;VALUE=$2}'
	exit 1
fi

judge=`grep '>' $cds | sed 's/> */>/g' | awk '{print $1}' | sort | uniq -c | awk '{if($1>1) print}' | wc -l`
if [[ $judge -gt 0 ]]; then
        echo "ERROR: Fail the name validity check in genome sequence file: $seq"
        cat -n $cds | grep '>' | sed 's/> */>/g' | sort -k2 | awk '{if($2 == VALUE) print;VALUE=$2}'
        exit 1
fi


######################################################
# Pipeline starts here
######################################################
echo
echo "Start running the program..."

##### Blast gene coding sequences in the genome sequences
makeblastdb -in $cds -out $outdir/db -dbtype nucl
blastn -db $outdir/db -query $seq -task blastn -dust no -outfmt 7 -max_target_seqs 1000000 > $outdir/$prefix\_blast.out

##### Parse blast out ################################
perl $dir/ParseBlast.pl $seq $cds $outdir/$prefix\_blast.out $outdir/$prefix\_parse.out

##### Extract gene sequences #########################
mkdir $outdir/gene_sequence
perl $dir/ExtractSequence.pl $outdir/$prefix\_parse.out $seq $outdir/gene_sequence/ $prefix
mv $outdir/gene_sequence/$prefix.rec $outdir
mv $outdir/gene_sequence/$prefix.log $outdir

##### Multiple sequnece alignment ####################
mkdir $outdir/msa
sh $dir/msa.clustalo.sh $thread $outdir/$prefix.log $outdir/gene_sequence/ $outdir/msa

nrec=`wc -l $outdir/$prefix.log | awk '{print $1}'`
nfinish=`ls $outdir/msa | wc -l`

while [[ $nfinish -lt $nrec ]]; do
        sleep 100
        nfinish=`ls $outdir/msa | wc -l`
done

##### Alignment summary ##############################
echo "File	#Total	#Consensus	%Consensus	#SNP	%SNP	#Uncovered	%Uncovered" > $outdir/$prefix.multiple.snp.rec
cat $outdir/$prefix.log | while read line; do perl $dir/MsaSNP.pl $outdir/msa/aligned.$line; done >> $outdir/$prefix.multiple.snp.rec
awk '{if($3==0) print $1}' $outdir/$prefix.multiple.snp.rec | sed 's/^aligned.//' | sort > $outdir/$prefix.MsaSNP.remove
sort $outdir/$prefix.log > $outdir/$prefix.log.bak
comm -13 $outdir/$prefix.MsaSNP.remove $outdir/$prefix.log.bak > $outdir/$prefix.log
rm $outdir/$prefix.log.bak

##### Sequence concatenation #########################
perl $dir/ConcatenateSequence.pl $outdir/$prefix.log $outdir/msa/ $outdir/$prefix.all.concatenated.fasta

##### Calculate distance matrix ######################
mkdir $outdir/dist
sh $dir/dist.sh $thread $outdir/$prefix.log $outdir $outdir/dist/ $prefix

nrec=`wc -l $outdir/$prefix.log | awk '{print $1}'`
let nrec=$nrec+1
nfinish=`ls $outdir/dist | wc -l`

while [[ $nfinish -lt $nrec ]]; do
        sleep 100
	nfinish=`ls $outdir/dist | wc -l`
done

cat $outdir/$prefix.log | while read line; do echo -ne $line "\t"; sed '1d' $outdir/dist/$line.dist | awk '{$1="";print}' | grep "NA" -c; done | awk '{if($2>0) print $1}' > $outdir/$prefix.MsaSNP.remove.1
cat $outdir/$prefix.log | while read line; do echo -ne $line "\t"; sed '1d' $outdir/dist/$line.dist | awk '{$1="";print}' | grep "Inf" -c; done | awk '{if($2>0) print $1}' >> $outdir/$prefix.MsaSNP.remove.1
sort $outdir/$prefix.MsaSNP.remove.1 > $outdir/$prefix.MsaSNP.remove.2
comm -13 $outdir/$prefix.MsaSNP.remove.2 $outdir/$prefix.log > $outdir/$prefix.log.bak
mv $outdir/$prefix.log.bak $outdir/$prefix.log
rm $outdir/$prefix.MsaSNP.remove.1 $outdir/$prefix.MsaSNP.remove.2

##### Mantel test ####################################
Rscript $dir/mantel.r $outdir/dist/$prefix.all.concatenated.dist $outdir/dist/ $outdir/$prefix.log $outdir/$prefix.mantel.out

##### Remove disrupted genes and build new concatenated sequences
awk '{if($NF == "TRUE") print $2}' $outdir/$prefix.mantel.out > $outdir/$prefix.log.2
perl $dir/ConcatenateSequence.pl $outdir/$prefix.log.2 $outdir/msa/ $outdir/$prefix.stage2.all.concatenated.fasta

##### Compute Shannon entropy ########################
perl $dir/ShannonEntropy.pl $outdir/$prefix.stage2.all.concatenated.fasta $outdir/$prefix.stage2.all.concatenated.fasta.log $outdir/$prefix.stage2.all.concatenated
comm -23 $outdir/$prefix.log $outdir/$prefix.log.2 > $outdir/$prefix.stage1.remove.log

##### Outlier test ###################################
perl $dir/GeneDiff.pl $outdir/$prefix.stage2.all.concatenated.consensus.fasta $outdir/$prefix.stage2.all.concatenated.fasta $outdir/$prefix.stage2.all.concatenated.gene.entropy $outdir/$prefix.stage2.all.concatenated.gene.rate

Rscript $dir/OutlierTest.r $outdir/$prefix.stage2.all.concatenated.gene.rate $outdir/$prefix.stage2.all.concatenated.gene.rate.info

Rscript $dir/RemovalPlot.r $outdir/$prefix.stage2.all.concatenated.gene.rate.info $outdir/$prefix.outlier.plot.pdf

##### Concatenate to remove recombinations detected in stage2
perl $dir/ConcatenateSequence.stage2.pl $outdir/$prefix.stage2.all.concatenated.gene.rate $outdir/msa/ $outdir/$prefix.stage3.all.concatenated.fasta

##### Final compiled result of the fate of genes #####
perl $dir/CombineRec.pl $cds $outdir/$prefix.rec $outdir/$prefix.stage1.remove.log $outdir/$prefix.stage2.all.concatenated.gene.rate.info $outdir/$prefix\_parse.out > $outdir/$prefix.final.summary

##### Clean up #######################################
mkdir $outdir/out.tmp
mv $outdir/$prefix.final.summary $outdir/out.tmp/
mv $outdir/$prefix.all.concatenated.fasta $outdir/out.tmp/
mv $outdir/$prefix.all.concatenated.fasta.log $outdir/out.tmp/
mv $outdir/$prefix.stage2.all.concatenated.fasta $outdir/out.tmp/$prefix.stage1.all.concatenated.fasta
mv $outdir/$prefix.stage2.all.concatenated.fasta.log $outdir/out.tmp/$prefix.stage1.all.concatenated.fasta.log
mv $outdir/$prefix.stage3.all.concatenated.fasta $outdir/out.tmp/$prefix.stage2.all.concatenated.fasta

rm $outdir/*
rm -rf $outdir/gene_sequence/
rm -rf $outdir/dist/
mv $outdir/out.tmp/* $outdir
rm -rf $outdir/out.tmp/
