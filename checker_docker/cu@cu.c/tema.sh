#!/bin/bash

run_exercise() {
    local program=$1
    local input_file_1=$2
    local input_file_2=$3
    local input_file_3=$4
    local input_file_4=$5
    local output_file_1=$6
    local output_file_2=$7
    local output_file_3=$8
    local output_file_4=$9

    ./script.sh "$program" "$input_file_1" "$input_file_2" "$input_file_3" "$input_file_4" "$output_file_1" "$output_file_2" "$output_file_3" "$output_file_4"
}

declare -a exercises=(
    "homework.c in1.txt in2.txt in3.txt in4.txt out1.txt out2.txt out3.txt out4.txt"
   
)

for exercise in "${exercises[@]}"; do
    set -- $exercise  
    run_exercise "$1" "$2" "$3" "$4" "$5" "$6" "$7" "$8" "$9"
done

