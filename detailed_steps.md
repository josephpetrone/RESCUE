## **This REPO is deprecated.**
## **Please vist [RESCUE]https://github.com/josephpetrone/RESCUE for newest version**

# **Nanopore-RRN-Sequncing**
Pipeline and Methods for 16S-ITS-23S rRNA Nanopore Sequencing with Custom Barcodes.
Last update: October 21, 2022

This repo serves as a functional pipeline to perform bacterial classification and abundance analysis using Nanopore sequencing technologies. The pipeline was created specifically to use custom barcoded RRN amplicons to sequence using Nanopore. The primers listed here create a 4,500bp fragment containing the entire 16S rRNA, the intergenic spacer region, and most of the 23s rRNA. Theoretically, any primers you choose can work for this pipeline as long as contraints in the programs are changed. For further information about the pipeline and the results of a validation study, please visit (and cite) the following publications from the Triplett Lab:
```
The development and validity of a Nanopore-based pipeline to classify Bacteria through long-read, 16S-ITS-23S rRNA sequencing (2022)

Early Life Gut Salmonella-Related Enteric Bacteria May Increase Risk of Future Asperger Syndrome (2022)
```



## **Primer Descriptions**
### The construct of these RRN primers are for both the forward and reverse (5' - 3'): 
```
'Phosphate' -- 'Linker' -- '16-mer barcode' -- 'primer' 
```

### **The linker sequence is :** 
... p.s this linker and 5' Phosphate on the primer also makes the amplicons suitable for Pacbio :)
```
"GATC"
```

### **The primer binding sequences used were :** 
```
Forward 16S (5'-3') : AGRRTTYGATYHTDGYTYAG
Reverse 23S (5'-3') : CCRAMCTGTCTCACGACG 
```

### **The final primer sequences used:**
[RRN Full Primers and Barcodes](https://github.com/josephpetrone/Nanopore-RRN-Sequncing/blob/main/RRN%20primers%20and%20barcodes.xlsx)




## **PCR Protocol**
### **For each 25µL PCR tube :**
> - 2X Phusion Hot-Start High-Fidelity Polymerase----:   13µL 
> - 10µM RRN Primer/barcode Forward----------------:   1.25µL 
> - 10µM RRN Primer/barcode Reverse----------------:   1.25µL 
> - DNA Input-----------------------------------------:   2µL -or- 10ng 
> - Sterile Nuclease-Free Water-----------------------:   Complete to 25µL 

Minimum DNA input tested at ~0.5ng total 




## **Thermocylcer Conditions**
- Initial Denaturation 
> 98ºC : 30sec 
- 30 Cycles 
> 98ºC : 10sec \
> 71.5ºC : 30sec \
> 72ºC : 4min 
- Final Extenstion
> 72ºC : 7min30sec




## **Amplification QC**
** DO NOT VORTEX AND TRY TO USE WIDE-BORE TIPS TO PREVENT FRAGMENTATION **

Any improper handling techniques at this step will increase fragmentation of the amplicons, leading to incomplete "reads" populating the pool and will be thrown away during de-multiplexing.

> **1. Verify Amplification via 1% agarose gel electrophoresis @ 100V for 30min** 

> **2. Quantify product using Qubit HS chemistry**

> **3. Pool equal concentrations of DNA into a low-bind 1.5mL tube**

***Aim for ≥ 4.5µg (3 Libraries) of DNA in the pool*** \
***If volume < 100µL, complete to 100µL with elution buffer*** 

> **4. Add 0.6X AMPureXP beads and wash twice with 75% EtOH**

> **5. Elute in 100µL EDTA-free EB (2 Libraries)**


## **Library Prep** 
**Use the latest native ligation-sequencing kit from the Nanopore Store** \
***For our publication, we used SQK-LSK110 and SQK-LSK112*** \
***Once again, use wide-bore tips and flick to mix at any step where the DNA is being collected or mixed***
- Input AMPure purified DNA into the protcol (900ng-1.5µg)
- Increase END-PREP incubation step to 30min
- Increase all AMPure incubation steps to 10min and all elutions to 15min
- Increase adapter ligation step to 30min using Quick T4 Ligase  
- Use LFB for the final AMPure wash
- Load onto flowcell as usual
- Sequence until flowcell exhaustion and basecall using the highest modal "SUP" with the latest basecaller

## **Data Processing**
**If not rebasecalling, copy all passed fastqs to working folder location**

**[Bash Script (Triplett Lab README)](https://github.com/josephpetrone/Nanopore-RRN-Sequncing/blob/main/script.sh)** \
**[ReBasecalling Command Line (Triplett Lab README)](https://github.com/josephpetrone/Nanopore-RRN-Sequncing/blob/main/basecalling.sh)**

### **Read-Splitting**
**[Duplex-Tools](https://github.com/nanoporetech/duplex-tools)** \
***duplex-tools was installed to a conda environment***
> $conda activate duplextools

1st time: 
```
> $duplex-tools split_on_adapter --threads [N] --allow_multiple_splits [input_folder_to_fastq] [path/to/working/folder/1-duplextools/split1] Native

```
2nd time: 
```
> $duplex-tools split_on_adapter --threads [N] --allow_multiple_splits [path/to/working/folder/1-duplextools/split1] [path/to/working/folder/1-duplextools/split2] Native 
```
10th time: 
```
> $duplex-tools split_on_adapter --threads [N] --allow_multiple_splits [path/to/working/folder/1-duplextools/split9] [path/to/working/folder/1-duplextools/split10] Native 
```
> $conda deactivate

### **Concatenate all Fastqs**
**Bash Manipulation**

```
> $cd /path/to/working/folder/1-duplextools/split10/ 

> $mkdir all 
 
> $zcat ./*.fastq.gz > ./all/"filename".fastq
```

### **Re-Filter Reads**
**[NanoFilt](https://github.com/wdecoster/nanofilt)** \
***NanoFilt was installed to a conda environment*** \
After read-splitting, some reads will now be below the Q-Score cutoff and need to be re-filtered.
```
> $conda activate nanofilt 
 
> $cd /path/to/working/folder 
 
> $NanoFilt -q [value] --readtype (1D,2D,1D2) [path/to/working/folder/1-duplextools/split10/all/"filename".fastq] > [path/to/working/folder/2-nanofilt/"filename".fastq] 

> $conda deactivate
```
### **Demultiplex**
**[cutadapt](https://github.com/marcelm/cutadapt)** 

options: 
- -e = error
- -O = min overlap
- -o output
- -g list of adapters from adapter file
- -m = minimum read length
- -M = maximum read length
- --revcomp = if inserted, will check the reverse complement of each read for the barcode, and will reformat a read to the "top strand" orientation if found.

[barcodes.fa](https://github.com/josephpetrone/Nanopore-RRN-Sequncing/blob/main/barcodes_linked2.fa)

This demultiplexing can be the source of error so tread lightly. I have it set up so that its looking for all 16 bases of both the forward and reverse barcode under the "-O" constraint. Additionally, with "-e 0.05", 0.8 mismatches are allowed, which THE PROGRAM INTERPRETS AS ZERO MISMATCH. Size selection is also important. Although most amplicons are around 4.5Kb, we changed the size to 3kb-7kb to allow for the inclusion of all taxa, particularly Candidatus Saccharibacteria. 

```
> $conda activate cutadapt

> $cutadapt -j 25 \
	--action=none \
	-O 16 \
	-e 0.05 \
	--no-indels \
	--revcomp \
	-m 3000 \
	-M 7000 \
	-g file:$barcodes_linked2.fa \
	-o $working_dir/3-demultiplexed/combined.demuxed_{name}.fastq \
	$working_dir/2-nanofilt/split_filtered.fastq
	
```


### **Adapter-Primer Removal**
**[cutadapt](https://github.com/marcelm/cutadapt)** \

***cutadapt was used again to remove non-biological nucleotides***

> $module load cutadapt 

Loop through demultiplexed files to retain filenames and perform cutadapt individually.
```
> $cd [path/to/working/folder/3-demultiplexed]

> $for file in *.* 
> $do 
> $cutadapt -e 0.2 \
	-O 15 \
	--revcomp \
	-m 3000 \
	-M 7000 \
	-o [path/to/working/folder/4-trimmed/trimmed_$file] \
	-a AGRRTTYGATYHTDGYTYAG...CGTCGTGAGACAGKTYGG $file 
> $done
```

### **Concatenate Top and Bottom Strands**
**Bash Manipulation** 
```
> $cd /path/to/working/folder/4-trimmed/ 
 
> $mkdir reverse 
> $mkdir forward 

> $mv ./*_rev.fastq ./reverse 
> $mv ./*.fastq ./forward 
> $mv ./forward/*_unclassified.fastq ../ 
 
> $mkdir combined 
```

Concatenate top and bottom (forward and reverse) into same file \
```
> $for f in ./forward/* 
> $do 
> $basename=${f##/}
> $prefix=${basename%%.**} 
> $cat "$f" ".reverse/${prefix}_"* > .combined/"combined.$basename" 
> $done
```

### **Taxonomic Classifier**
**[EMU](https://gitlab.com/treangenlab/emu)** \
***EMU was installed to a conda environment*** \ 
This script and databases are formatted for EMU 3.0+

The re-formatted ncbi_202006db database has been reformatted as an EMU database. You can find the entire folder needed here: \
[ncbi_202006_db](https://github.com/josephpetrone/Nanopore-RRN-Sequncing/blob/main/ncbi_202006_RRN.zip)


options:
- --type = map-ont, sr, map-pb
- --min-abundance = threshold
- --threads = cpu multithreading for minimap
- --db = database folder
- --N = max alignments for each read
- --output-dir = output directoru
- --keep-files = keeps sam alignment files for each sample (remove if FALSE)
- --keep-counts = will allow read counts of each taxa to populate the csv (remove if FALSE)
```
> $cd /path/to/working/folder/ 
> $for file in ./4-trimmed/combined/* 
> $do 
> $emu abundance --type map-ont --threads 28 --keep-files --keep-counts "$file" --db /path/to/database/[ncbi_202006_RRN](/ 
	--output-dir ./5-emu
> $done
```


## **RStudio and Phyloseq Handoff**

All ".tsv" output from EMU will need to be placed into one folder for access into RStudio.

Lets load some required packages
```
library("phyloseq")
require("tidyverse")
library("ggplot2")
library("dplyr")
library(viridis)
library("Rarefy")
library(knitr)
library("kableExtra")
library(microbiome)
library(ggpubr)
```


This chunk of code will search your folder for ".tsv" files and join the taxa and counts of each file
```
## set directory of emu output
setwd("/path/to/emu/output")

## searches everything ".tsv"
list_file = list.files(".", ".tsv")

# create or clear blank data.frames
combined_r10 = data.frame()
current_table = data.frame()


## This chunk does most of the grunt of naming and which columns to pull out 
for (i in list_file) {
  print(i)
  
  ## each sample will be named according to whats inbetween "combined.trimmed_" and "_rel-abundance.tsv"
  name = gsub("_rel-abundance.tsv", "", i)
  name2 = gsub("combined.trimmed_", "", name)
  i2 = paste("./", i, "")
  i2 = gsub(" ", "", i2)
  current_table = read.delim(i2, header = T)
  
  ## Pulls the 5th, 4th, and 2nd columns out of each tsv. If you want further than genus and species-level, change constraints here
  current_table = current_table[,c(5,4,2)]
  colnames(current_table) = c("genus","species", name2)
  current_table[,3] = as.numeric(round(current_table[,3], digits = 0))
  current_table[,1] = gsub("\\[", "",current_table[,1])
  current_table[,1] = gsub("\\]", "",current_table[,1])
  current_table[,2] = gsub("\\[", "",current_table[,2])
  current_table[,2] = gsub("\\]", "",current_table[,2])
  #current_table[,3] = gsub("\\[", "",current_table[,3])
  #current_table[,3] = gsub("\\]", "",current_table[,3])
  if (nrow(combined_r10) == 0) {
    combined_r10 = current_table
  } else {
    combined_r10 = merge(combined_r10, current_table, all = T, by = c("genus","species"))
    
  }
}

## This can clean-up and weird taxa that may not have classification at genus-level
combined_r10[1, 1] =  "Eubacteriales Family XIII. Incertae Sedis"
combined_df[2, 1] =  "Lachnospiraceae incertae sedis"
```

This chunk of code is meant to form Pseudo OTU tables. Here I have three options for making one:
>otu_table = just genus-level \
>otu_table_species = just species-level \
>otu_table_all = retains genus and species-level

```
combined_genus2 = combined_r10[-c(2)]
combined_genus2[is.na(combined_genus2)] = 0

#change within [] to all data columns you want numerical
combined_genus2[,2:29] <- sapply(combined_genus2[,2:29],as.numeric)
combined_genus2 = aggregate(as.data.frame(combined_genus2[,-1]), list(genus=combined_genus2[,1]), FUN = sum)
rownames(combined_genus2) = paste0("OTU", 1:nrow(combined_genus2))

combined_species2 = combined_r10[-c(1)]
combined_species2[is.na(combined_species2)] = 0

#change within [] to all data columns you want numerical
combined_species2[,2:29] <- sapply(combined_species2[,2:29],as.numeric)
combined_species2 = aggregate(as.data.frame(combined_species2[,-1]), list(species=combined_species2[,1]), FUN = sum)
rownames(combined_species2) = paste0("OTU", 1:nrow(combined_species2))

combined_all = combined_r10
combined_all[is.na(combined_all)] = 0

#change within [] to all data columns you want numerical
combined_all[,3:30] <- sapply(combined_all[,3:30],as.numeric)
combined_all = aggregate(.~genus + species, as.data.frame(combined_all), sum)
rownames(combined_all) = paste0("OTU", 1:nrow(combined_all))

#create an OTU table/split the table to get only OTUs and Subjects
otu_table = select(combined_genus2, -genus)
otu_table_species = select(combined_species2, -species)
otu_table_all = select(combined_all, -c(species:genus))
```

This little bit will create a pseudo tax-table. Once again, three options here.
```
#crete a taxonomy
taxa = combined_genus2 %>%
  select(1)
taxa[,1] = as.character(taxa[,1])
colnames(taxa) <-c("genus")
taxa=as.matrix(taxa)

taxa_species = combined_species2 %>%
  select(1)
taxa_species[,1] = as.character(taxa_species[,1])
colnames(taxa_species) <-c("species")
taxa_species=as.matrix(taxa_species)

taxa_all = combined_all %>%
  select(c(1,2))
colnames(taxa_all) <-c("Genus", "Species")
taxa_all=as.matrix(taxa_all)
```

Heres the magic here. This will create pseudo phyloseq object and is the actual handoff here.
```
map <- "/Volumes/Petrone 1TB/Dissertation/RRN_paper/emu_output/plate123_subset/map.txt"

## three Phyloseq objects
ps <- phyloseq(otu_table(otu_table, taxa_are_rows=TRUE), tax_table(taxa))
ps_species = phyloseq(otu_table(otu_table_species, taxa_are_rows=TRUE), tax_table(taxa_species))
ps_all = phyloseq(otu_table(otu_table_all, taxa_are_rows=TRUE), tax_table(taxa_all))
sample_metadata = import_qiime_sample_data(map)
sample_metadata$Read.Type = as.factor(sample_metadata$Read.Type)

## three Phyloseq merges
input = merge_phyloseq(ps, sample_metadata)
input_species = merge_phyloseq(ps_species, sample_metadata)
input_all = merge_phyloseq(ps_all, sample_metadata)
```

This little chunk prunes any NULL samples in the metadata and removes exmpty taxa if present
```
OM <- prune_samples(sample_sums(input)>=0, input)
OM = prune_taxa(taxa_sums(OM) > 0, OM)
summarize_phyloseq(OM)
OM
OM = subset_samples(OM, Sample != "NULL")

OM_spp <- prune_samples(sample_sums(input_species)>=0, input_species)
OM_spp = prune_taxa(taxa_sums(OM_spp) > 0, OM_spp)
summarize_phyloseq(OM_spp)
OM_spp = subset_samples(OM_spp, Sample != "NULL")
OM_spp

OM_all <- prune_samples(sample_sums(input_all)>=0, input_all)
OM_all = prune_taxa(taxa_sums(OM_all) > 0, OM_all)
summarize_phyloseq(OM_all)
OM_spp = subset_samples(OM_spp, Sample != "NULL")
OM_all
```


## **Citation**
Please cite both our publication and the github page!!

Publication:
```
Petrone, J. R., Rios-Glusberger, P., Millitich, P. T., Roesch, L. F. W., &amp; Triplett, E. W. (2022). The development and validity of a Nanopore-based pipeline to classify Bacteria through long-read, 16S-ITS-23S rRNA sequencing . In Progress. 
```
Github:
```
Petrone, J. R., &amp; Millitich, P. T. (2022, June 30). Nanopore-RRN-Sequencing. Github. Retrieved from https://github.com/josephpetrone/Nanopore-RRN-Sequncing/ 
```

### **This repo is unaffliated with Oxford Nanopore Technologies Ltd.**



