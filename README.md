# **RESCUE**
Resolving \
Species-level \
Classification \
Using \
Emu

Updated pipeline and Methods for 16S-ITS-23S rRNA Nanopore Sequencing with Custom Barcodes.

Last update: January 20, 2023

This repo serves as a functional pipeline to perform bacterial classification and abundance analysis using Nanopore sequencing technologies. The pipeline was created specifically to use custom barcoded RRN amplicons to sequence using Nanopore. The primers listed here create a 4,500bp fragment containing the entire 16S rRNA, the intergenic spacer region, and most of the 23s rRNA. Theoretically, any primers you choose can work for this pipeline as long as contraints in the programs are changed. For further information about the pipeline and the results of a validation study, please visit (and cite) the following publications from the Triplett Lab:

```
RESCUE: a Validated Nanopore Pipeline to Classify Bacteria Through Long-Read, 16S-ITS-23S rRNA Sequencing (2022)
```
[Detailed Steps](https://github.com/josephpetrone/RESCUE/blob/master/detailed_steps.md) for full individual explanations

## **1. Installation**
This package is intented to be installed onto HPC systems with necessary programs listed as modules. \
However, this shell script can run locally after installing all programs into local conda environments

### **1a. Local Installations** 
We will install all of the required programs into a conda environment
Create a conda environment. Please run these EXACTLY as shown below.
```
conda create -n RESCUE python=3.7 emu cutadapt
CONDA_BASE=$(conda info --base)
conda activate RESCUE
conda config --add channels defaults
conda config --add channels bioconda
conda config --add channels conda-forge
conda install -c bioconda duplex-tools nanofilt
```
## **2. Downloading RESCUE Files**
```
git clone https://github.com/josephpetrone/RESCUE.git
cd ./RESCUE
wget https://www.dropbox.com/s/f4oyl8ufj6bzqtz/databases.tar.gz
tar –xvzf ./databases.tar.gz
```

## **3. Testing install**
Once this finishes, RESCUE can be ran as a local installation

```
cd /path/to/RESCUE/
conda activate RESCUE
./RESCUE.sh -h
```
## **4. Quick Test Run**
```
cd /path/to/RESCUE/
conda activate RESCUE
./RESCUE.sh -i /path/to/RESCUE/test/input/fastq -o /path/to/RESCUE/test/output -m 10gb -t 4 -d RRN_db -s no -r yes

MAKE SURE TO PROVIDE THE ENTIRE PATH TO THE INSTALLATION. SIMPLY PUTTING "./" WILL NOT WORK
```
## **5. Full Options**
Syntax: scriptTemplate [-h|i|o|t|m|b|d|s|a|q|r|p] \
Please omit final / from all directory paths!!! \

options:\
-h&emsp;Print this Help.\
-i&emsp;Directory to input fastq's.\
-o&emsp;Directory where you want 'RRN_pipeline' output directories.\
-t&emsp;Numerical number of threads. (Default: 5)\
-m&emsp;Total RAM (Ngb) Must include gb after numerical entry (Default: 20gb)\
-b&emsp;Barcode mismatch error rate max (Cutadapt demultiplexing)\
&emsp;&emsp;•Error rate X 16 bases = mismatch # (rounded down) (Default: 0.05 = 0.8 = 0 Mismatch)\
-d&emsp;Database options ( RRN_db | EMU_db | RDP )\
-s&emsp;Slurm submission option ( yes | no )\
-a&emsp;&emsp;Slurm account to submit under (Default: Triplett)\
-q&emsp;&emsp;Slurm QOS to submit under (Default: Triplett-b)\
-r&emsp;(Beta) Use command line R for file manipulation ( yes | no )\
-p&emsp;(Optional) path to mapping file if using RStudio\

example usage:
```
./RESCUE.sh -i /full/path/to/fastq/directory \
-o /full/path/to/RRN_pipeline_output \
-m 50gb \
-t 40 \
-d RRN_db \
-s no \
-r yes \
-p /path/to/mapping.txt \
-b 0.5 
```
DO NOT SUBMIT THIS SCRIPT DIRECTLY THROUGH SLURM. USE USAGE ABOVE AND TRUST ME!

## **5. Adding Databases**
For the current version of RESCUE, three databases are available:\
1. RRN_db
2. EMU_db
3. RDP \
For use of additional databases such as SILVA or UNITE, please visit https://gitlab.com/treangenlab/emu and download database files directly to "/path/to/RESCUE/databases/database_name" and call using folder name. \
Additionally, one RESCUE environment is loaded, you can use default EMU commands to make a database.

