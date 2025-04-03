#!/bin/bash

input_file="$(basename $1)"
output_dir="$(dirname $1)"
output_file="${input_file//list/sources}"

while read -r line; do
    [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue  # Skip comments and empty lines
    
    # Check if $2 is enclosed in square brackets
    if [[ "$line" =~ ^[^\ ]+\ \[.*\]\ .* ]]; then
        # Extract optional options
        options=$(echo "$line" | awk '{print $2}')
        type=$(echo "$line" | awk '{print $1}')
        url=$(echo "$line" | awk '{print $3}')
        suite=$(echo "$line" | awk '{print $4}')
        components=$(echo "$line" | awk '{for(i=5;i<=NF;i++) printf $i" "; print ""}')

        # Extract signed-by key if present
        key=$(echo "$options" | grep -oP "(?<=\[signed-by=)[^\]]+" || echo "")
        
        # Extract arch if present
        arch=$(echo "$options" | grep -oP "(?<=\[arch=)[^\]]+" || echo "")
    else
        # No optional options
        type=$(echo "$line" | awk '{print $1}')
        url=$(echo "$line" | awk '{print $2}')
        suite=$(echo "$line" | awk '{print $3}')
        components=$(echo "$line" | awk '{for(i=4;i<=NF;i++) printf $i" "; print ""}')
        
        # No signed-by key
        key=""
    fi

    # Create Deb822 format
    echo -e "Types: $type\nURIs: $url\nSuites: $suite\nComponents: $components" > "$output_dir/$output_file"
    
    # Add signed-by if available
    [[ -n "$key" ]] && echo "Signed-By: $key" >> "$output_dir/$output_file"
    [[ -n "$arch" ]] && echo "Architectures: ${arch//,/ }" >> "$output_dir/$output_file"

done < "$input_file"

echo "Conversion completed! Files are saved as $output_dir/$output_file"
