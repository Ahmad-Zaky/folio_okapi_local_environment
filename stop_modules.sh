#!/bin/bash

START_PORT=9131
END_PORT=9200

stop_modules() {
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

	FILTERED_PROCESSES=$(lsof -i :$1)

	if [ -z "$FILTERED_PROCESSES" ]; then
		return 0
	fi

	return 1
}


kill_process_port() {
	local PORT=$1

	kill -9 $(lsof -t -i:$PORT)
}

stop_modules