#!/bin/bash

####################################################
# 		START - VALIDATE PREVIOUS SCRIPTS		   #
####################################################

if [ ! -f scripts/helpers.sh ]; then
	echo -e "["$(date +"%A, %b %d, %Y %I:%M:%S %p")"] \n\e[1;31m ERROR: Helpers script file is missing \033[0m"
	
    exit 1
fi

if [ ! -f scripts/preprocess.sh ]; then
	echo -e "["$(date +"%A, %b %d, %Y %I:%M:%S %p")"] \n\e[1;31m ERROR: Preprocess script file is missing \033[0m"
	
    exit 1
fi

if [ ! -f scripts/process.sh ]; then
	echo -e "["$(date +"%A, %b %d, %Y %I:%M:%S %p")"] \n\e[1;31m ERROR: Process script file is missing \033[0m"
	
    exit 1
fi

################################################
# 		END - VALIDATE PREVIOUS SCRIPTS		   #
################################################


post_process() {
	new_line
	log_stars_title "Post process ..."

	delete_tmp_files
}