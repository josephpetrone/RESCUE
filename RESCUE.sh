#!/bin/bash

############################################################
# Help                                                     #
############################################################

Help()
{
   # Display Help
   echo "RESCUE : Resolving Species Level Classifications Using Emu"
   echo
   echo "This script is intended to be submitted through HPC for the Triplett-lab."
   echo "There are some checkpoints to ensure proper function, but failures might occur."
   echo "Check the log file in ./logs/ to find the error."
   echo "Normally errors will occur with directory structure. Please read below!"
   echo "I miss you Triplett Lab! -Joe Petrone 2022"
   echo
   echo "Syntax: scriptTemplate [-h|i|o|t|m|b|d|s|a|q|r|p]"
   echo
   echo "Please omit final "'/'" from all directory paths!!!"
   echo
   echo "options:"
   echo "-h     Print this Help."
   echo "-i     Directory to input fastq's."
   echo "-o     Directory where you want 'RRN_pipeline' output directories."
   echo "-t     Numerical number of threads. (Default: 5)"
   echo "-m     Total RAM (Ngb) Must include gb after numerical entry (Default: 20gb)"
   echo "-b 	Barcode mismatch error rate max (Cutadapt demultiplexing)"
   echo "	•Error rate X 16 bases = mismatch # (rounded down) (Default: 0.05 = 0.8 = 0 Mismatch)"
   echo "-d     Database options ( RRN_db | EMU_db | RDP )"  
   echo "-s     Slurm submission option ( yes | no )"
   echo "-a	Slurm account to submit under (Default: Triplett)"
   echo "-q	Slurm QOS to submit under (Default: Triplett-b)"
   echo "-r     (Beta) Use command line R for file manipulation ( yes | no )"
   echo "-p     (Optional) path to mapping file if using RStudio"
   echo
   echo "example usage:"
   echo "./RESCUE.sh -i /full/path/to/fastq/directory -o /full/path/to/RRN_pipeline_output -m 50gb -t 40 -d RRN_db -s yes -r yes -p /path/to/mapping.txt"
   echo 
   echo "DO NOT SUBMIT THIS SCRIPT DIRECTLY THROUGH SLURM. USE USAGE ABOVE AND TRUST ME!"
}



# Get the options
while getopts ":h*:i:o:t:m:d:s:r:" option; do   	
   case $option in
      h) # Display Help
	 Help
         exit;;
      i) # fastq directory
         fastq_dir=$OPTARG;;
      o) # Enter an output directory
         output_dir=$OPTARG;;
      t) # Enter threads
	 threads=$OPTARG;;
      m) # Memory
	 mem=$OPTARG;;
      b) # barcode
         barcode=$OPTARG;;
      d)# Database
	 database=$OPTARG;;
      s) # Submit to slurm
	 slurm=$OPTARG;;
      r) # Rstudio output
	 rstudio=$OPTARG;;
      p) # mapping
	 mapping=$OPTARG;;
      a) # slurm account
         account=$OPTARG;;
      q) # slurm qos
         qos=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done


if [ -z "${fastq_dir:+x}" ]; then
        echo "Fatal Error: Please provide fastq directory and try again :)"
	exit
else
    	echo "Check 1: launch complex check..."
	echo "Check 1: directory location=$fastq_dir"
fi

if [ -z "${output_dir:+x}" ]; then
        echo "Fatal Error: Please provide output directory and try again :)"
	exit
else
        echo "Check 2: launch systems check..."
	echo "Check 2: ouput location=$output_dir"
fi

if [ -z "${threads:+x}" ]; then 
	echo "ERROR: Please provide thread number and try again :); otherwise presumed 5 threads"
	threads=5
else 
	echo "Check 3: fuel systems check..."
	echo "Check 3: CPU fuel level=$threads"
fi

if [ -z "${mem:+x}" ]; then
        echo "ERROR: Please provide RAM usage and try again :); otherwise presumed 20gb"
        mem=20gb
else
    	echo "Check 4: fuel systems check2..."
        echo "Check 4: RAM fuel level=$mem"
fi

if [ -z "${database:+x}" ]; then
        echo "ERROR: Please provide database name"
        exit
else
        echo "Check 5: cargo hold check..."
	echo "$database database selected"
	echo "Liftoff"
fi

if [ -z "${mapping:+x}" ]; then
        echo "ERROR: Will still run but without merging mapping file to Phyloseq Object"
else
    	echo "Mapping file found at $mapping"
fi

if [ -z "${barcode:+x}" ]; then
        echo "Default demultiplexing at 0 mismatches"
	barcode=0.05
else
	echo "$barcode 16" | awk '{print "Demultiplexing with " int($1 * $2) " mismatches"}'
fi

if [ -z "${account:+x}" ]; then
        account=triplett
	echo "If submitting to slurm, account will default to $account"
else
    	echo "Account is set to $account"
fi
if [ -z "${qos:+x}" ]; then
	qos=triplett-b
        echo "If submitting to slurm, QOS will default to $qos"
else
    	echo "QOS is set to $qos"
fi


echo "RESCUE Initiation"
if [[ $slurm == y* ]]; then
   sbatch -A $account \
	--qos=$qos \
	--out=/blue/triplett/share/rrn_analysis/RESCUE/logs/RESCUE_Submission_%j.log  \
	--mem=$mem \
	--cpus-per-task=$threads \
	--job-name=RESCUE_SBATCH \
	--time=48:00:00 \
	--export=fastq_dir=$fastq_dir,output_dir=$output_dir,database=$database,rstudio=$rstudio,threads=$((threads - 1)),mapping=$mapping,barcode=$barcode \
	/blue/triplett/share/rrn_analysis/RESCUE/sbatch/RESCUE_slurm.sh
   echo "About to submit to slum, find log at ./logs/RESCUE_Submission_SLURM_ID.log"
else
   echo "Initiating on local machine"

#############################################
### MAIN PROGRAM
#############################################

## Please do not change me unless you're absolutely sure
## Path to cutadapt  barcode fasta
barcodes=./barcodes_linked2.fa

working_dir=$output_dir/RRN_pipeline

cd $output_dir



#############################################
############# READ SPLITTING ################
#############################################

mkdir RRN_pipeline
cd $working_dir
mkdir ./1-duplextools
echo $pwd

### duplex-tools
conda activate RESCUE

## Split 1
duplex_tools split_on_adapter --threads $threads \
	--allow_multiple_splits \
	$fastq_dir/ \
	$working_dir/1-duplextools/split1 \
	Native

## Split 2
duplex_tools split_on_adapter --threads $threads \
        --allow_multiple_splits \
        $working_dir/1-duplextools/split1 \
        $working_dir/1-duplextools/split2 \
        Native
rm -r $working_dir/1-duplextools/split1

## Split 3
duplex_tools split_on_adapter --threads $threads \
        --allow_multiple_splits \
        $working_dir/1-duplextools/split2 \
        $working_dir/1-duplextools/split3 \
        Native
rm -r $working_dir/1-duplextools/split2

## Split 4
duplex_tools split_on_adapter --threads $threads \
        --allow_multiple_splits \
        $working_dir/1-duplextools/split3 \
        $working_dir/1-duplextools/split4 \
        Native
rm -r $working_dir/1-duplextools/split3

## Split 5
duplex_tools split_on_adapter --threads $threads \
        --allow_multiple_splits \
        $working_dir/1-duplextools/split4 \
        $working_dir/1-duplextools/split5 \
        Native
rm -r $working_dir/1-duplextools/split4

## Split 6
duplex_tools split_on_adapter --threads $threads \
        --allow_multiple_splits \
        $working_dir/1-duplextools/split5 \
        $working_dir/1-duplextools/split6 \
        Native
rm -r $working_dir/1-duplextools/split5

## Split 7
duplex_tools split_on_adapter --threads $threads \
        --allow_multiple_splits \
        $working_dir/1-duplextools/split6 \
        $working_dir/1-duplextools/split7 \
        Native
rm -r $working_dir/1-duplextools/split6

## Split 8
duplex_tools split_on_adapter --threads $threads \
        --allow_multiple_splits \
        $working_dir/1-duplextools/split7 \
        $working_dir/1-duplextools/split8 \
        Native
rm -r $working_dir/1-duplextools/split7

## Split 9
duplex_tools split_on_adapter --threads $threads \
        --allow_multiple_splits \
        $working_dir/1-duplextools/split8 \
        $working_dir/1-duplextools/split9 \
        Native
rm -r $working_dir/1-duplextools/split8

## Split 10
duplex_tools split_on_adapter --threads $threads \
        --allow_multiple_splits \
        $working_dir/1-duplextools/split9 \
        $working_dir/1-duplextools/split10 \
        Native
rm -r $working_dir/1-duplextools/split9

##In case we ever want to remove this 9 step function
#for i in {2..10}
#do
#   duplex_tools split_on_adapter --threads $threads \
#        --allow_multiple_splits \
#        $working_dir/1-duplextools/split_$((i-1)) \
#        $working_dir/1-duplextools/split_$i \
#        Native
#   echo 'Split-no: $i'
#done



####This splitting needs to be ran until no more reads are split ~10 times
####Change the -input -output so that splitting is done on the output of the previous  iteration 



#############################################
############# File Manipulation #############
#############################################

cd $working_dir/1-duplextools/split10
mkdir all
zcat ./*.fastq.gz > ./all/split10_all.fastq


#############################################
############ RE-FILTER READS ################
#############################################
### NanoFilt
## -q = Q-score cutoff
## --readtype (1D,2D,1D2)

cd $working_dir
mkdir 2-nanofilt

cat $working_dir/1-duplextools/split10/all/* | NanoFilt -q 10 --readtype 1D > $working_dir/2-nanofilt/split_filtered.fastq


#############################################
################ DEMULTIPLEX ################
#############################################
### Nanoplexer
## -b = multi-fasta containing all barcodes used (correct orientation for top and bottom strands)
## -d = a txt file containing the primer combination and what the sample should be named


cd  $working_dir
mkdir $working_dir/3-demultiplexed

cutadapt -j $threads \
	--action=none \
	-O 16 \
	-e $barcode \
	--no-indels \
	--revcomp \
	-m 3000 \
	-M 7000 \
	-g file:$barcodes \
	-o $working_dir/3-demultiplexed/combined.demuxed_{name}.fastq \
	$working_dir/2-nanofilt/split_filtered.fastq


########################################################   
################ ADAPTER-PRIMER REMOVAL ################
########################################################
### Cutadapt
# -e = error
# -O = min overlap
# -o = output
# -a = primer1...Reverse_complement_of_primer2
# -m = minimum read length
# -M = maximum read length
# --revcomp = If primers found on bottom strand, reorient to top stand 

mkdir $working_dir/4-trimmed

cd $working_dir/3-demultiplexed

## Loop through demultiplexed fastq files


for file in *.*
do
	cutadapt -j $threads \
	-e 0.2 \
	-O 15 \
	--revcomp \
	-o $working_dir/4-trimmed/trimmed.$file \
	-g AGRRTTYGATYHTDGYTYAG...CGTCGTGAGACAGKTYGG \
	$file
done

######################################################
################ TAXONOMIC CLASSIFIER ################
######################################################
### EMU
## --type = (map-ont, sr, map-bp)
## --min-abundance = threshold for min-abundance
## --db = database folder
## --N = max alignments for each read
## --K = batch size for minimap
## --output-dir = output directory
## --keep-counts = needed to get abundance
## --keep-read-assignments = keep this here; gives you probablility of each read classification 

cd $working_dir
## Load and activate conda emu enviroment

# Loop through demultiplexed fastq files
## Giving it all the files at once is too large of a "filename"

for empanada in $working_dir/4-trimmed/*
do
	emu abundance --type map-ont \
		--keep-counts \
		--keep-read-assignments \
		--threads $threads \
		$empanada \
		--db /blue/triplett/share/rrn_analysis/RESCUE/databases/$database \
		--output-dir $working_dir/5-emu/
done

## Shutdown conda environment
conda deactivate

fi

if [[ $rstudio == y* ]]; then
   mv $working_dir/5-emu/*unknown.rel-abundance.tsv $working_dir
   mkdir $working_dir/6-rstudio
   module load R
   Rscript /blue/triplett/share/rrn_analysis/RESCUE/sbatch/RESCUE.R \
   $working_dir/5-emu/ $working_dir/6-rstudio/ $mapping
else
   echo "No Rstudio Today..."
   exit

