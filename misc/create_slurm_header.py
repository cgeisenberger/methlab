#!/usr/bin/env python3

import argparse

parser = argparse.ArgumentParser(description="A simple script to create a header for SLURM deployment")

parser.add_argument("-c", "--cores", default=1, type=int, help="Number of CPU cores (default: 1)")
parser.add_argument("-t", "--time", default=1, type=int, help="Time limit of job [hours] (default: 1)")
parser.add_argument("-m", "--memory", default=4, type=int, help="Memory allocated for jobs [gigabytes](default: 4)")
parser.add_argument("-j", "--job_name", default="default_string", type=str, help="Job Name")



#!/usr/bin/env bash
#
# Custom SLURM header

#SBATCH --job-name=tapsTabulator_array
#SBATCH --output=tapsTabulator_array_%A_%a.out
#SBATCH --error=tapsTabulator_array_%A_%a.err
#SBATCH --array=1-25
#SBATCH --time=12:00:00
#SBATCH --mem=8G
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1