#!/bin/bash R

.libPaths()

library(phyloseq)
library(tidyverse)
library(plyr)
library(dplyr)

#.libPaths("/apps/R/lib/3.2/") 

# get the input passed from the shell script
args <- commandArgs(trailingOnly = TRUE)
str(args)
cat(args, sep = "\n")

# test if there is at least one argument: if not, return an error
if (length(args) == 0) {
  stop("At least one argument must be supplied (input file).\n", call. = FALSE)
} else {
  print(paste0(args))
}

# use shell input
input <- paste0(args[1])
output <- paste0(args[2])
mapping <-paste0(args[3])
 
print(paste0("Input file location : ", input))
print(paste0("Output file location : ", output))

## Set Directory
setwd(input)
getwd()
list_file = list.files(".", "rel-abundance.tsv")
list_file

## Create empty dataframes
combined_r10 = data.frame()
current_table = data.frame()
current_table_subset = data.frame()


## The big guy. Loops through all files to create a fake OTU table
for (i in list_file) {
  print(i)
  name = gsub("", "", i)
  ## Below is option. Will change the filename
  i2 = paste("./", i, "")
  i2 = gsub(" ", "", i2)
  current_table = read.delim(i2, header = T)
  current_table = current_table[,-c(1,2)] 
  names(current_table)[names(current_table) == 'estimated.counts'] <- name
  current_table[,ncol(current_table)] = as.numeric(round(current_table[,ncol(current_table)], digits = 0))
  current_table[,] <- lapply(current_table, gsub, pattern='\\[', replacement='')
  current_table[,] <- lapply(current_table, gsub, pattern='\\]', replacement='')
  current_table[is.na(current_table)] = as.numeric(0)
  current_table = subset(current_table, select=-subspecies)
  if ("clade" %in% colnames(current_table)) {
    current_table = subset(current_table, select=-c(clade,species.group,species.subgroup))
  }
  current_table <- dplyr::slice(current_table, 1:(n() - 1)) 
  current_table[,ncol(current_table)] = as.numeric(current_table[,ncol(current_table)])
  current_table = aggregate(.~superkingdom+phylum+class+order+family+genus+species, current_table,sum)
  if (nrow(combined_r10) == 0) {
    combined_r10 = current_table
  } else {
    combined_r10 = merge(current_table,combined_r10, all = T, by = c("family","order","class","phylum","superkingdom","genus","species"))
  }
}


combined_object = combined_r10

combined_object[is.na(combined_object)] = as.numeric(0)
combined_object[,8:ncol(combined_object)] <- sapply(combined_object[,8:ncol(combined_object)],as.numeric)
rownames(combined_object) = paste0("OTU", 1:nrow(combined_object))

#create an OTU table/split the table to get only OTUs and Subjects
otu_table = select(combined_object, -c(superkingdom,phylum,class,order,family,genus,species))

#create a taxonomy
taxa = combined_object %>%
  select(1:7)
taxa[,(1:7)] = sapply(taxa[,(1:7)],as.character)
taxa=as.matrix(taxa)

ps_object <- phyloseq(otu_table(otu_table, taxa_are_rows=TRUE), tax_table(taxa))
setwd(output)
saveRDS(ps_object, "phyloseq_object.rds")

print(paste0("Phyloseq Object Saved at: ", output))

sample_metadata = import_qiime_sample_data(mapping)

input_paper_comparisons = merge_phyloseq(ps_object, sample_metadata)

