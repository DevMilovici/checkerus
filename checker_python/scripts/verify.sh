#!/bin/bash
# Configuration
PROGRAM=$1
THREAD_COUNTS=(1 2 4 8)
POINTS_PER_TEST=(50 10 30 10)  # Points for tests 1-4

# Test files - each test has 2 input files
INPUT_FILES_1=("in.txt" ) #"in2_1.txt" "in3_1.txt" "in4_1.txt")
INPUT_FILES_2=("in2.txt") #"in2_2.txt" "in3_2.txt" "in4_2.txt")
OUTPUT_FILES=("out1.txt" ) #"out2.txt" "out3.txt" "out4.txt")

# Initialize
total_points=0

# Compile the program
echo "Compiling $PROGRAM..."
gcc -o main "$PROGRAM" -lpthread -lm -O3

if [ $? -ne 0 ]; then
    echo "Compilation failed!"
    echo "Total points: 0"
    exit 1
fi

echo "Compilation successful!"
echo "============================================"

# Run each test
#for test_index in {0..3}; do
for test_index in {0..0}; do
    input_file_1="${INPUT_FILES_1[$test_index]}"
    input_file_2="${INPUT_FILES_2[$test_index]}"
    expected_output="${OUTPUT_FILES[$test_index]}"
    test_points="${POINTS_PER_TEST[$test_index]}"
    
    echo "Running test $((test_index + 1)) with $input_file_1 and $input_file_2..."
    
    # Check if input files exist
    if [ ! -f "$input_file_1" ] || [ ! -f "$input_file_2" ]; then
        echo "  ✗ Input files not found!"
        echo "  Points earned: 0"
        echo "--------------------------------------------"
        continue
    fi
    
    correct_outputs=0
    execution_times=()
    
    # Run with different thread counts
    for threads in "${THREAD_COUNTS[@]}"; do
        temp_output="temp_output_${threads}.txt"
        
        # Run the program and measure time
        start_time=$(date +%s.%N)
        ./main 1 > "$temp_output" 2>&1
        exit_code=$?
        end_time=$(date +%s.%N)
        
        execution_time=$(echo "$end_time - $start_time" | bc)
        execution_times+=("$execution_time")
        
        # Check if program executed successfully
        if [ $exit_code -ne 0 ]; then
            echo "  ✗ $threads thread(s): Program execution failed"
            rm -f temp_output_*.txt
            break
        fi
        
        # Compare output
        if cmp -s "$temp_output" "$expected_output"; then
            echo "  ✓ $threads thread(s): ${execution_time}s - Output correct"
            correct_outputs=$((correct_outputs + 1))
        else
            echo "  ✗ $threads thread(s): Output incorrect"
            # Optional: show diff for debugging
            # echo "  Diff:"
            # diff -u "$expected_output" "$temp_output" | head -20
            rm -f temp_output_*.txt
            break
        fi
        
        rm -f "$temp_output"
    done
    
    # Calculate points if all outputs are correct
    if [ "$correct_outputs" -eq 4 ]; then
        # Calculate speedup: (T1/T2 + T2/T4 + T4/T8) / 3
        t1="${execution_times[0]}"
        t2="${execution_times[1]}"
        t4="${execution_times[2]}"
        t8="${execution_times[3]}"
        
        speedup=$(echo "scale=6; (($t1/($t2+0.000001)) + ($t2/($t4+0.000001)) + ($t4/($t8+0.000001))) / 3" | bc -l)
        
        echo "  Speedup: $speedup"
        echo "  Points earned: $test_points"
        total_points=$((total_points + test_points))
    else
        echo "  Points earned: 0 (not all thread counts passed)"
    fi
    
    echo "--------------------------------------------"
done

# Cleanup
rm -f main temp_*.txt

# Final result
echo "============================================"
echo "Total points: $total_points"