#!/bin/bash -l

#SBATCH -J art_microbe
#SBATCH --mail-type=ALL
#SBATCH --mail-user=cguccion@ucsd.edu
#SBATCH --time=24:00:00
#SBATCH --ntasks=1
#SBATCH --nodes=1

#Find job array ID
J=$SLURM_ARRAY_TASK_ID
echo 'Job Arary #' $J

<<com
Author: Caitlin Guccione
Date: 1/8/2024
Goal: Helper function which starts each of the 
20 random seeds for commands for ART
com

mamba activate human-depletion-lucas

#Combo of all microbes file
microbe_source=/projects/benchmark-human-depletion/compare_datasets/mix_hum_microbe_sim/source_data/FDA-ARGOS/GCF_combo.fna

#Create seed for this round
R_SEED=$((J+40+SEED))

#Create middle output fn [only use the mini one when running #7]
#mid_fn=$TEMP_OUT/midpoint_coverages/microbial/${perc_microbe}p-FDA-ARGO-${R_SEED}_sim_
mid_fn=$TEMP_OUT/midpoint_coverages/microbial/${perc_microbe}p-FDA-ARGO-${R_SEED}_MINI_sim_

#Run the ART command
$ART -na \
    -i $microbe_source \
    -l 150 \
    -m 350 \
    -s 50 \
    -f $microbe_coverage \
    -o $mid_fn \
    -1 ${SEQ1} \
    -2 ${SEQ2} \
    -rs ${R_SEED}

<<com
Info on Art commands:
$ART -na \ #Do not ouptut alignment
        -i $microbe_source \ #input ref
        -l 150 \ #Read length
        -m 350 \ #Mean fragment size for paired-end sim -Picked Illumina Averge
        -s 50 \ #Standard deviation of DNA fragment size for paired end
        -f $microbe_coverage \ # the fold of read coverage to be simulated or number of reads/read pairs
        -o $out_fn \ #ouput dir
        -1 ${SEQ1} \ #Seq profile Error profiles - optional- Taken from Qiyun advice to use this paper: CAMISIM
        -2 ${SEQ2} \
        -rs $((J+40)) #random seed 
com

<<com 
#This step failed... so moving to s different file

#Subset filename out
#out_fn=$TEMP_OUT/${perc_microbe}p-FDA-ARGO-${R_SEED}_sim
out_fn=$TEMP_OUT/${perc_microbe}p-FDA-ARGO-${R_SEED}_MINI_sim

echo "$microbe_read"

#Subset the number of reads you actually want in you dataset
seqtk sample -s100 ${mid_fn}1.fq $microbe_read > ${out_fn}_TESTING_.R1.fastq
seqtk sample -s100 ${mid_fn}2.fq $microbe_read > ${out_fn}_TESTING_.R2.fastq
com

echo 'done'

