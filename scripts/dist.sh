#!/bin/bash

thread=$1                 # Number of threads used
file=$2			  # Log file from ExtractSequence.pl
indir=$3		  # Input directory
outdir=$4		  # Output directory
prefix=$5                 # Input prefix

rundir=`dirname $0`	  # Running directory

tmp_fifofile="/tmp/$$.fifo"
mkfifo $tmp_fifofile      # Create a file of the type fifo
exec 6<> $tmp_fifofile    # Direct the file descriptor fd6 to the fifo type
rm $tmp_fifofile	  # Remove the tmp file

for((i=0;i<$thread;i++));do 
	echo
done >&6                  # Put enters to the fd6, the number of which should equal to the number of threads

## Process the concaatenated sequence.
read -u6
{ 
Rscript $rundir/calcDist.r $indir/$prefix.all.concatenated.fasta $outdir/$prefix.all.concatenated.dist
echo >&6
} &

cat $file | while read line; do	# For each of the lines in the record file
	read -u6	# Each time this command executes, one enter will be removed and carry on. 
			# Once no enter remains here, it will stop here
	{
	Rscript $rundir/calcDist.r $indir/msa/aligned.$line $outdir/$line.dist
	echo >&6	# While a process ends, add another enter here
	} &
done

for((i=1;i<=$thread;i++)); do
	wait
done               	# Wait for all processes to end.
exec 6>&-	        # Close fd6

exit 0
