#!/bin/bash

# Check if the correct number of arguments is provided
if [ "$#" -ne 5 ]; then
    echo "Usage: $0 <program> <input_file_1> <input_file_2> <output_file_1> <output_file_2>"
    exit 1
fi

# Compile the C program with pthread support
gcc -pthread -o test $1 -lm -lpthread

# Define the input and expected output files
input_file_1=$2
input_file_2=$3
expected_output_file_1=$4
expected_output_file_2=$5

# Array of thread counts to test
thread_counts=(1 2 4 8)
baseline_time=0

# Function to run the test and compare output
run_test_and_compare() {
    local expected_output_file=$1
    local input_file=$2

    total_points=0

    for threads in "${thread_counts[@]}"; do
        
        # Temporary file to capture the program output
        temp_output="temp_output_$threads.txt"

        # Run the test and measure the time taken
        { time ./test  "$input_file" "$temp_output" $threads >/dev/null; } 2> temp_time.txt

        # Extract the real execution time
        real_time=$(grep real temp_time.txt | awk '{print $2}')

        # Using awk to calculate total seconds
        total_time=$(echo "$real_time" | awk -F'm' '{ split($2, a, "s"); print $1 * 60 + a[1] }')

        # Compare the temporary output with the expected output file
        if cmp -s "$temp_output" "$expected_output_file"; then
            echo "Execution time with $threads thread(s): ${total_time}s"
            # Add points for successful execution
            if [ "$threads" -eq "8" ]; then
                total_points=$((total_points + 10))  
            fi
            total_points=$((total_points + 10))     
        else
            echo "Output does not match for $threads thread(s)"
            echo -1
            return
        fi

        # Calculate and print speedup
        if [ "$threads" -eq "1" ]; then
            baseline_time=$total_time
        fi

        speedup=$(awk "BEGIN { printf \"%.2f\", $baseline_time / $total_time }")
        echo "Speedup with $threads thread(s): $speedup"
    done

    
    total_points=$((total_points))

    # Clean up temporary files
    rm temp_time.txt $temp_output
    rm temp*

    echo "Total points for this test: $total_points"
    echo "--------------------------------------------"
}

# Run the tests and compare with the first expected output file using the first input file
echo "Running first test (comparing with $expected_output_file_1)..."
run_test_and_compare $expected_output_file_1 $input_file_1

# Run the tests and compare with the second expected output file using the second input file
echo "Running second test (comparing with $expected_output_file_2)..."
run_test_and_compare $expected_output_file_2 $input_file_2
