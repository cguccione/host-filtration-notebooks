#!/bin/bash -l

#Find job array ID
#Submit each of these 2,3,4,5,6,7
#Already submitted human: 7,6,5,4,3,2
#Already submitted microbe: 2,3,4,5,6,7
#Already submiited combo: 7,6,4,2,3, (use Microbe ART seed when submittig)
J=7
echo 'Job Arary #' $J

#Seed for reproduction in ART
SEED=40

<<com
Author: Caitlin Guccione
Date: 1/8/2024
Goal: To create simulated data for human/microbome
split in paper. More info: 
https://docs.google.com/spreadsheets/d/1x0W6j2dg9fOyjagcfBmRyn_f-BWWvPs5kwRz4RzP4zc/edit#gid=1769283887
com

#File containing all human/microbe read splits
tsv_read='human_microbe_read_split.tsv'

#File containing all human/microbe coverages
tsv_cover='human_microbe_coverage_split.tsv'

#Folder with human pangenomes
human_pan_folder=/projects/benchmark-human-depletion/compare_datasets/mix_hum_microbe_sim/source_data/pangenome_subset

#ART Tool
ART=/projects/benchmark-human-depletion/caitlin_sim_testing/daniel_tcga_rerun/art/art_bin_MountRainier/art_illumina

#Ouput path
TEMP_OUT=/panfs/cguccion/23_11_07_HostDepletionBenchmarkOverflow/mixed_simulation_tmp
FINAL_OUT=/projects/benchmark-human-depletion/compare_datasets/mix_hum_microbe_sim/ART/art_output

#Seq Error profiles (optional- Taken from Qiyun's advice to use this paper: CAMISIM)
#More info here: https://docs.google.com/document/d/10jO9G5KVNm5-gGyPHbzsOn9XXArNC-SVwDkda3R8GJw/edit
SEQ1=/projects/benchmark-human-depletion/caitlin_sim_testing/seq_error_profiles/ART_MBARC-26_HiSeq_R1.txt
SEQ2=/projects/benchmark-human-depletion/caitlin_sim_testing/seq_error_profiles/ART_MBARC-26_HiSeq_R2.txt

#Get line with current SLURM array task ID
read_line=$(sed -n "${J}p" "$tsv_read")

#Extract Human and Microbe read # from the line
IFS=$'\t' read -r human_read microbe_read <<< "$read_line"
echo "Human Reads: $human_read"
echo "Microbal Reads: $microbe_read"

#Get line with current SLURM array task ID
read_cover=$(sed -n "${J}p" "$tsv_cover")

#Extract Human and Microbe coverage # from the line
IFS=$'\t' read -r human_coverage microbe_coverage <<< "$read_cover"
echo "Human Coverage: $human_coverage"
echo "Microbal Coverage: $microbe_coverage"

#Calcualte the percent human and microbial
perc_hum=$(awk "BEGIN {printf \"%.2f\", $human_read / ($human_read + $microbe_read) * 100}")
perc_microbe=$(awk "BEGIN {printf \"%.2f\", $microbe_read / ($human_read + $microbe_read) * 100}")

#Each script below was run seperate and run 6x : one for each human/microbial breakdown 

<<com
#Submit an array for the 20 simulations for this human read breakdown
sbatch \
   -J art_mid \
   --array 1-20 \
   --export ART=${ART},human_pan_folder=${human_pan_folder},TEMP_OUT=${TEMP_OUT},perc_hum=${perc_hum},human_read=${human_read},human_coverage=${human_coverage},SEQ1=${SEQ1},SEQ2=${SEQ2},SEED=${SEED},perc_microbe=${perc_microbe},microbe_read=${microbe_read} \
   ART_pangenome_helper.sbatch
com

<<com
#Submit an array for the 20 simulations for the microbe read breakdown
sbatch \
   -J art_microbe \
   --array 1-20 \
   --export SEED=${SEED},ART=${ART},human_pan_folder=${human_pan_folder},TEMP_OUT=${TEMP_OUT},perc_hum=${perc_hum},human_read=${human_read},human_coverage=${human_coverage},SEQ1=${SEQ1},SEQ2=${SEQ2},perc_microbe=${perc_microbe},microbe_read=${microbe_read},microbe_coverage=${microbe_coverage} \
   ART_microbe_helper.sbatch   
com


#Subset approriate # of reads for each file and combine human/microbe
sbatch \
   -J combine \
   --array 1-20 \
   --export SEED=${SEED},ART=${ART},human_pan_folder=${human_pan_folder},TEMP_OUT=${TEMP_OUT},perc_hum=${perc_hum},human_read=${human_read},human_coverage=${human_coverage},SEQ1=${SEQ1},SEQ2=${SEQ2},perc_microbe=${perc_microbe},microbe_read=${microbe_read},microbe_coverage=${microbe_coverage} \
   combine_helper.sbatch


echo 'done'
