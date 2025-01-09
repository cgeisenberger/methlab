#!/bin/bash

REF='/Users/cgeisenberger/Dropbox/Research/projects/taps/revision/output/k562_genes.bed'

echo "Calculating overlap for mapped files"
bedtools intersect -a $REF -filenames -b mapped_reads/*R1*.bam -C > ./overlap_files/mapped_overlap.bed
