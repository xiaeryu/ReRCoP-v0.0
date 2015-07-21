args <- commandArgs(TRUE)

library(ape)
data<- read.dna(args[1],format="fasta")
out <- dist.dna(data,as.matrix=TRUE)
out <- round(out,6)
write.table(out,args[2])
