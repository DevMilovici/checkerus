#!/bin/bash

gcc -pthread -o test $1

input_file_1=$2
input_file_2=$3
input_file_3=$4
input_file_4=$5
expected_output_file_1=$6
expected_output_file_2=$7
expected_output_file_3=$8
expected_output_file_4=$9

thread_counts=(1 2 4 8)
baseline_time=0

index=0

run_test_and_compare() {
    local expected_output_file=$1
    local input_file=$2

    total_points=0

    for threads in "${thread_counts[@]}"; do
        
        temp_output="temp_output_$threads.txt"

        { time ./test $threads "$input_file" "$temp_output" >/dev/null; } 2> temp_time.txt

        real_time=$(grep real temp_time.txt | awk '{print $2}')

        total_time=$(echo "$real_time" | awk -F'm' '{ split($2, a, "s"); print $1 * 60 + a[1] }')

        if cmp -s "$temp_output" "$expected_output_file"; then
            echo "Execution time with $threads thread(s): ${total_time}s"

            total_points=$((total_points + 1))     
        else
            echo "Output does not match for $threads thread(s)"
            return
        fi

        
        if [ "$threads" -eq "1" ]; then
            baseline_time=$total_time
        fi

        speedup=$(awk "BEGIN { printf \"%.2f\", $baseline_time / $total_time }")
        echo "Speedup with $threads thread(s): $speedup"
    done

    
    total_points=$((total_points))
    if [ "$total_points" -eq "4" ];then
       if [ "$index" -eq "0" ];then
            total_points=50
       fi

       if [ "$index" -eq "1" ];then
            total_points=10
       fi

       if [ "$index" -eq "2" ];then
            total_points=30
       fi

       if [ "$index" -eq "3" ];then
            total_points=10
       fi
    else
        total_points=0
    fi

    
    rm temp_time.txt $temp_output
    rm temp*

    echo "Total points for this test: $total_points"
    echo "--------------------------------------------"
    index=$((index + 1))  
}

echo "Running first test (comparing with $expected_output_file_1)..."
run_test_and_compare $expected_output_file_1 $input_file_1

echo "Running second test (comparing with $expected_output_file_2)..."
run_test_and_compare $expected_output_file_2 $input_file_2

echo "Running first test (comparing with $expected_output_file_3)..."
run_test_and_compare $expected_output_file_3 $input_file_3

echo "Running second test (comparing with $expected_output_file_4)..."
run_test_and_compare $expected_output_file_4 $input_file_4
