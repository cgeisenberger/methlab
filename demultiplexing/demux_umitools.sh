#!/bin/bash

bc="NNNNXXXXXXXXNNNNNN"

for r1 in *R1_001.fastq.gz
do
  bn=$(basename -s _R1_001.fastq.gz ${r1})
  r2=${bn}_R2_001.fastq.gz
  umi_tools extract --bc-pattern=${bc} --stdin=${r1} --read2-in=${r2} --stdout=${bn}_R1_umitools.fastq.gz --read2-out=${bn}_R2_umitools.fastq.gz --log=${bn}_umitools.log
done



