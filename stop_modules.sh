#!/bin/bash

START_PORT=9130
END_PORT=9200

set_port_arg() {
	if [ -n "$1" ]; then
		SPECIFIC_PORT=$1
	fi
}

stop_modules() {

	if [[ -v SPECIFIC_PORT ]]; then
		START_PORT="$SPECIFIC_PORT"
		END_PORT="$SPECIFIC_PORT"
	fi

	for ((i=$START_PORT; i<=$END_PORT; i++))
	do
        local PORT=$i

        is_port_used $PORT
        IS_PORT_USED=$?
        if [[ "$IS_PORT_USED" -eq 1 ]]; then
            kill_process_port $PORT
        fi
	done
}

is_port_used() {
	local PORT=$1

	FILTERED_PROCESSES=$(lsof -i :$PORT)

	if [ -z "$FILTERED_PROCESSES" ]; then
		return 0
	fi

	return 1
}


kill_process_port() {
	local PORT=$1

	kill -9 $(lsof -t -i:$PORT)
}

set_port_arg $1
stop_modules