#!/bin/bash -l

#SBATCH -J combine
#SBATCH --mail-type=ALL
#SBATCH --mail-user=cguccion@ucsd.edu
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --nodes=1
#SBATCH --mem-per-cpu=500000    # memory/cpu (in MB)
#SBATCH --partition=highmem

#Find job array ID
J=$SLURM_ARRAY_TASK_ID
echo 'Job Arary #' $J

<<com
Author: Caitlin Guccione
Date: 1/9/2024
Goal: Helper function to combine 
reads from human and microbial simulation
com

mamba activate human-depletion-lucas

tmp_dir=/panfs/cguccion/23_11_07_HostDepletionBenchmarkOverflow/mixed_simulation_tmp/tmp

############### Human Import

#List of files in pangenome
pan_list=/projects/benchmark-human-depletion/compare_datasets/mix_hum_microbe_sim/source_data/pangenome_subset/fn_list.txt

#Find current file based on ID
pan_file=$human_pan_folder/$(sed -n "${J}p" "$pan_list")

#Extract name of current pangenome
pan_filename_p1=$(basename "$pan_file")
pan_filename_p2=$(echo "$pan_filename_p1" | awk -F'.' '{print $1"."$2}')

#Find the human file
#human_fn=$TEMP_OUT/midpoint_coverages/${perc_hum}p-${pan_filename_p2}_sim
human_fn=$TEMP_OUT/midpoint_coverages/${perc_hum}p-${pan_filename_p2}_MINI_sim

echo "Importing human file: $human_fn"

############### Microbe Import

#Create seed for this microbe subset
R_SEED=$((J+40+SEED))

#Find the microbe file
#microbe_fn=$TEMP_OUT/midpoint_coverages/microbial/${perc_microbe}p-FDA-ARGO-${R_SEED}_sim
microbe_fn=$TEMP_OUT/midpoint_coverages/microbial/${perc_microbe}p-FDA-ARGO-${R_SEED}_MINI_sim

echo "Importing microbe file: $microbe_fn"

############### Subset to correct # of reads

#Subset to correct # of reads for human
#sub_human_fn=${tmp_dir}/${perc_hum}p-${pan_filename_p2}_sim_SUB
sub_human_fn=${tmp_dir}/${perc_hum}p-${pan_filename_p2}_MINI_sim_SUB

#Subset the number of reads you actually want in you dataset
seqtk sample -s100 ${human_fn}_1.fq $((human_read /2)) > ${sub_human_fn}.R1.fastq
seqtk sample -s100 ${human_fn}_2.fq $((human_read /2)) > ${sub_human_fn}.R2.fastq

echo "Subset $human_read human reads"

#Subset to correct # of reads for microbe
#sub_microbe_fn=${tmp_dir}/${perc_microbe}p-FDA-ARGO-${R_SEED}_sim_SUB
sub_microbe_fn=${tmp_dir}/${perc_microbe}p-FDA-ARGO-${R_SEED}_MINI_sim_SUB

#Subset the number of reads you actually want in you dataset
seqtk sample -s100 ${microbe_fn}_1.fq $((microbe_read /2)) > ${sub_microbe_fn}.R1.fastq
seqtk sample -s100 ${microbe_fn}_2.fq $((microbe_read /2)) > ${sub_microbe_fn}.R2.fastq

echo "Subset $microbe_read microbe reads"

<<com
############### Interleave R1/R2 Reads

#Human interleave reads
seqtk mergepe ${sub_human_fn}.R1.fastq ${sub_human_fn}.R2.fastq > ${sub_human_fn}.fastq

#Microbe interleave reads
seqtk mergepe ${sub_microbe_fn}.R1.fastq ${sub_microbe_fn}.R2.fastq > ${sub_microbe_fn}.fastq

#Clean up
echo 'Reads interleaved, removing R1/R2 files'
rm ${sub_human_fn}.R1.fastq ${sub_human_fn}.R2.fastq ${sub_microbe_fn}.R1.fastq ${sub_microbe_fn}.R2.fastq
com

############### Rename Reads as Human/Microbe

#Rename Human
#bioawk -c fastx '{ print "@" $name "_HUMAN" "\n" $seq "\n" "+" "\n" $qual}' ${sub_human_fn}.fastq > ${sub_human_fn}_NAME.fastq
bioawk -c fastx '{ print "@" $name "_HUMAN" "\n" $seq "\n" "+" "\n" $qual}' ${sub_human_fn}.R1.fastq > ${sub_human_fn}_NAME.R1.fastq
bioawk -c fastx '{ print "@" $name "_HUMAN" "\n" $seq "\n" "+" "\n" $qual}' ${sub_human_fn}.R2.fastq > ${sub_human_fn}_NAME.R2.fastq

#Rename Microbe
#bioawk -c fastx '{ print "@" $name "_MICROBE" "\n" $seq "\n" "+" "\n" $qual}' ${sub_microbe_fn}.fastq > ${sub_microbe_fn}_NAME.fastq
bioawk -c fastx '{ print "@" $name "_MICROBE" "\n" $seq "\n" "+" "\n" $qual}' ${sub_microbe_fn}.R1.fastq > ${sub_microbe_fn}_NAME.R1.fastq
bioawk -c fastx '{ print "@" $name "_MICROBE" "\n" $seq "\n" "+" "\n" $qual}' ${sub_microbe_fn}.R2.fastq > ${sub_microbe_fn}_NAME.R2.fastq

#Clean up
echo 'Renamed human/microbe reads, removing fastq non-labled fastq'
#rm ${sub_human_fn}.fastq ${sub_microbe_fn}.fastq
rm ${sub_human_fn}.R1.fastq ${sub_microbe_fn}.R1.fastq ${sub_human_fn}.R2.fastq ${sub_microbe_fn}.R2.fastq

###############

#Combine human and microbe
#final_fn=$TEMP_OUT/final_combo/${perc_hum}p-${pan_filename_p2}_${perc_microbe}p-FDA-ARGO-${R_SEED}_sim
final_fn=$TEMP_OUT/final_combo/${perc_hum}p-${pan_filename_p2}_${perc_microbe}p-FDA-ARGO-${R_SEED}_MINI_sim

#cat ${sub_human_fn}_NAME.fastq ${sub_microbe_fn}_NAME.fastq > ${final_fn}.fastq
cat ${sub_human_fn}_NAME.R1.fastq ${sub_microbe_fn}_NAME.R1.fastq > ${final_fn}.R1.fastq
cat ${sub_human_fn}_NAME.R2.fastq ${sub_microbe_fn}_NAME.R2.fastq > ${final_fn}.R2.fastq

#Remove all un-needed files
echo 'Remove human and microbe indvidual files'
#rm ${sub_human_fn}_NAME.fastq ${sub_microbe_fn}_NAME.fastq
rm ${sub_human_fn}_NAME.R1.fastq ${sub_microbe_fn}_NAME.R1.fastq ${sub_human_fn}_NAME.R2.fastq ${sub_microbe_fn}_NAME.R2.fastq

echo 'Files interleaved, labled and combined'
