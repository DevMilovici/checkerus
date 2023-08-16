#!/bin/bash

maxRunTime=300
submissionCheckersPath=checkers
rezultsPath=rezults
ssh_user=worker
keyFile=keys/worker

queuePath=$1
submissionName=$2
fullMachineName=$3

submissionType=$(echo $submissionName | cut -d'#' -f1)
echo -e "\tsubmissionType: ${submissionType}"
submissionIdentifier=$(echo $submissionName | cut -d'#' -f2)
echo -e "\tsubmissionIdentifier: ${submissionIdentifier}"
userName=$(echo $submissionName | cut -d'#' -f2 | cut -d'@' -f1)
echo -e "\tuserName: ${userName}"
timeStamp=$(echo $submissionName | cut -d'#' -f2 | cut -d'@' -f2)
echo -e "\ttimeStamp: ${timeStamp}"
machine=$(echo $fullMachineName | cut -f 1 -d "-")
echo -e "\tmachine: ${machine}"
port=$(echo $fullMachineName | cut -f 2 -d "-")
echo -e "\tport: ${port}"

fullSubmissionPath="$queuePath/$fullMachineName/$submissionName"
echo -e "\tfullSubmissionPath: ${fullSubmissionPath}"
fileDebug="$rezultsPath/$submissionType/$userName/$timeStamp/debug.txt"
echo -e "\tfileDebug: ${fileDebug}"
sshCmd="ssh -i $keyFile -o StrictHostKeyChecking=no -q -p $port $ssh_user@$machine"
echo -e "\tsshCmd: ${sshCmd}"
scpCmd="scp -i $keyFile -o StrictHostKeyChecking=no -q -P $port"
echo -e "\tscpCmd: ${scpCmd}"

mkdirCmd="mkdir -p $rezultsPath/$submissionType/$userName/$timeStamp"
echo -e "\tmkdirCmd: ${mkdirCmd}"
$mkdirCmd
echo "" > $fileDebug

echo "Running on $machine:$port" >> $fileDebug 2>&1

#upload submission
$sshCmd "mkdir $submissionName" >> $fileDebug 2>&1
$scpCmd $fullSubmissionPath $ssh_user@$machine:$submissionName/$submissionName >> $fileDebug 2>&1
$sshCmd "unzip -o $submissionName/$submissionName -d $submissionName" >> $fileDebug 2>&1

#upload checker
$scpCmd $submissionCheckersPath/$submissionType/active/checker.zip $ssh_user@$machine:$submissionName/checker.zip >> $fileDebug 2>&1
$sshCmd "unzip -o $submissionName/checker.zip -d $submissionName" >> $fileDebug 2>&1

#run
$sshCmd "cd $submissionName; touch *; chmod 777 runAll.sh" >> $fileDebug 2>&1
fileRezults="$rezultsPath/$submissionType/$userName/$timeStamp/rezult.txt"
echo "" > $fileRezults
timeout $maxRunTime $sshCmd "cd $submissionName; ./runAll.sh" &> $fileRezults

#cleanup
$sshCmd "killall -9 runAll.sh" >> $fileDebug 2>&1
$sshCmd "killall -9 mpirun" >> $fileDebug 2>&1
$sshCmd "rm -R $submissionName" >> $fileDebug 2>&1

fullLongTermStoragePath="$rezultsPath/$submissionType/$userName/$timeStamp/$submissionName"
mv $fullSubmissionPath $fullLongTermStoragePath