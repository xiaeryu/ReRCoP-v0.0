args <- commandArgs(TRUE)

# args[1]: dist of the concatenated fasta file.
# args[2]: directory to the dist files.
# args[3]: log file with all files to consider.
# args[4]: output file.

library(vegan)

## Compute the permutation statistics from the complete concatenated sequence.
all.dis <- read.table(args[1])
all.out <- mantel(all.dis,all.dis,permutations=9999,method="spearman")
perm <- all.out$perm
perm.out <- quantile(perm,c(0.95,0.99,0.995,0.999))
cutoff <- quantile(perm,0.99)
###############################################
# Results are like:
#        95%        99%      99.5%      99.9%
# 0.06815992 0.10922447 0.12417185 0.16581747
###############################################

## Function to calculate the correlation between each gene distance matrix with the complete matrix.
compute.cor <- function(gene.dist){
	file <- paste(args[2],"/",gene.dist,".dist",sep="")
	xdis <- read.table(file)
	all.dis <- as.vector(as.dist(all.dis))
	xdis <- as.vector(as.dist(xdis))
	xsd <- sd(xdis)
	if(xsd==0){
		xcor=0
	}else{
		xcor <- cor(all.dis,xdis,method="spearman")
	}
	xcor=round(xcor,4)
	return(xcor)
}

## Compute correlation for all genes.
infile.t <- read.table(args[3])
infile <- as.vector(infile.t[,1])
dist.cor <- lapply(infile,compute.cor)
pass <- dist.cor > cutoff
combine.table <- cbind(infile,dist.cor,pass)

write.table(combine.table,args[4])

