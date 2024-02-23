#!/bin/bash -l

#SBATCH -J gzip-files
#SBATCH --time 1:00:00
#SBATCH --mem 20gb
#SBATCH --mail-type=ALL
#SBATCH --mail-user=cguccion@ucsd.edu
#SBATCH --partition=highmem
#SBATCH --array=41-60 #1-20 #Adjust based on # of files in folder

<<com
Date: 1/15/2024
Author: Caitlin Guccione
Goal: To gzip all files in given folder
com

gzip_path=/panfs/cguccion/23_11_07_HostDepletionBenchmarkOverflow/mixed_simulation_tmp/final_combo/paired_MINI_0.05p-HUMAN_99.95p-MICROBE/raw

cd ${gzip_path}
 
files=(*)

# Get the current file for this array task
file_index=$((SLURM_ARRAY_TASK_ID - 1))
current_file="${files[$file_index]}"

echo "Compressed: $current_file"
gzip "$current_file"

echo "Compression complete."

