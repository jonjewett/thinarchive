#!/bin/bash


##  Define Variables

	requireroot=yes
	timestamp=`date "+[%m-%d-%Y]-[%H.%M.%S]"`			# Date format in archive naming
	
	srcdata=/path/to/data/to/be/archived				# Path to data to be archived
	arcdata=/path/to/write/archives/into				# Path to write archives to

	scriptfamily=[ThinArchive]:							# Description of script
	scriptname=`basename $0`							# Short name generated from the filename

	syslog=/var/log/system.log 							# Path to your system log
	logpreface=`hostname -s;echo "$scriptname$scriptfamily "`			# Assembly of computer hostname and script name for log ID's
	

## Define Functions


	enforceusr() {

		if [[ $(/usr/bin/id -u) -ne 0 ]];
		
			then

				echo " " 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog
				echo "Required user checking failed root privileges detection.  Terminating script execution..." 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog
				echo " " 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog
				exit 0		##  Script execution should abort and stop HERE

			else					
			
				echo "Verifying administrative privileges..." 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog
				echo "Root / Super User privileges confirmed.  Continuing with data archival process." 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog

		fi

	}


	usrcheck() {

		if [[ "$requireroot" == "yes" ]];

			then

				enforceusr											# Go verify that we're running as root, stop if we're not

			else

				:													# Go ahead and run, whether we're root or not

		fi

	}


	startup() {

		if [[ $(/usr/bin/id -u) -ne 0 ]];
		
			then

				writelog="tee"										# If user is not root, echo to console
				usrcheck

			else					
			
				writelog="tee -a ${syslog}"							# If user is root, log to syslog
				usrcheck

		fi

	}


	archive() {

		rsync -rgotpLP --link-dest=${arcdata}/current ${srcdata}/ ${arcdata}/backup-${timestamp} 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog

	}


	updatecurrent() {
	
		rm ${arcdata}/current 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog
		ln -s backup-${timestamp} ${arcdata}/current 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog
		touch ${arcdata}/current 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog
		touch ${arcdata}/backup-${timestamp} 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog

	}


	prunearchives() {

		/bin/rm -rf /$arcdata/`ls -t /$arcdata/ | grep 'backup' | tail -1` 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog

	}


## Runtime

	startup

	echo "Archiving data, and hard-linking for data-deduplication. . ." 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog
	archive

	echo "Updating directory timestamps, and current symlink. . ." 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog
	updatecurrent

	echo "Removing oldest archive to keep revision count static. . ." 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog
	
	##  NOTICE SEE COMMENTS BELOW  ##
	prunearchives
	##  The "prunearchives" function call on the line above should be commented out initially
	##  so as to allow for the desired number of archives to build up in the output directory.
	##  Once sufficient archives have been created, uncomment the line again, and this script
	##  will maintain a consistent level of archives (deleting the oldest archive on each new
	##  run.)

	echo "Data Archival Complete.  Cleaning up." 2>&1 | { read cmdout;echo `date | cut -c 5-19` $logpreface$cmdout; } | $writelog

	exit 0
