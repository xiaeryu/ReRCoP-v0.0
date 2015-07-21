ReRCoP
===
Recombination Removal for Core-genome Phylogeny

Prerequisites
---
1. Linux environment
2. Perl
3. Perl package: File::Basename
4. R
5. R packages: ape, vegan, MASS, car 
6. BLAST package. (makeblastdb, blastn)
7. [clustalo] (http://www.clustal.org/omega/) for multiple sequence alignment

Usage
---
```sh
sh ReRCoP.sh
        -s      *genome sequence file, in multiple-fasta format
        -g      *gene coding sequence file, in multiple-fasta format
        -o      output directory, please specify an unexisting directory [default: ./ReRCoP]
        -p      prefix of output files [default: default]
        -t      number of threads to use [default: 6]
        * are required input
```

Input files
---
1. A file in multiple nucleotide fasta format with gene coding sequences (All the coding sequences from any one of the samples will do).  
  * If one of the input is complete genome with annotation from the public database:  
		1> Download coding sequence in multiple nucleotide fasta format.  
		2> Remove duplicated genes.  
		3> Remove phage genes.  
		4> Remove genes with CRISPER sequence.
 * Else if one of the input is complete genome without annotations from the public database:  
		1> Predict coding sequences with software like [prodigal](http://prodigal.ornl.gov/).  
		2> Remove duplicated genes.  
    3> Remove phage genes.  
	  4> Remove genes with CRISPER sequence.
 * Else if none of the input files are complete genomes but are raw sequencing reads, do the following:  
		1> Use assmbly tools for de novo assembly to get files of contigs for each sample.  
		2> Use one of the samples with good assembly quality, predict coding sequences with software like [prodigal](http://prodigal.ornl.gov/).  
		3> Remove duplicated genes.  
		4> Remove phage genes.  
		5> Remove genes with CRISPER sequence.  

2. A file in multiple nucleotide fasta format with genome sequences.
 * Complete sequences: Should be in fasta format.
 * Assembled contigs: Concatenate the contigs to form one fake genome sequence, which can be done with the script FormatContig.pl in ./scripts. Then concatenate all genome sequences or fake genome sequences to form a multiple-fasta file.
```perl
		perl FormatContig.pl <contig fasta file> <header of the output fasta file> <output fasta file>
```
  
Cautions
---
Take note about giving different header names for the fasta file. If the header file contains blanks, the first column should all be different. Don't include 'Inf' or 'NA' in the name.

Output files
---
* **.final.summary**: A summary of the category of each input gene
 * Column 1: Gene number label
 * Column 2: Gene name
 * Column 3: Gene length
 * Column 4: Gene category   
		(NON-CORE: non-core genes  
		 NON-PHYLOGENETIC: non-phylogenetic genes removed at the first stage  
		 HGT-RECOMB: genes detected as recombinat in at least one of the isolates, Column 5 shows the genomes in which the gene is detected as recombinant  
		 PASS: core genes that are phylogenetically relevant and contain no recombination)
 * Column 5: genomes in which the gene in column 4 is detected as recombinant

* **.all.concatenated.fasta** : the concatenated fasta file of the core genomes without removal
* **.all.concatenated.fasta.log**: log file for the above concatenation. The genes are indicated by the gene number label, which can map to the respective gene name in the .final.summary file

* **.stage1.all.concatenated.fasta**: the concatenated fasta file of the core genomes after the first stage of removal, say after removing non-phylogenetic genes
* **.stage1.all.concatenated.fasta.log**: log file for the above concatenation. The genes are indicated by the gene number label, which can map to the respective gene name in the .final.summary file (This log is also the log for the below fasta concatenation, because the second stage of removel does no removal of genes but set recombination gene sequences to '-'.)

* **.stage2.all.concatenated.fasta**: the concatenated fasta file of the core genomes after the second stage of removal, say after setting the all bases in recombination gene sequences to '-'. Designed to be the input file for downstream phylogenetic studies.

* **the msa directory**: the aligned sequences of each core gene.
