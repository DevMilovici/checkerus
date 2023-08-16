#!/bin/bash

maxRunTime=20
minScalability=1.2
points=0
programToTest=program

declare -A extraParameters
declare -A refParameters
# EVEN
extraParameters[test_1]="./in/in_2.txt ./out/out_2.txt ./ref/out_2.txt"
refParameters[test_1]="out_2.txt"
extraParameters[test_2]="./in/in_4.txt ./out/out_4.txt ./ref/out_4.txt"
refParameters[test_2]="out_4.txt"
extraParameters[test_3]="./in/in_5.txt ./out/out_5.txt ./ref/out_5.txt"
refParameters[test_3]="out_5.txt"


function print_points {
	TEST=$*
	NUM=$((55 - ${#TEST}))
	for i in $(seq $NUM)
	do
		echo -n .
	done
}

function printResult {
	testName=${@:1:$#-2}
	testResult=${@:$#-1:1}
	pointsPerTest=${@: -1}
	if [ $testResult == FAILED ]
	then
		echo "$testName$(print_points $testName)FAILED"
        # (0/$pointsPerTest)"
	else
		echo "$testName$(print_points $testName)PASSED"
        # ($pointsPerTest/$pointsPerTest)"
		points=$(echo "$points+$pointsPerTest"| bc -l)
	fi
}

function checkReturnCode {
	ret=$1
	if [ $ret == 124 ]
	then
		echo -e "\nERROR: Program took more than $maxRunTime seconds to execute"
		echo "ERROR: It is possible you have an infinte loop bug or a dead-lock"
		echo "ERROR: for dead-locks check with valgrind --tool=helgrind -s ./$program"
	elif [ $ret == 127 ]
	then
		echo -e "\nERROR: Program not found (maybe it did not compile)"
	elif [ $ret == 134 ]
	then
		echo -e "\nERROR: Signal SIGABRT"
		echo "ERROR: maybe something wrong with malloc/free"
		echo "ERROR: check with valgrind --leak-check=full ./$program"
	elif [ $ret == 139 ]
	then
		echo -e "\nERROR: Signal SIGSEGV"
		echo "ERROR: Segfault - maybe something wrong with  malloc, free, pointer, overflow and so on"
		echo "ERROR: check with valgrind --leak-check=full ./$program"
	elif [ $ret -gt 127 ]
	then
		echo -e "\nERROR: Program ended with non-zero return code $ret"
		echo "ERROR: Does your program return 0?"
		echo "ERROR: Problems with system function-calls can also trigger this"
		echo "ERROR: in a terminal type 'trap -l' and see $(($ret-128)) to identify the error"
	elif [ $ret != 0 ]
	then
		echo -e "\nERROR: Program ended with non-zero return code $ret."
		echo "ERROR: Does your program return 0?"
	fi
}

function runProgram {
	program=$1
	testName=$2
	num_threads=$3
	fullTestName=$testName.$num_threads
	testResult="FAILED"
	echo -e "Running $testName with $num_threads processes. "

    testParameters=${extraParameters[$testName]};
    inputPath="$(echo ${testParameters} | cut -d' ' -f1)";
    outputPath="$(echo ${testParameters} | cut -d' ' -f2)";
    ouputPathExtension="$(echo $outputPath | sed "s/.*\.//g")"
    outputPath="$(echo ${outputPath} | sed "s/\.${ouputPathExtension}//g")""_${num_threads}""."$ouputPathExtension
    refPath="$(echo ${testParameters} | cut -d' ' -f3)";
    # echo -e "\tNumSteps: "$numSteps;
    # echo -e "\tInputPath: "$inputPath;
    # echo -e "\tOutputPath: "$outputPath;
    # echo -e "\tRefPath: "$refPath;

    runCommand="/usr/bin/time --quiet -f "%e" -o execTime.$fullTestName timeout $maxRunTime mpirun --oversubscribe -np $num_threads ./$program ${inputPath} ${outputPath}"
	# echo -e "\t> ${runCommand}"
    $runCommand &> /dev/null
	
	ret=$?
	checkReturnCode $ret
	if [ $ret != 0 ]
	then
		echo -e "\n"
	elif [ ! -e ${outputPath} ]
	then
		echo -e "\nERROR: Output file does not exist"
	else
		diff $refPath $outputPath &> /dev/null
		if [ $? != 0 ]
		then
			echo -e "\nERROR: Output files differ"
		else
			testResult="PASSED"
		fi
	fi
	times[$num_threads]="`tail -n 1 execTime.$fullTestName`"
    rm "execTime."$fullTestName
	echo -e "Finished in ${times[$num_threads]} seconds."
    rm $outputPath
}

function scalabilityTest {
	pointsForScalability=$1
	pointsForOneTest=$2
	sumScalability=0
	testResultAllThreadsAllTests="PASSED"
	for testNameShort in $tests
	do
		testResultAllThreads="PASSED"
		for num_threads in 1 2 4 8
		do
			runProgram $programToTest $testNameShort $num_threads
			if [ $testResult == "FAILED" ]
			then
				testResultAllThreads="FAILED"
			fi
		done
		echo -e "Execution times: 1 Process -"  ${times[1]}"; 2 Processes - " ${times[2]}"; 4 Processes - "${times[4]}"; 8 Processes - "${times[8]}
		scalability=$(echo "((${times[1]}/(${times[2]}+0.00001))+(${times[2]}/(${times[4]}+0.00001))+(${times[4]}/(${times[8]}+0.00001)))/3" | bc -l)
		echo -e "Scalability score ((1P/2P + 2P/4P + 4P/8P) / 3) is $scalability"
		sumScalability=$(echo "$sumScalability+$scalability" | bc -l)
		if [ $testResultAllThreads == "FAILED" ]
		then
			testResultAllThreadsAllTests="FAILED"
		fi
		testName="Checking outputs for $testNameShort"
		printResult $testName $testResultAllThreads $pointsForOneTest
        echo -e "\n";
	done

	numTests=$(echo $tests | wc -w)
	averageScalability=$(echo "$sumScalability/$numTests" | bc -l)
	isScalable=$(echo "$averageScalability > $minScalability" | bc -l)
	echo "Average scalability score is $averageScalability"
	echo "Average scalability score should be larger than $minScalability"
	testResultScalability="FAILED"
	if [ $testResultAllThreadsAllTests == FAILED ]
	then
		echo "However, scalability is irrelevant if any previous test failed."
	elif [ $isScalable != 0 ]
	then
		testResultScalability="PASSED"
	fi
	testName="Checking scalability on $programToTest"
	printResult $testName $testResultScalability $pointsForScalability
}

make
maxRunTime=10
minScalability=1.2
echo -e "\n-------------------------------------------------------\nRunning TEST 1...\n-------------------------------------------------------";
tests="test_1"
scalabilityTest 50 0

maxRunTime=15
minScalability=1.4
echo -e "\n-------------------------------------------------------\nRunning TEST 2...\n-------------------------------------------------------";
tests="test_2"
scalabilityTest 20 0

maxRunTime=12
minScalability=1.5
echo -e "\n-------------------------------------------------------\nRunning TEST 3...\n-------------------------------------------------------";
tests="test_3"
scalabilityTest 30 0

echo "                                      Total  =  [ $(echo "scale=3; $points" | bc)/100.000 ]"

killall $programToTest &> /dev/null
killall mpirun &> /dev/null