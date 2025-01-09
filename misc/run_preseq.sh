#!/bin/bash

STEP_SIZE=200000
LIMIT_READS=20000000

for f in *.sorted.bam
do 
  bn=$(basename -s .bam ${f})
  preseq lc_extrap -s $STEP_SIZE -e $LIMIT_READS -o "${bn}_future_yield.txt" -B $f
done
