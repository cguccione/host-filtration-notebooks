#!/bin/bash

folder_path="$1"
file_prefix="$2"
output_fn="$3"
output_tsv="${output_fn}_output.tsv"

echo -e "Filename\tDuration (seconds)" > "$output_tsv"

for filename in "$folder_path"/host_filter-"${file_prefix}"_*.out; do
    if [ -f "$filename" ]; then
        start_time=$(grep "Time start:" "$filename" | awk '{print $3}')
        end_time=$(grep "Time end:" "$filename" | awk '{print $3}')

        start_seconds=$(date -d "$start_time" +"%s")
        end_seconds=$(date -d "$end_time" +"%s")

        duration_seconds=$((end_seconds - start_seconds))

        echo -e "$(basename "$filename")\t$duration_seconds" >> "$output_tsv"
    else
        echo "File $filename not found."
    fi
done

echo "Results saved to $output_tsv"

