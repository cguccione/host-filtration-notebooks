#!/bin/bash

folder_path="$1"
file_prefix="$2"
output_fn="$3"
output_tsv="${output_fn}_output.tsv"

echo -e "Filename\tDuration (seconds)" > "$output_tsv"

total_duration=0
num_files=0

for filename in "$folder_path"/host_filter-"${file_prefix}"_*.out; do
    if [ -f "$filename" ]; then
        start_time=$(grep "Time start:" "$filename" | awk '{print $3}')
        end_time=$(grep "Time end:" "$filename" | awk '{print $3}')

        echo "$start_time $end_time"

        start_seconds=$(date -d "$start_time" +"%s")
        end_seconds=$(date -d "$end_time" +"%s")

        # Check if end time is less than start time, add 24 hours (86400 seconds)
        if [ "$end_seconds" -lt "$start_seconds" ]; then
            end_seconds=$((end_seconds + 86400))
        fi

        echo "$start_seconds $end_seconds"

        duration_seconds=$((end_seconds - start_seconds))

        echo -e "$(basename "$filename")\t$duration_seconds" >> "$output_tsv"

        total_duration=$((total_duration + duration_seconds))
        num_files=$((num_files + 1))
    else
        echo "File $filename not found."
    fi
done

if [ "$num_files" -gt 0 ]; then
    average_duration=$((total_duration / num_files))
    echo -e "Average\t$average_duration" >> "$output_tsv"
else
    echo "No files found for calculation."
fi

echo "Results saved to $output_tsv"
