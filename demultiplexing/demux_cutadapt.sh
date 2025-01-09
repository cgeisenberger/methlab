#!/bin/bash

barcode_file="/media/Leia/cgeisenberger/files/scbs_multiplexed_barcode_sequences.fasta"
indices=$(ls -alh *umitools.fastq.gz | grep -oE "^[^_]*_S[0-9]{1,2}" | uniq)

for prefix in $indices
do
  r1=${prefix}_R1_umitools.fastq.gz
  r2=${prefix}_R2_umitools.fastq.gz
  cutadapt -e 1 -g ^file:${barcode_file} -o ${prefix}_{name}_R1.fastq.gz -p ${prefix}_{name}_R2.fastq.gz $r1 $r2
done



