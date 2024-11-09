#!/bin/bash

# Function to run a test
run_exercise() {
    local program=$1
    local input_file_1=$2
    local input_file_2=$3
    local output_file_1=$4
    local output_file_2=$5

    #echo "Running exercise with program: $program"
    
    # Check if the required files exist
    if [[ ! -f $program ]]; then
        echo "Error: Program file '$program' does not exist."
        exit 1
    fi
    
    if [[ ! -f $input_file_1 ]]; then
        echo "Error: Input file '$input_file_1' does not exist."
        exit 1
    fi

    if [[ ! -f $input_file_2 ]]; then
        echo "Error: Input file '$input_file_2' does not exist."
        exit 1
    fi
    
    if [[ ! -f $output_file_1 ]]; then
        echo "Error: Expected output file '$output_file_1' does not exist."
        exit 1
    fi

    if [[ ! -f $output_file_2 ]]; then
        echo "Error: Expected output file '$output_file_2' does not exist."
        exit 1
    fi

    # Call the script that runs the tests with the provided arguments
    ./script.sh "$program" "$input_file_1" "$input_file_2" "$output_file_1" "$output_file_2"
}

# Define the exercises with their respective programs and expected output files
declare -a exercises=(
    "in_3x4x5_s1.txt in_3x4x5_s2.txt out_3x4x5_s1.txt out_3x4x5_s2.txt",
    "in_6x6_s1.txt in_6x6_s2.txt out_6x6_s1.txt out_6x6_s2.txt"
)
progname=$1
# Loop through each exercise
for exercise in "${exercises[@]}"; do
    set -- $exercise  # Split the exercise string into variables
    run_exercise $progname "$1" "$2" "$3" "$4"
done

#echo "All exercises completed."
