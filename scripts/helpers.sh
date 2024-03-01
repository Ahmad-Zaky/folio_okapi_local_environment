#!/bin/bash

log() {
	echo -e "["$(date +"%A, %b %d, %Y %I:%M:%S %p")"] $1"
}

new_line() {
	echo -e "\n"
}

set_line_no() {
	LINE_NO=$1
}

set_file_name() {
	SOURCE_FILE=$1
}

new_output_line() {
	echo -e "" >> $OUTPUT_FILE
	echo -e "" >> $OUTPUT_FILE
	echo -e "" >> $OUTPUT_FILE
}

output_debug() {
	local CALL_STACK_INDEX=$1
	if ! [[ "$CALL_STACK_INDEX" =~ ^[0-9]+$ ]]; then
		CALL_STACK_INDEX=1
	fi

	FUNCTION=${FUNCNAME[$CALL_STACK_INDEX]}

	new_output_line
	echo "["$(date +"%A, %b %d, %Y %I:%M:%S %p")"] File: $SOURCE_FILE - Line: $LINE_NO - Func: ${FUNCTION}" >> $OUTPUT_FILE
	echo -e "" >> $OUTPUT_FILE
}

debug_line() {
	local CALL_STACK_INDEX=$1
	if ! [[ "$CALL_STACK_INDEX" =~ ^[0-9]+$ ]]; then
		CALL_STACK_INDEX=1
	fi

	FUNCTION=${FUNCNAME[$CALL_STACK_INDEX]}

	echo "["$(date +"%A, %b %d, %Y %I:%M:%S %p")"] File: $SOURCE_FILE - Line: $LINE_NO - Func: ${FUNCTION}"
}

# Output Error
error() {
	local MSG=$1
	local CALL_STACK_INDEX=$2
	if ! [[ "$CALL_STACK_INDEX" =~ ^[0-9]+$ ]]; then
		CALL_STACK_INDEX=2
	fi

	set_line_no $BASH_LINENO && debug_line $CALL_STACK_INDEX
    log "\e[1;31mERROR: $MSG \033[0m"

    exit 1
}

warning() {
    log "\e[1;33mWARNING: $1 \033[0m"
}

# Check if key exists
has() {
	local KEY=$1
	local INDEX=$2
	local JSON_LIST=$3

	if [ -n "$4" ]; then
		local NESTED_JSON_PROPERTIES=$4
	fi

	if [[ -v NESTED_JSON_PROPERTIES ]]; then
		HAS_CMD=".[$INDEX].$NESTED_JSON_PROPERTIES | has(\"$KEY\")"
	else
		HAS_CMD=".[$INDEX] | has(\"$KEY\")"
	fi

	if grep -q $(jq "$HAS_CMD" $JSON_LIST) <<< "true"; then
		return 1
	fi

	return 0
}

# Check if json object value of specific key exists
has_value() {
	local KEY=$1
	local INDEX=$2
	local VALUE=$3
	local JSON_LIST=$4

	if [ -n "$5" ]; then
		local NESTED_JSON_PROPERTIES=$5
		has $KEY $INDEX $JSON_LIST $NESTED_JSON_PROPERTIES
	else
		has $KEY $INDEX $JSON_LIST
	fi

	if [[ ! "$?" -eq 1 ]]; then
		return 0
	fi

	if [[ -v NESTED_JSON_PROPERTIES ]]; then
		KEY="$NESTED_JSON_PROPERTIES.$KEY"
	fi
	
	if grep -q $(jq ".[$INDEX] | .$KEY == \"$VALUE\"" $JSON_LIST) <<< "true"; then
		return 1
	fi

	return 0
}

# Search in arguments
has_arg() {
	local ARGS=$1
	local FIND=$2
	
	for ARG in $ARGS; do
		if [[ "$ARG" == "$FIND" ]]; then
			return 1
		fi
	done

	return 0
}

curl_req() {
	local CALL_STACK_INDEX=$1

	if [[ "$CALL_STACK_INDEX" =~ ^[0-9]+$ ]]; then
		shift
	else
		CALL_STACK_INDEX=2
	fi

	SKIP_FAILED_REQ=false
	if [[ $1 == true ]]; then
		SKIP_FAILED_REQ=true
		shift
	fi

	set_line_no $BASH_LINENO
	output_debug $CALL_STACK_INDEX
	
	STATUS_CODE=$(curl -s -o response.txt -w "%{http_code}" "$@") 
	CURL_RESPONSE=$(cat response.txt) && : > response.txt

	echo $CURL_RESPONSE >> $OUTPUT_FILE

	if ! [[ $STATUS_CODE =~ ^2[0-9][0-9]$ ]] && [[ $SKIP_FAILED_REQ == true ]]; then
		warning "HTTP request failed! (Status Code: $STATUS_CODE)"

		return
	fi

	if ! [[ $STATUS_CODE =~ ^2[0-9][0-9]$ ]]; then
		set_file_name $BASH_SOURCE
		debug_line 2
		error "HTTP request failed! (Status Code: $STATUS_CODE)"
	fi
}

# Basic Okapi curl boilerplate
okapi_curl() {
	local OPTIONS="-HX-Okapi-Tenant:$TENANT"
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS="-HX-Okapi-Token:$OKAPI_HEADER_TOKEN"
	fi

	set_file_name $BASH_SOURCE
	curl_req 3 $OPTIONS -HContent-Type:application/json $*
}

handle_cloud_okapi() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	has "okapi" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	validate_okapi_url $INDEX $JSON_LIST

	validate_okapi_tenant $INDEX $JSON_LIST

	validate_okapi_credentials $INDEX $JSON_LIST
}

attach_credentials() {
	local UUID=$1

	has_credentials
	HAS_CREDENTIALS=$?
	if [[ "$HAS_CREDENTIALS" -eq 1 ]]; then
		return
	fi

	log "Attach credentials ..."

	okapi_curl -d"{\"username\":\"$USERNAME\",\"userId\":\"$UUID\",\"password\":\"$PASSWORD\"}" $OKAPI_URL/authn/credentials
}

attach_permissions() {
	local UUID=$1
	PUUID=`uuidgen`

	has_user_permissions
	HAS_USER_PERMISSIONS=$?
	if [[ "$HAS_USER_PERMISSIONS" -eq 1 ]]; then
		return
	fi

	log "Attach permissions ..."

	okapi_curl -d"{\"id\":\"$PUUID\",\"userId\":\"$UUID\",\"permissions\":[\"okapi.all\",\"perms.all\",\"users.all\",\"login.item.post\",\"perms.users.assign.immutable\"]}" $OKAPI_URL/perms/users
}

# Login to obtain the token from the header
login_user() {
	log "Login with credentials: "
	log "username: $USERNAME"
	log "password: $PASSWORD"

	login_user_curl $OKAPI_URL $TENANT $USERNAME $PASSWORD

	OKAPI_HEADER_TOKEN=$TOKEN
	POSTMAN_ENV_TOKEN_VAL=$TOKEN
}

login_user_curl() {
	local URL=$1
	local TNT=$2
	local USR=$3
	local PWD=$4

	set_file_name $BASH_SOURCE
	curl_req -Dheaders -HX-Okapi-Tenant:$TNT -HContent-Type:application/json -d"{\"username\":\"$USR\",\"password\":\"$PWD\"}" $URL/authn/login
	
	# login from mod-users-bl module but the $LOGIN_WITH_MOD variable value should be 'mod-uers-bl'
	# curl_req -Dheaders -HX-Okapi-Tenant:$TNT -HContent-Type:application/json -d"{\"username\":\"$USR\",\"password\":\"$PWD\"}" $URL/bl-users/login?expandPermissions=true&fullPermissions=true

	TOKEN=`awk '/x-okapi-token/ {print $2}' <headers|tr -d '[:space:]'`
}

# Import swagger.api OpenApi Specification file as postman collection
postman() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	has "postman" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi
	
	# Skip postman if disabled
	is_postman_enabled $INDEX $JSON_LIST
	IS_ENALBLED=$?
	if [[ "$IS_ENALBLED" -eq 0 ]]; then
		return
	fi

	validate_open_api_file $INDEX $JSON_LIST $MODULE

	validate_module_postman_api_key $INDEX $JSON_LIST

	import_postman_openapi $MODULE_POSTMAN_API_KEY $OPEN_API_FILE $MODULE
}

import_postman_openapi() {
	log "Import postman openapi collection"

	local MODULE_POSTMAN_API_KEY=$1
	local OPEN_API_FILE=$2
	local MODULE=$3

	set_file_name $BASH_SOURCE
	curl_req $POSTMAN_URL$POSTMAN_IMPORT_OPENAPI_PATH \
		-HContent-Type:multipart/form-data \
		-HAccept:application/vnd.api.v10+json \
		-HX-API-Key:$MODULE_POSTMAN_API_KEY \
		-Ftype="file" \
		-Finput=@"$MODULE/$OPEN_API_FILE"
}

update_env_postman() {
	if [ -z "$POSTMAN_API_KEY" ] || [ -z "$POSTMAN_ENV_LOCAL_WITH_OKAPI_UUID" ] || [ -z "$POSTMAN_URL" ] || [ -z "$POSTMAN_ENVIRONMENT_PATH" ]; then
		return 
	fi

	log "Update env postman ..."

	local POSTMAN_API_KEY=$1

	set_file_name $BASH_SOURCE
	curl_req --location -XPUT $POSTMAN_URL$POSTMAN_ENVIRONMENT_PATH'/'$POSTMAN_ENV_LOCAL_WITH_OKAPI_UUID \
		-H'Content-Type: application/json' \
		-H'X-API-Key: '$POSTMAN_API_KEY \
		--data '{
			"environment": {
				"name": "'"$POSTMAN_ENV_NAME"'",
				"values": [
					{
						"key": "okapi_url",
						"value": "'$POSTMAN_ENV_OKAPI_URL_VAL'",
						"enabled": true,
						"type": "default"
					},
					{
						"key": "mod_url",
						"value": "'$POSTMAN_ENV_MOD_URL_VAL'",
						"enabled": true,
						"type": "default"
					},
					{
						"key": "tenant",
						"value": "'$POSTMAN_ENV_TENANT_VAL'",
						"enabled": true,
						"type": "default"
					},
					{
						"key": "token",
						"value": "'$POSTMAN_ENV_TOKEN_VAL'",
						"enabled": true,
						"type": "default"
					},
					{
						"key": "user_id",
						"value": "'$POSTMAN_ENV_USER_ID_VAL'",
						"enabled": true,
						"type": "default"
					},
					{
						"key": "job_profile_id",
						"value": "",
						"enabled": true,
						"type": "default"
					}
				]
			}
		}'
}

has_tenant() {
	local TENANT=$1

	set_file_name $BASH_SOURCE
	curl_req $OKAPI_URL/_/proxy/tenants

	RESULT=$(echo $CURL_RESPONSE | jq ".[] | .id | contains(\"$TENANT\")")
	RESULT=$(echo $RESULT | sed 's/"//g')
	
	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

has_user() {
	local USERNAME=$1

	okapi_curl $OKAPI_URL/users?query=username%3D%3D$USERNAME

	RESULT=$(echo $CURL_RESPONSE | jq ".users[] | .username | contains(\"$USERNAME\")")
	RESULT=$(echo $RESULT | sed 's/"//g')

	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

has_credentials() {
	okapi_curl $OKAPI_URL/authn/credentials-existence?userId=$UUID

	RESULT=$(echo $CURL_RESPONSE | jq ".credentialsExist | contains(true)")
	RESULT=$(echo $RESULT | sed 's/"//g')

	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0	
}

has_user_permissions() {
	okapi_curl $OKAPI_URL/perms/users?limit=1000

	RESULT=$(echo $CURL_RESPONSE | jq ".permissionUsers[] | .userId | contains(\"$UUID\")")
	RESULT=$(echo $RESULT | sed 's/"//g')

	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

should_login() {
	okapi_curl -HX-Okapi-Tenant:$TENANT $OKAPI_URL/users

	if ! [[ $STATUS_CODE =~ ^2[0-9][0-9]$ ]]; then
		return 1
	fi

	return 0
}

is_enabled() {
	local INDEX=$1
	local JSON_LIST=$2
	
	# By default module is enabled if the key is missing
	has "enabled" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return 1
	fi

	has_value "enabled" $INDEX "true" $JSON_LIST
	if [[ "$?" -eq 1 ]]; then
		return 1
	fi

	return 0
}

is_postman_enabled() {
	local INDEX=$1
	local JSON_LIST=$2
	
	# By default module is postman enabled if the key is missing
	has "enabled" $INDEX $JSON_LIST "postman"
	if [[ "$?" -eq 0 ]]; then
		return 1
	fi

	has_value "enabled" $INDEX "true" $JSON_LIST "postman"
	if [[ "$?" -eq 1 ]]; then
		return 1
	fi

	return 0
}

is_server_okapi_enabled() {
	local INDEX=$1
	local JSON_LIST=$2
	
	# By default module has server okapi enabled if the key is missing
	has "enabled" $INDEX $JSON_LIST "okapi"
	if [[ "$?" -eq 0 ]]; then
		return 1
	fi

	has_value "enabled" $INDEX "true" $JSON_LIST "okapi"
	if [[ "$?" -eq 1 ]]; then
		return 1
	fi

	return 0
}

is_okapi_exists() {
	if [ -d $OKAPI_DIR ]; then
		return 1
	fi

	return 0
}

is_okapi_running() {
	is_port_used $OKAPI_PORT

	IS_PORT_USED=$?
	if [[ "$IS_PORT_USED" -eq 0 ]]; then
		return 0
	fi

	return 1
}

clone_okapi() {

	# Check if Okapi exists in modules.json and clone default okapi repo
	FOUND=$(jq '.[] | first(select(.id == "okapi")) | .id == "okapi"' $JSON_FILE)
	if [[ "$FOUND" == "false" ]] || [[ -z "$FOUND" ]]; then
    	log "Cloning Okapi ..."

		eval "git clone --recurse-submodules $OKAPI_REPO"

		return
	fi

	local HAS_REPO=$(jq '.[] | first(select(.id == "okapi")) | has("repo")' $JSON_FILE)
	local HAS_TAG=$(jq '.[] | first(select(.id == "okapi")) | has("tag")' $JSON_FILE)
	
	# Clone Repo with Tag and with custom repo
	if [[ $HAS_REPO == "true" ]] && [[ $HAS_TAG == "true" ]]; then
    	log "Cloning Okapi ..."

		OKAPI_REPO=$(jq '.[] | first(select(.id == "okapi")) | .repo' $JSON_FILE)
		TAG=$(jq '.[] | first(select(.id == "okapi")) | .tag' $JSON_FILE)
		
		# Remove extra double quotes at start and end of the string
		OKAPI_REPO=$(echo $OKAPI_REPO | sed 's/"//g')
		TAG=$(echo $TAG | sed 's/"//g')

		eval "git clone --recurse-submodules -b $TAG $OKAPI_REPO"

		return
	fi
	
	# Clone Repo without tag and with custom repo
	if [[ $HAS_REPO == "true" ]]; then
    	log "Cloning Okapi ..."

		OKAPI_REPO=$(jq '.[] | first(select(.id == "okapi")) | .repo' $JSON_FILE)
		# Remove extra double quotes at start and end of the string
		OKAPI_REPO=$(echo $OKAPI_REPO | sed 's/"//g')

		eval "git clone --recurse-submodules $OKAPI_REPO"

		return
	fi

	# Clone default Okapi
  	log "Cloning Okapi ..."

	eval "git clone --recurse-submodules $OKAPI_REPO"
}

build_okapi() {
	# Check if Okapi exists in modules.json and build default okapi repo
	FOUND=$(jq '.[] | first(select(.id == "okapi")) | .id == "okapi"' $JSON_FILE)
	if [[ "$FOUND" == "false" ]] || [[ -z "$FOUND" ]]; then
		return
	fi

	# Build Okapi either from modules.json or the default build command
	local HAS_BUILD=$(jq '.[] | first(select(.id == "okapi")) | has("build")' $JSON_FILE)
	if [[ $HAS_REPO == "true" ]]; then
		OKAPI_BUILD_COMMAND=$(jq '.[] | first(select(.id == "okapi")) | .build' $JSON_FILE)

		# Remove extra double quotes at start and end of the string
		OKAPI_BUILD_COMMAND=$(echo $OKAPI_BUILD_COMMAND | sed 's/"//g')
	fi

	# Build default Okapi command
  	log "Build Okapi ..."
	eval "cd $OKAPI_DIR && $OKAPI_BUILD_COMMAND"

	# Go back to modules directory
	cd ..
}

rebuild_okapi() {
	# Check if Okapi exists in modules.json and build default okapi repo
	SHOULD_REBUILD_OKAPI=$(jq '.[] | first(select(.id == "okapi")) | .id == "okapi" and .rebuild == "true"' $JSON_FILE)
	if [[ "$SHOULD_REBUILD_OKAPI" == "true" ]]; then
    	log "Rebuild Okapi ..."

    	build_okapi
	fi
}

stop_running_module_or_modules() {
	if [[ "$STOP_OKAPI_ARG" -eq 1 ]] && ([[ -z "$STOP_OKAPI_PROT_ARG" ]] || [[ "$STOP_OKAPI_PROT_ARG" == "okapi" ]]); then
		stop_running_modules
        stop_okapi

		exit 0
	fi

    if [[ "$STOP_OKAPI_ARG" -eq 1 ]] && [[ "$STOP_OKAPI_PROT_ARG" == "modules" ]]; then
		stop_running_modules

		exit 0
	fi

	if [[ "$STOP_OKAPI_ARG" -eq 1 ]] && [[ ! -z "$STOP_OKAPI_PROT_ARG" ]]; then
        stop_running_module

		exit 0
	fi

	if [[ $SHOULD_STOP_RUNNING_MODULES == "false" ]] && [[ "$STOP_OKAPI_ARG" -eq 0 ]]; then
		return
	fi

	stop_running_modules
}

stop_running_modules() {
	log "Stop running modules ..."

	set_file_name $BASH_SOURCE
	curl_req true $OPTIONS $OKAPI_URL/_/discovery/modules

	local MODULE_URLS=$(echo $CURL_RESPONSE | jq ".[] | .url")
	local MODULE_URLS=$(echo $MODULE_URLS | sed 's/"//g')

	for MODULE_URL in $MODULE_URLS; do
		# Using sed to extract the port
		local MODULE_PORT=$(echo "$MODULE_URL" | sed -n 's/.*:\([0-9]\+\)$/\1/p')

		is_port_used $MODULE_PORT
        IS_PORT_USED=$?
        if [[ "$IS_PORT_USED" -eq 1 ]]; then
            kill_process_port $MODULE_PORT
        fi
	done
}

stop_running_module() {
    is_port_used $STOP_OKAPI_PROT_ARG
    IS_PORT_USED=$?
    if [[ "$IS_PORT_USED" -eq 1 ]]; then

		log "Stop running module with port $STOP_OKAPI_PROT_ARG ..."

        kill_process_port $STOP_OKAPI_PROT_ARG
	else
		log "Module with port $STOP_OKAPI_PROT_ARG already stopped !"
    fi
}

re_export_env_vars() {
	db_defaults

	kafka_defaults

	user_defaults
	
	postman_defaults

	set_env_vars_to_okapi
}

export_module_envs() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	has "env" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	local LENGTH=$(jq ".[$INDEX].env | length" $JSON_LIST)

	for ((k=0; k<$LENGTH; k++))
	do
		ENV_NAME=$(jq ".[$INDEX].env[$k].name" $JSON_LIST)
		ENV_VALUE=$(jq ".[$INDEX].env[$k].value" $JSON_LIST)

		# Remove extra double quotes at start and end of the string
		ENV_NAME=$(echo $ENV_NAME | sed 's/"//g')
		ENV_VALUE=$(echo $ENV_VALUE | sed 's/"//g')

		declare ENV_VAR="$ENV_NAME"
		export $ENV_VAR="$ENV_VALUE"

		set_file_name $BASH_SOURCE
		curl_req -d"{\"name\":\"$ENV_VAR\",\"value\":\"$ENV_VALUE\"}" $OKAPI_URL/_/env
	done
}

stop_okapi() {
	is_port_used $OKAPI_PORT
	IS_PORT_USED=$?
	if [[ "$IS_PORT_USED" -eq 1 ]]; then
		log "Stopping Okapi ..."

		kill_process_port $OKAPI_PORT
	else
		log "Okapi already stopped !"
	fi
}

is_port_used() {
	local PORT=$1

	FILTERED_PROCESSES=$(lsof -i :$1)

	if [ -z "$FILTERED_PROCESSES" ]; then
		return 0
	fi

	return 1
}

export_next_port() {
	local PORT=$1

	FILTERED_PROCESSES=$(lsof -i :$1)

	if [ -z "$FILTERED_PROCESSES" ]; then
		export PORT="$1"
		export SERVER_PORT="$1"
		export HTTP_PORT="$1"
		
		set_file_name $BASH_SOURCE
		curl_req -d"{\"name\":\"PORT\",\"value\":\"$PORT\"}" $OKAPI_URL/_/env
		curl_req -d"{\"name\":\"SERVER_PORT\",\"value\":\"$SERVER_PORT\"}" $OKAPI_URL/_/env
		curl_req -d"{\"name\":\"HTTP_PORT\",\"value\":\"$HTTP_PORT\"}" $OKAPI_URL/_/env

		return
	fi

	PORT=$((PORT + 1))
	export_next_port $PORT 
}

get_user_uuid_by_username() {
	local OPTIONS="-HX-Okapi-Tenant:$TENANT"
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS="-HX-Okapi-Token:$OKAPI_HEADER_TOKEN"
	fi

	# Check if users api works at all
	should_login
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	log "Get user UUID for username: $USERNAME"

	set_file_name $BASH_SOURCE
	okapi_curl $OPTIONS $OKAPI_URL/users

	UUID=$(echo $CURL_RESPONSE | jq ".users[] | select(.username == \"$USERNAME\") | .id")

	# Remove extra double quotes at start and end of the string
	UUID=$(echo $UUID | sed 's/"//g')

	log "User UUID: $UUID"

	POSTMAN_ENV_USER_ID_VAL=$UUID
}

get_random_permission_uuid_by_user_uuid() {
	local UUID=$1

	local OPTIONS="-HX-Okapi-Tenant:$TENANT"
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS="-HX-Okapi-Token:$OKAPI_HEADER_TOKEN"
	fi

	set_file_name $BASH_SOURCE
	curl_req $OPTIONS $OKAPI_URL/perms/users

	USER_PUUIDS=$(echo $CURL_RESPONSE | jq ".permissionUsers[] | select(.userId == \"$UUID\") | .id")

	# Return the first incommnig PUUID
	for USER_PUUID in $USER_PUUIDS; do
		PUUID=$USER_PUUID

		# Remove extra double quotes at start and end of the string
		PUUID=$(echo $PUUID | sed 's/"//g')

		return
	done
}

get_install_params() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	INSTALL_PARAMS="purge=true"

	local LOAD_REFERENCE_KEY=".install_params.tenantParameters.loadReference"
	FOUND_LOAD_REFERENCE=$(jq ".[] | first(select($LOAD_REFERENCE_KEY == \"true\")) | $LOAD_REFERENCE_KEY == \"true\"" $JSON_FILE)
	
	local LOAD_SAMPLE_KEY=".install_params.tenantParameters.loadSample"
	FOUND_LOAD_SAMPLE=$(jq ".[] | first(select($LOAD_SAMPLE_KEY == \"true\")) | $LOAD_SAMPLE_KEY == \"true\"" $JSON_FILE)
	
	if [[ "$FOUND_LOAD_REFERENCE" == "true" ]]; then
		INSTALL_PARAMS="$INSTALL_PARAMS&tenantParameters=loadReference%3Dtrue"
	fi

	if [[ "$FOUND_LOAD_REFERENCE" == "true" ]] && [[ "$FOUND_LOAD_SAMPLE" == "true" ]]; then
		INSTALL_PARAMS="$INSTALL_PARAMS%2C"
	fi

	if [[ "$FOUND_LOAD_SAMPLE" == "true" ]]; then
		INSTALL_PARAMS="$INSTALL_PARAMS&tenantParameters=loadSample%3Dtrue"
	fi
}

reset_and_verify_password() {
	local UUID=$1

	log "Reset and verify user password"
	okapi_curl $OKAPI_URL/bl-users/password-reset/link -d"{\"userId\":\"$UUID\"}"

	JSON_DATA=$CURL_RESPONSE

	# Check if the JSON data contains the string "requires permission".
	if grep -q "requires permission" <<< "$JSON_DATA"; then
		# NOTE: this request does not work for the first time, but it works fine the second time
		# the reason why is not clear but may be related to kafka not finished the task yet,
		# so I just try to wait using sleep command and it did work with me just fine.

		log "Access for user '$USERNAME' requires permission: users-bl.password-reset-link.generate"
		
		log "Please wait until permissions added are persisted, which may delay due to underlying kafka process in users module so we will try again now."

		sleep 50

		reset_and_verify_password $UUID

		return
	fi
	unset JSON_DATA

	TOKEN_2=`jq -r '.link' < echo $CURL_RESPONSE | sed -e 's/.*\/reset-password\/\([^?]*\).*/\1/g'`

	log "Second token: $TOKEN_2"

	set_file_name $BASH_SOURCE
	curl_req -HX-Okapi-Token:$TOKEN_2 $OKAPI_URL/bl-users/password-reset/validate -d'{}'
}

# Set extra permissions related to module mod-users-bl
set_users_bl_module_permissions() {
	local INDEX=$1
	local USERS_BL_MODULE="mod-users-bl"
	local PERMISSIONS_MODULE="mod-permissions"

	get_user_uuid_by_username

	# Validate that mod-users-bl exists in modules.json
	has_value "id" $INDEX "$USERS_BL_MODULE" $JSON_FILE
	FOUND=$?
	if [[ "$FOUND" -eq 0 ]]; then
		return
	fi

	# Validate that mod-permissions exists in modules.json
	has_value "id" $INDEX "$PERMISSIONS_MODULE" $JSON_FILE
	FOUND=$?
	if [[ "$FOUND" -eq 0 ]]; then
		return
	fi

	get_random_permission_uuid_by_user_uuid $UUID

	okapi_curl $OKAPI_URL/perms/users/$PUUID/permissions -d'{"permissionName":"users-bl.all"}'

	okapi_curl $OKAPI_URL/perms/users/$PUUID/permissions -d'{"permissionName":"users-bl.password-reset-link.generate"}'

	login_user

	reset_and_verify_password $UUID
}

deploy_module_directly() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	# Get Deployement descriptor path
	DEPLOYMENT_COMMAND=$(jq ".descriptor.exec" $MODULE/target/DeploymentDescriptor.json)

	# Remove extra double quotes at start and end of the string
	DEPLOYMENT_COMMAND=$(echo $DEPLOYMENT_COMMAND | sed 's/"//g')
	
	# Replace %p with current port
	DEPLOYMENT_COMMAND=$(echo $DEPLOYMENT_COMMAND | sed "s/%p/$SERVER_PORT/g")

	echo "Deploy module $MODULE on port: $SERVER_PORT"

	# Deploy module
	eval "cd $MODULE && nohup $DEPLOYMENT_COMMAND &"
}

enable_module_directly() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	ENABLE_PAYLOAD="{"
	
	# Add module_to property
	ENABLE_PAYLOAD="$ENABLE_PAYLOAD \"module_to\": \"$MODULE\""

	# add parameters property
	local LOAD_REFERENCE_KEY=".install_params.tenantParameters.loadReference"
	local LOAD_SAMPLE_KEY=".install_params.tenantParameters.loadSample"
	HAS_LOAD_REFERENCE=$(jq ".[] | first(select(.id == \"$MODULE\")) | $LOAD_REFERENCE_KEY == \"true\"" $JSON_LIST)
	HAS_LOAD_SAMPEL=$(jq ".[] | first(select(.id == \"$MODULE\")) | $LOAD_SAMPLE_KEY == \"true\"" $JSON_LIST)

	if [[ "$HAS_LOAD_REFERENCE" == "true" ]] || [[ "$HAS_LOAD_SAMPEL" == "true" ]]; then
		ENABLE_PAYLOAD="$ENABLE_PAYLOAD, \"parameters\": ["
		
		if [[ "$HAS_LOAD_REFERENCE" == "true" ]]; then
			ENABLE_PAYLOAD="$ENABLE_PAYLOAD {\"key\": \"loadReference\", \"value\": \"true\"}"
		fi

		if [[ "$HAS_LOAD_REFERENCE" == "true" ]] && [[ "$HAS_LOAD_SAMPEL" == "true" ]]; then
			ENABLE_PAYLOAD="$ENABLE_PAYLOAD,"
		fi
		
		if [[ "$HAS_LOAD_SAMPEL" == "true" ]]; then
			ENABLE_PAYLOAD="$ENABLE_PAYLOAD {\"key\": \"loadSample\", \"value\": \"true\"}"
		fi

		ENABLE_PAYLOAD="$ENABLE_PAYLOAD ]"
	fi
	ENABLE_PAYLOAD="$ENABLE_PAYLOAD }"

	# Get cloud Okapi credentials
	local CLOUD_OKAPI_URL=$(jq ".[] | first(select(.id == \"$MODULE\")) | .okapi.url" $JSON_LIST)
	local CLOUD_TENANT=$(jq ".[] | first(select(.id == \"$MODULE\")) | .okapi.tenant" $JSON_LIST)
	local CLOUD_USERNAME=$(jq ".[] | first(select(.id == \"$MODULE\")) | .okapi.credentials.username" $JSON_LIST)
	local CLOUD_PASSWORD=$(jq ".[] | first(select(.id == \"$MODULE\")) | .okapi.credentials.password" $JSON_LIST)
	
	# Remove extra double quotes at start and end of the string
	CLOUD_OKAPI_URL=$(echo $CLOUD_OKAPI_URL | sed 's/"//g')
	CLOUD_TENANT=$(echo $CLOUD_TENANT | sed 's/"//g')
	CLOUD_USERNAME=$(echo $CLOUD_USERNAME | sed 's/"//g')
	CLOUD_PASSWORD=$(echo $CLOUD_PASSWORD | sed 's/"//g')

	
	# Sleep until the deployment process finish
	sleep 15

	# Cloud Okapi login
	login_user_curl $CLOUD_OKAPI_URL $CLOUD_TENANT $CLOUD_USERNAME $CLOUD_PASSWORD
	
	log "Install (Enable) $MODULE"

	set_file_name $BASH_SOURCE
	curl_req --location "http://localhost:$SERVER_PORT/_/tenant" \
		--header "x-okapi-tenant: $CLOUD_TENANT" \
		--header "x-okapi-token: $TOKEN" \
		--header "x-okapi-url: $CLOUD_OKAPI_URL" \
		--header 'Content-Type: application/json' \
		--header "x-okapi-url-to: http://localhost:$SERVER_PORT" \
		--data "$ENABLE_PAYLOAD"

	# Local Okapi login if we should for the consecutive modules
	should_login
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		login_user
	fi
}

kill_process_port() {
	local PORT=$1

	kill -9 $(lsof -i :$PORT | grep LISTEN | awk '{print $2}')
}


get_module_version() {
	local MODULE=$1
	local VERSION_FROM=$2

	if  [[ "$VERSION_FROM" == "pom" ]]; then
		get_module_version_from_pom $MODULE
	fi

	if  [[ "$VERSION_FROM" == "azure_pipeline" ]]; then
		get_module_version_from_azure_pipeline $MODULE
	fi
}

get_module_version_from_pom() {
	local MODULE=$1

	if [ ! -f "$MODULE/pom.xml" ] && [ ! -f "$MODULE/azure-pipelines.yml" ]; then
		set_file_name $BASH_SOURCE
		error "pom.xml file is missing"
	fi

	if [ ! -f "$MODULE/pom.xml" ] && [ -f "$MODULE/azure-pipelines.yml" ]; then
		VERSION_FROM="azure_pipeline"
	fi

	# Opt in the module
	cd $MODULE

	MODULE_VERSION=$(xmllint --xpath "*[local-name()='project']/*[local-name()='version']/text()" pom.xml)

	# Opt out from the module
	cd ..
}

get_module_version_from_azure_pipeline() {
	local MODULE=$1

	if [ ! -f "$MODULE/azure-pipelines.yml" ]; then
		set_file_name $BASH_SOURCE
		error "azure-pipelines.yml file is missing"
	fi

	# Opt in the module
	cd $MODULE

	MODULE_VERSION=$(yq '.variables.[] | select(.name == "tag") | .value' azure-pipelines.yml)

	# Opt out from the module
	cd ..
}

# Pre register mod-authtoken module
pre_authenticate() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	# Do not proceed if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	if [ $MODULE != $LOGIN_WITH_MOD ]; then
		return
	fi

	enable_okapi $INDEX $JSON_LIST

	should_login
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		login_user
	fi

	new_user
	get_user_uuid_by_username
	attach_permissions $UUID
	attach_credentials $UUID
}

# Post register mod-authtoken module
post_authenticate() {
	local MODULE=$1

	if [ $MODULE != $LOGIN_WITH_MOD ]; then
		return
	fi

	login_user
}

# Store new user
new_user() {

	# Check if users api works at all
	should_login
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	has_user $USERNAME
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	log "Add New User:"
	log "username: $USERNAME"
	log "password: $PASSWORD"

	local OPTIONS="-HX-Okapi-Tenant:$TENANT -HContent-Type:application/json"
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS="$OPTIONS -HX-Okapi-Token:$OKAPI_HEADER_TOKEN"
	fi

	set_file_name $BASH_SOURCE
	curl_req --location -XPOST $OKAPI_URL/users $OPTIONS \
		--data '{
		"username": "'$USERNAME'",
		"active": '$USER_ACTIVE',
		"barcode": '$USER_BARCODE',
		"personal": {
			"firstName": "'$USER_PERSONAL_FIRSTNAME'",
			"lastName": "'$USER_PERSONAL_LASTNAME'",
			"middleName": "'$USER_PERSONAL_MIDDLENAME'",
			"preferredFirstName": "'$USER_PERSONAL_PREFERRED_FIRST_NAME'",
			"phone": "'$USER_PERSONAL_PHONE'",
			"mobilePhone": "'$USER_PERSONAL_MOBILE_PHONE'",
			"preferredContactTypeId": "'$USER_PERSONAL_PREFERRED_CONTACT_TYPE_ID'",
			"email": "'$USER_PERSONAL_EMAIL'",
			"imageUrl": "",
			"addresses": [
				{
					"city": "'$USER_PERSONAL_ADDRESSES_CITY'",
					"countryId": "'$USER_PERSONAL_ADDRESSES_COUNTRY_ID'",
					"postalCode": "'$USER_PERSONAL_ADDRESSES_POSTAL_CODE'",
					"addressLine1": "'$USER_PERSONAL_ADDRESSES_ADDRESS_LINE_1'",
					"addressTypeId": "'$USER_PERSONAL_ADDRESSES_ADDRESS_TYPE_ID'"
				}
			]
		},
		"proxyFor": '$USER_PROXY_FOR',
		"departments": '$USER_DEPARTMENTS',
		"patronGroup": "'$USER_PATRON_GROUP'",
		"expirationDate": "",
		"scopes": []
	}'

	get_user_uuid_by_username
}

delete_user() {
	okapi_curl -XDELETE "$OKAPI_URL/users?query=username%3D%3D$1" >> $OUTPUT_FILE && output_debug
}
