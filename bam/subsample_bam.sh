#!/bin/bash

# Set the directory containing BAM files
input_dir="./deduplicated"
output_dir="./subsampled"

# Create the output directory if it doesn't exist
mkdir -p "$output_dir"

# Number of reads to subsample
num_reads=1000000

# Iterate over BAM files in the input directory
for bam_file in "$input_dir"/*.bam; do
  # Get the base name of the BAM file (without path and extension)
  base_name=$(basename "$bam_file" .bam)

  # Create the output file name
  output_file="$output_dir/${base_name}_subsampled.bam"

  # Subsample the BAM file using samtools
  samtools view -bs 42.${num_reads} "$bam_file" > "$output_file"

  # Index the subsampled BAM file
  samtools index "$output_file"

  echo "Subsampled $bam_file -> $output_file"
done

echo "All BAM files have been subsampled."
