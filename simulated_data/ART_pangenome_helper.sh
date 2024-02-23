#!/bin/bash -l

#SBATCH -J art_help
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
Goal: Helper function which starts each of the 20
commands for ART
com

mamba activate human-depletion-lucas

#List of files in pangenome
pan_list=/projects/benchmark-human-depletion/compare_datasets/mix_hum_microbe_sim/source_data/pangenome_subset/fn_list.txt

#Find current file based on ID
pan_file=$human_pan_folder/$(sed -n "${J}p" "$pan_list")

echo "Processing file: $pan_file"

#Extract name of current pangenome
pan_filename_p1=$(basename "$pan_file")
pan_filename_p2=$(echo "$pan_filename_p1" | awk -F'.' '{print $1"."$2}')

#Create middle output fn [only use the mini one when running #7]
mid_fn=$TEMP_OUT/midpoint_coverages/${perc_hum}p-${pan_filename_p2}_sim_
#mid_fn=$TEMP_OUT/midpoint_coverages/${perc_hum}p-${pan_filename_p2}_MINI_sim_
##CHANGE BELOW TOO IF U DO THIS

#Run the ART command
$ART -na \
    -i $pan_file \
    -l 150 \
    -m 350 \
    -s 50 \
    -f $human_coverage \
    -o $mid_fn \
    -1 ${SEQ1} \
    -2 ${SEQ2} \
    -rs ${SEED}

<<com
Info on Art commands:
$ART -na \ #Do not ouptut alignment
        -i $pan_file \ #input ref
        -l 150 \ #Read length
        -m 350 \ #Mean fragment size for paired-end sim -Picked Illumina Averge
        -s 50 \ #Standard deviation of DNA fragment size for paired end
        -f $human_coverage \ # the fold of read coverage to be simulated or number of reads/read pairs
        -o $out_fn \ #ouput dir
        -1 ${SEQ1} \ #Seq profile Error profiles - optional- Taken from Qiyun advice to use this paper: CAMISIM
        -2 ${SEQ2} \
        -rs ${SEED} #random seed 
com

<<com #This failed so moving to another script to fix this
#Subset filename out
out_fn=$TEMP_OUT/${perc_hum}p-${pan_filename_p2}_sim
#out_fn=$TEMP_OUT/${perc_hum}p-${pan_filename_p2}_MINI_sim

#Subset the number of reads you actually want in you dataset
seqtk sample -s100 ${mid_fn}1.fq $human_read > ${out_fn}.R1.fastq
seqtk sample -s100 ${mid_fn}2.fq $human_read > ${out_fn}.R2.fastq
com

echo 'done'

