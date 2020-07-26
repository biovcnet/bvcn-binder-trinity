#!bin/bash

for prefix in `ls *reads1_subsamp.fastq | cut -f1,2 -d'_' | sort -u`; do
  echo ${prefix}
  R1=( ${prefix}_reads1_subsamp )
  R2=( ${prefix}_reads2_subsamp )
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

unmerge-paired-reads.sh 02_SortMeRNA/${prefix}_non_rRNA 03_Assembly/${prefix}_R1.fq 03_Assembly/${prefix}_R2.fq

cd 03_Assembly
mkdir Trinity

Trinity --seqType fq --left ${prefix}_R1.fq --right ${prefix}_R2.fq --CPU 6 --max_memory 20G 

done
