#!/bin/bash

#############################################################################################
# - Sections order:																			#
#	+ Database  																			#
# 	+ Helpers																				#
# 	+ Preprocess																			#
#	+ Validation																			#
# 	+ Process (Clone, Build (Compile), Register (Declare), Deploy, Install (Enable))		#
# 	+ Postprocess																			#
# 	+ Run																					#
#############################################################################################


if [ -f scripts/database.sh ]; then
    . scripts/database.sh
fi

if [ -f scripts/helpers.sh ]; then
    . scripts/helpers.sh
fi

if [ -f scripts/preprocess.sh ]; then
    . scripts/preprocess.sh
fi

if [ -f scripts/validation.sh ]; then
    . scripts/validation.sh
fi

if [ -f scripts/process.sh ]; then
    . scripts/process.sh
fi

if [ -f scripts/postprocess.sh ]; then
    . scripts/postprocess.sh
fi

pre_process $*

process

post_process
