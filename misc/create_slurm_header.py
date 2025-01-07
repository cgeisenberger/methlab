#!/usr/bin/env python3

import argparse
import sys
import os




def main():
    parser = argparse.ArgumentParser(description="A simple script to create a header for SLURM deployment")

    parser.add_argument("-n", "--n_tasks", default=1, type=int, help="Number of tasks (default: 1)")
    parser.add_argument("-c", "--cores", default=1, type=int, help="CPUs per task (default: 1)")
    parser.add_argument("-t", "--time", default=1, type=int, help="Time limit of job [hours] (default: 1)")
    parser.add_argument("-m", "--memory", default=4, type=int, help="Memory allocated for jobs [gigabytes](default: 4)")
    parser.add_argument("-j", "--job_name", default="anonymous_job", type=str, help="Job Name (default: 'anonymous_job')")
    parser.add_argument("-f", "--force", action="store_true", help="Overwrite output file if it exists (default: off)")
    parser.add_argument("filename", help="Name of output file (will be overwritten if '-f' or '--force' is set)")

    args = parser.parse_args()


    # Check if output file exists
    if os.path.exists(args.filename):
        if args.force:
            # if --force flag is set, delete the file and write new output
            print("File already exists, --force flag set, data will be overwritten")
            os.remove(args.filename)
            write_slurm_header(args)
        else:
            sys.stderr.write("Error: Output file exists, use --force to enable overwriting!\n")
            sys.exit(1) 
    else:
        write_slurm_header(args)


def write_slurm_header(args):
    with open(args.filename, "w") as file:
        file.write(f"#!/usr/bin/env bash \n")
        file.write(f"# \n")
        file.write(f"# Custom SLURM submission header \n\n\n")
        file.write(f"#SBATCH --job-name={args.job_name}\n")
        file.write(f"#SBATCH --output={args.job_name}.out\n")
        file.write(f"#SBATCH --error={args.job_name}.err\n")
        file.write(f"#SBATCH --time={args.time}:00:00\n")
        file.write(f"#SBATCH --mem={args.memory}G\n")
        file.write(f"#SBATCH --ntasks={args.n_tasks}\n")
        file.write(f"#SBATCH --cpus-per-task={args.cores}\n")

if __name__ == "__main__":
    main()