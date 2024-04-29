#!/bin/bash

#############################################################################################
# - Sections order:																			#
# 	+ Helpers																				#
# 	+ Prepare																				#
#	+ Validation																			#
# 	+ Processing (Clone, Build (Compile), Register (Declare), Deploy, Install (Enable))		#
# 	+ Run																					#
#############################################################################################


if [ -f scripts/helpers.sh ]; then
    . scripts/helpers.sh
fi

if [ -f scripts/prepare.sh ]; then
    . scripts/prepare.sh
fi

if [ -f scripts/database.sh ]; then
    . scripts/database.sh
fi

if [ -f scripts/validation.sh ]; then
    . scripts/validation.sh
fi

if [ -f scripts/processing.sh ]; then
    . scripts/processing.sh
fi

pre_process $*

process
