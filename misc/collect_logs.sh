#!/bin/bash

# create directories
mkdir log
mkdir log/trimming
mkdir log/mapping
mkdir log/deduplication

#  move files
mv mapped_reads/*.txt log/mapping/
mv trimmed_reads/*.txt log/trimming/
mv deduplicated_reads/*.txt log/deduplication/
