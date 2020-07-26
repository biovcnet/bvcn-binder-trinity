#!bin/bash


for prefix in `ls *1.fastq | cut -f1,2 -d'.' | sort -u`; do
  echo ${prefix}
  R1=( ${prefix}.1 )
  R2=( ${prefix}.2 )


echo Checking initial read quality 

#Check the quality of the sequenced reads
fastqc ${R1}.fastq ${R2}.fastq -o 00_QC_RawReads/

echo Moving to rcorrector

#run rcorrector to identify and correct errors
run_rcorrector.pl -1 ${R1}.fastq -2 ${R2}.fastq -od 00_QC_CorrectedReads

echo Removing "uncorrectable reads" using FilterUncorrectabledPEfastq.py script from TranscriptomeAssemblyTools.git 

#remove uncorrectable reads

cd 00_QC_CorrectedReads
python2 ../Programs/TranscriptomeAssemblyTools/FilterUncorrectabledPEfastq.py -1 ${R1}.cor.fq -2 ${R2}.cor.fq -s ${R1}

cd ../

echo Check the quality of the corrected reads

#Check the quality of the corrected reads
fastqc 00_QC_CorrectedReads/unfixrm_${R1}.cor.fq 00_QC_CorrectedReads/unfixrm_${R2}.cor.fq -o 00_QC_CorrectedReads/

echo run the Cutadapt wrapper TrimGalore 

#remove left over sequencing adapters and low quality reads
trim_galore --paired --retain_unpaired --phred33 --output_dir 01_TrimmedReads --length 36 -q 5 --stringency 1 -e 0.1 00_QC_CorrectedReads/unfixrm_${R1}.cor.fq 00_QC_CorrectedReads/unfixrm_${R2}.cor.fq

echo Check the quality of the corrected and trimmed reads
fastqc 01_TrimmedReads/unfixrm_${R1}.cor_val_1.fq 01_TrimmedReads/unfixrm_${R2}.cor_val_2.fq -o 00_QC_TrimmedReads/

echo Merging reads for SortMeRNA
#Merge the paired-end reads for sortMeRNA
merge-paired-reads.sh 01_TrimmedReads/unfixrm_${R1}.cor_val_1.fq 01_TrimmedReads/unfixrm_${R2}.cor_val_2.fq 02_SortMeRNA/${prefix}_merged.fq

echo Run SortMeRNA using the indexed rRNA databases
#run sortmerna to remove carry over rRNA
sortmerna --reads 02_SortMeRNA/${prefix}_merged.fq \
--ref \
Programs/sortmerna/data/rRNA_databases/silva-bac-16s-id90.fasta,Programs/sortmerna/data/index/silva-bac-16s-db:\
Programs/sortmerna/data/rRNA_databases/silva-bac-23s-id98.fasta,Programs/sortmerna/data/index/silva-bac-23s-db:\
Programs/sortmerna/data/rRNA_databases/silva-arc-16s-id95.fasta,Programs/sortmerna/data/index/silva-arc-16s-db:\
Programs/sortmerna/data/rRNA_databases/silva-arc-23s-id98.fasta,Programs/sortmerna/data/index/silva-arc-23s-db:\
Programs/sortmerna/data/rRNA_databases/silva-euk-18s-id95.fasta,Programs/sortmerna/data/index/silva-euk-18s-db:\
Programs/sortmerna/data/rRNA_databases/silva-euk-28s-id98.fasta,Programs/sortmerna/data/index/silva-euk-28s:\
Programs/sortmerna/data/rRNA_databases/rfam-5.8s-database-id98.fasta,Programs/sortmerna/data/index/rfam-5.8s-db:\
Programs/sortmerna/data/rRNA_databases/rfam-5s-database-id98.fasta,Programs/sortmerna/data/index/rfam-5s-db \
--paired_in --fastx --aligned 02_SortMeRNA/${prefix}_rRNA \
--other 02_SortMeRNA/${prefix}_non_rRNA --log

echo Unmerge reads for SortMeRNA

unmerge-paired-reads.sh 02_SortMeRNA/${prefix}_non_rRNA.fq 03_Assembly/${prefix}_R1.fq 03_Assembly/${prefix}_R2.fq

echo Check the quality of the corrected and trimmed and rRNA filtered reads

fastqc 03_Assembly/${prefix}_R1.fq 03_Assembly/${prefix}_R2.fq -o 03_Assembly

#run MultiQC to generate a QC report
multiqc -d -s 0*

cd 03_Assembly
Trinity --seqType fq --left ${prefix}_R1.fq --right ${prefix}_R2.fq --max_memory 1G 

$TRINITY_HOME/util/TrinityStats.pl  trinity_out_dir/Trinity.fasta

done







