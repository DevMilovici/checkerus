#!/bin/bash

program=$1
run_exercise() {
    local input_file_1=$1
    local input_file_2=$2
    local input_file_3=$3
    local input_file_4=$4
    local output_file_1=$5
    local output_file_2=$6
    local output_file_3=$7
    local output_file_4=$8

    ./script.sh "$program" "$input_file_1" "$input_file_2" "$input_file_3" "$input_file_4" "$output_file_1" "$output_file_2" "$output_file_3" "$output_file_4"
}

declare -a exercises=(
    "in1.txt in2.txt in3.txt in4.txt out1.txt out2.txt out3.txt out4.txt"
   
)

for exercise in "${exercises[@]}"; do
    set -- $exercise  
    run_exercise "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" 
done

