#!/bin/bash

gcc -o test $1 -lpthread -lm

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
max_points=0

run_test_and_compare() {
    local expected_output_file=$1
    local input_file=$2

    total_points=0
  
    t1=0
    t2=0
    t3=0
    t4=0
    index_t=0
    for threads in "${thread_counts[@]}"; do
        
        temp_output="temp_output_$threads.txt"

        { time ./test "$input_file" "$temp_output" $threads >/dev/null; } 2> temp_time.txt

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


	if [ "$index_t" -eq "0" ]; then
		t1=$total_time
	fi
	if [ "$index_t" -eq "1" ]; then
                t2=$total_time
        fi
	if [ "$index_t" -eq "2" ]; then
                t3=$total_time
        fi
	if [ "$index_t" -eq "3" ]; then
                t4=$total_time
        fi
	
	index_t=$((index_t + 1))
        #speedup=$(awk "BEGIN { printf \"%.2f\", $baseline_time / $total_time }")
        
        
	#echo "Speedup with $threads thread(s): $speedup"
    done
	#echo test
	#echo ($t1/($t2+0.00001)
	#echo (${t1}/(${t2}+0.00001) | bc -l
	#echo test2
    echo 1
   # speedup=$(echo "((${t1}/(${t2}+0.00001))+(${t2}/(${t4}+0.00001))+(${t4}/(${t8}+0.00001)))/3" | bc -l)
    speedup=$(echo "scale=6; (($t1/($t2+0.00001)) + ($t2/($t3+0.00001)) + ($t3/($t4+0.00001))) / 3" | bc -l)

    echo 2

    total_points=$((total_points))
    if [ "$total_points" -eq "4" ];then
       ######ADD SPEEDUP CONSTRAINT
	if [ "$index" -eq "0" ];then
            total_points=50
            max_points=$((max_points + 50)) 
       fi

       if [ "$index" -eq "1" ];then
            total_points=10
            max_points=$((max_points + 10)) 
       fi

       if [ "$index" -eq "2" ];then
            total_points=30
            max_points=$((max_points + 30)) 
       fi

       if [ "$index" -eq "3" ];then
            total_points=10
            max_points=$((max_points + 10)) 
       fi
	echo "Speedup ( T1/T2 + T2/T4 + T4/T8 )/3 : $speedup"
    else
        total_points=0
    fi

    
    rm temp_time.txt $temp_output
    #rm temp*

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

echo "--------------------------------------------"
 echo "Total points: $max_points"
