#!/bin/bash

# have to be logged in as cristian (user that has acess to key for ssh to apd)
# nohup ./moveToBufferDaemon.sh > logMovetoBuffer.txt &

uploadPath=uploads
queuePath=buffer

while true; do
	for file in $(ls -tr $uploadPath/); do
		for machine in $(ls $queuePath/); do
            echo -e "------------------------------------"
			numRunning=$(ls $queuePath/$machine | wc -l)
			if [ $numRunning -ge 1 ]; then
				continue;
			fi
			mvCmd="mv $uploadPath/$file $queuePath/$machine"
            echo -e "${mvCmd}"
            $mvCmd
			echoCmd="echo $machine $queuePath/$machine $file &"
            echo -e "${echoCmd}"
            $echoCmd &
			bashCmd="bash ./runHomework.sh $queuePath $file $machine &"
            echo -e "${bashCmd}"
            $bashCmd &
			break;
		done;
	done;

	sleep 5
	date
done
