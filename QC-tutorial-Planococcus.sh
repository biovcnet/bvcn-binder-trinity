#!/bin/bash

## Before we start ##
#We are going to clone a collection of scripts from Adam Freedmans github as well as the sortmerna rRNA databases which we have to index

cd data/paired-end-data

git clone https://github.com/harvardinformatics/TranscriptomeAssemblyTools.git

#wget https://github.com/biocore/sortmerna/archive/2.1.tar.gz
#OR
git clone https://github.com/biocore/sortmerna.git
cd sortmerna/data/
mkdir index
indexdb_rna --ref ./rRNA_databases/silva-bac-16s-id90.fasta,./index/silva-bac-16s-db:\
./rRNA_databases/silva-bac-23s-id98.fasta,./index/silva-bac-23s-db:\
./rRNA_databases/silva-arc-16s-id95.fasta,./index/silva-arc-16s-db:\
./rRNA_databases/silva-arc-23s-id98.fasta,./index/silva-arc-23s-db:\
./rRNA_databases/silva-euk-18s-id95.fasta,./index/silva-euk-18s-db:\
./rRNA_databases/silva-euk-28s-id98.fasta,./index/silva-euk-28s:\
./rRNA_databases/rfam-5s-database-id98.fasta,./index/rfam-5s-db:\
./rRNA_databases/rfam-5.8s-database-id98.fasta,./index/rfam-5.8s-db

cd ../../

#For the paired-end reads within the test data folder named "paired-end-data" we will run a for loop for two files that are appended .fastq
#RNA_reads.sample.1.fastq
#RNA_reads.sample.2.fastq

for prefix in `ls *1.fastq | cut -f1,2 -d'.' | sort -u`; do
  echo ${prefix}
  R1=( ${prefix}.1 )
  R2=( ${prefix}.2 )
mkdir 00_QC_RawReads
mkdir 00_QC_TrimmedReads
mkdir 00_QC_CorrectedReads
mkdir 01_TrimmedReads
mkdir 02_SortMeRNA
mkdir 03_Assembly

#Check the quality of the sequenced reads
fastqc ${R1}.fastq ${R2}.fastq -o 00_QC_RawReads/

#run rcorrector to identify and correct errors
run_rcorrector.pl -t 70 -1 ${R1}.fastq -2 ${R2}.fastq

#remove uncorrectable reads
python2 TranscriptomeAssemblyTools/FilterUncorrectabledPEfastq.py -1 ${R1}.cor.fq -2 ${R2}.cor.fq -s ${R1}
fastqc unfixrm_${R1}.cor.fq unfixrm_${R2}.cor.fq -o 00_QC_CorrectedReads/

#remove left over sequencing adapters and low quality reads
trim_galore --paired --retain_unpaired --phred33 --output_dir 01_TrimmedReads --length 36 -q 5 --stringency 1 -e 0.1 unfixrm_${R1}.cor.fq unfixrm_${R2}.cor.fq
fastqc 01_TrimmedReads/unfixrm_${R1}.cor_val_1.fq 01_TrimmedReads/unfixrm_${R2}.cor_val_2.fq -o 00_QC_TrimmedReads/

#Merge the paired-end reads for sortMeRNA
merge-paired-reads.sh 01_TrimmedReads/unfixrm_${R1}.cor_val_1.fq 01_TrimmedReads/unfixrm_${R2}.cor_val_2.fq 02_SortMeRNA/${prefix}_merged.fq

#run sortmerna
sortmerna --reads 02_SortMeRNA/${prefix}_merged.fq \
--ref \
sortmerna/data/rRNA_databases/silva-bac-16s-id90.fasta,sortmerna/data/index/silva-bac-16s-db:\
sortmerna/data/rRNA_databases/silva-bac-23s-id98.fasta,sortmerna/data/index/silva-bac-23s-db:\
sortmerna/data/rRNA_databases/silva-arc-16s-id95.fasta,sortmerna/data/index/silva-arc-16s-db:\
sortmerna/data/rRNA_databases/silva-arc-23s-id98.fasta,sortmerna/data/index/silva-arc-23s-db:\
sortmerna/data/rRNA_databases/silva-euk-18s-id95.fasta,sortmerna/data/index/silva-euk-18s-db:\
sortmerna/data/rRNA_databases/silva-euk-28s-id98.fasta,sortmerna/data/index/silva-euk-28s:\
sortmerna/data/rRNA_databases/rfam-5.8s-database-id98.fasta,sortmerna/data/index/rfam-5.8s-db:\
sortmerna/data/rRNA_databases/rfam-5s-database-id98.fasta,sortmerna/data/index/rfam-5s-db \
--paired_in --fastx --aligned 02_SortMeRNA/${prefix}_rRNA \
--other 02_SortMeRNA/${prefix}_non_rRNA -m 4096 --log

unmerge-paired-reads.sh 02_SortMeRNA/${prefix}_non_rRNA.fq 03_Assembly/${prefix}_R1.fq 03_Assembly/${prefix}_R2.fq

cd 03_Assembly
mkdir Trinity

Trinity --seqType fq --left ${prefix}_R1.fq --right ${prefix}_R2.fq --CPU 6 --max_memory 20G 

done

#run MultiQC to generate a QC report
multiqc .
