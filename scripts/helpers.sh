#!/bin/bash

####################################################
# 		START - VALIDATE PREVIOUS SCRIPTS		   #
####################################################

if [ ! -f scripts/database.sh ]; then
	echo -e "["$(date +"%A, %b %d, %Y %I:%M:%S %p")"] \n\e[1;31m ERROR: Database script file is missing \033[0m"
	
    exit 1
fi

################################################
# 		END - VALIDATE PREVIOUS SCRIPTS		   #
################################################

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

# NOTE:
# -----
# if you pass CALL_STACK_INDEX, SKIP_FAILED_REQ arguments it should be ordered like this,
# firstly the call stack index argument and then the skip failed request argument
curl_req() {
	local CALL_STACK_INDEX=$1

	if [[ "$CALL_STACK_INDEX" =~ ^[0-9]+$ ]]; then
		shift
	else
		CALL_STACK_INDEX=2
	fi

	SKIP_FAILED_REQ=false
	if [[ $1 == false ]]; then
		shift
	fi

	if [[ $1 == true ]]; then
		SKIP_FAILED_REQ=true
		shift
	fi

	if [[ $SUPPRESS_CURRENT_LINE_NO != true ]]; then
		set_line_no $BASH_LINENO
	fi

	output_debug $CALL_STACK_INDEX
	
	# add the file if not already exist
	create_file $RESPONSE_FILE

	STATUS_CODE=$(curl -s -o $RESPONSE_FILE -w "%{http_code}" "$@") 
	CURL_RESPONSE=$(cat $RESPONSE_FILE) && : > $RESPONSE_FILE

	echo $CURL_RESPONSE >> $OUTPUT_FILE

	if ! [[ $STATUS_CODE =~ ^2[0-9][0-9]$ ]] && [[ $SKIP_FAILED_REQ == true ]]; then
		set_file_name $BASH_SOURCE
		debug_line $CALL_STACK_INDEX
		warning "HTTP request failed! (Status Code: $STATUS_CODE)"

		return 0
	fi

	if ! [[ $STATUS_CODE =~ ^2[0-9][0-9]$ ]]; then
		set_file_name $BASH_SOURCE
		debug_line $CALL_STACK_INDEX
		error "HTTP request failed! (Status Code: $STATUS_CODE)"

		return 0
	fi

	return 1
}

delete_curl_req() {
	local CALL_STACK_INDEX=$1

	if [[ "$CALL_STACK_INDEX" =~ ^[0-9]+$ ]]; then
		shift
	else
		CALL_STACK_INDEX=2
	fi

	SKIP_FAILED_REQ=false
	if [[ $1 == false ]]; then
		shift
	fi

	if [[ $1 == true ]]; then
		SKIP_FAILED_REQ=true
		shift
	fi

	set_line_no $BASH_LINENO
	output_debug $CALL_STACK_INDEX

	STATUS_CODE=$(curl -s --location --request DELETE -o $RESPONSE_FILE -w "%{http_code}" "$@") 
	CURL_RESPONSE=$(cat $RESPONSE_FILE) && : > $RESPONSE_FILE

	echo $CURL_RESPONSE >> $OUTPUT_FILE

	if ! [[ $STATUS_CODE =~ ^2[0-9][0-9]$ ]] && [[ $SKIP_FAILED_REQ == true ]]; then
		warning "HTTP request failed! (Status Code: $STATUS_CODE)"

		return 0
	fi

	if ! [[ $STATUS_CODE =~ ^2[0-9][0-9]$ ]]; then
		set_file_name $BASH_SOURCE
		debug_line 2
		error "HTTP request failed! (Status Code: $STATUS_CODE)"

		return 0
	fi

	return 1
}


# Basic Okapi curl boilerplate
okapi_curl() {
	local OPTIONS="-HX-Okapi-Tenant:$TENANT"
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS="-HX-Okapi-Token:$OKAPI_HEADER_TOKEN"
	fi

	SKIP_FAILED_REQ=false
	if [[ $1 == true ]]; then
		SKIP_FAILED_REQ=true
		shift
	fi

	SUPPRESS_CURRENT_LINE_NO=true

	set_line_no $BASH_LINENO
	set_file_name $BASH_SOURCE
	curl_req 3 $SKIP_FAILED_REQ $OPTIONS -HContent-Type:application/json $*
	RESULT=$?

	SUPPRESS_CURRENT_LINE_NO=false

	if [[ "$RESULT" -eq 1 ]]; then
		return 1
	fi

	return 0
}

handle_cloud_okapi() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	has "okapi" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	is_server_okapi_enabled $INDEX $JSON_LIST
	IS_ENABLED=$?
	if [[ "$IS_ENABLED" -eq 0 ]]; then
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

	okapi_curl true -d"{\"username\":\"$USERNAME\",\"userId\":\"$UUID\",\"password\":\"$PASSWORD\"}" $OKAPI_URL/authn/credentials
}

attach_permissions() {
	local UUID=$1

	build_permissions_payload $MODULE
	rebuild_permissions_payload "$PERMISSIONS_PAYLOAD"

	get_permission_id_by_user_id $UUID
	if [[ -z $PUUID ]]; then
		log "Attach permissions ..."

		PUUID=`uuidgen`
		okapi_curl true -d"{\"id\":\"$PUUID\",\"userId\":\"$UUID\",\"permissions\":$PERMISSIONS_PAYLOAD}" $OKAPI_URL/perms/users
		
		return
	fi

	log "Reattach permissions ..."

	okapi_curl true -X PUT -d"{\"id\":\"$PUUID\",\"userId\":\"$UUID\",\"permissions\":$PERMISSIONS_PAYLOAD}" $OKAPI_URL/perms/users/$PUUID
}

build_permissions_payload() {
	local MODULE_GROUP=$1
	
	has_installed_module $MODULE_GROUP
	if [[ $? -eq 0 ]]; then
		return
	fi

	get_user_permissions
	PERMISSIONS_PAYLOAD="$USER_PERMISSIONS"
	for INSTALLED_MODULE in $INSTALLED_MODULES; do
	    # get module permissions group
		get_module_permissions_group ".." $INSTALLED_MODULE

		# combine both module permissions with user permissions
		combine_permissions "$MODULE_GROUP_PERMISSIONS" "$PERMISSIONS_PAYLOAD"
		PERMISSIONS_PAYLOAD="$COMBINED_PERMISSIONS"
	done
}

rebuild_permissions_payload() {
	local PERMISSIONS_PAYLOAD_JSON=$1
	local LENGTH=`echo "$PERMISSIONS_PAYLOAD_JSON" | jq ". | length"`

	PERMISSIONS_PAYLOAD="["
	for ((k=0; k<$LENGTH; k++))
	do
		PERMISSION=$(echo $PERMISSIONS_PAYLOAD_JSON | jq ".[$k]")

		# Remove extra double quotes at start and end of the string
		PERMISSION=$(echo $PERMISSION | sed 's/"//g')

        if [[ $k -eq $LENGTH-1 ]]; then
			PERMISSIONS_PAYLOAD="$PERMISSIONS_PAYLOAD\"$PERMISSION\""
			break
		fi

		PERMISSIONS_PAYLOAD="$PERMISSIONS_PAYLOAD\"$PERMISSION\","
	done
	PERMISSIONS_PAYLOAD="$PERMISSIONS_PAYLOAD]"
}

# Login to obtain the token from the header
login_user() {
	if [[ "$OKAPI_OPTION_ENABLE_SYSTEM_AUTH" == "false" ]]; then
		return
	fi

	is_empty $TOKEN
	if [[ $? -eq 0 ]]; then
		return
	fi

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

	LOGIN_URL_PATH=authn/login
	if [[ $ENABLE_LOGIN_WITH_EXPIRY == "true" ]]; then
		LOGIN_URL_PATH=authn/login-with-expiry
	fi

	set_file_name $BASH_SOURCE
	curl_req -D $HEADERS_FILE -HX-Okapi-Tenant:$TNT -HContent-Type:application/json -HAccept:application/json -d"{\"username\":\"$USR\",\"password\":\"$PWD\"}" $URL/$LOGIN_URL_PATH
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# login from mod-users-bl module but the $LOGIN_WITH_MOD variable value should be 'mod-users-bl'
	# curl_req -D $HEADERS_FILE -HX-Okapi-Tenant:$TNT -HContent-Type:application/json -d"{\"username\":\"$USR\",\"password\":\"$PWD\"}" $URL/bl-users/login?expandPermissions=true&fullPermissions=true
	# if [[ "$?" -eq 0 ]]; then
	# 	return
	# fi

	if [[ $ENABLE_LOGIN_WITH_EXPIRY == "true" ]]; then
		TOKEN=$(grep -i -oP "(?<=set-cookie: $ACCESS_TOKEN_COOKIE_KEY=)[^;]+" "$HEADERS_FILE")
		REFRESH_TOKEN=$(grep -i -oP "(?<=set-cookie: $REFRESH_TOKEN_COOKIE_KEY=)[^;]+" "$HEADERS_FILE")

		new_line
		log "Token: $TOKEN"
		log "Refresh Token: $REFRESH_TOKEN"
		new_line
	else
		TOKEN=`awk '/x-okapi-token/ {print $2}' <$HEADERS_FILE|tr -d '[:space:]'`

		log "Token: $TOKEN"
	fi
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
	IS_ENABLED=$?
	if [[ "$IS_ENABLED" -eq 0 ]]; then
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
	return

	if [ -z "$POSTMAN_API_KEY" ] || [ -z "$POSTMAN_ENV_LOCAL_WITH_OKAPI_UUID" ] || [ -z "$POSTMAN_URL" ] || [ -z "$POSTMAN_ENVIRONMENT_PATH" ]; then
		return 
	fi

	log "Update env postman ... "

	if [ -z "$POSTMAN_ENV_USER_ID_VAL" ]; then
		POSTMAN_ENV_USER_ID_VAL=$UUID
	fi

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
	if [[ "$?" -eq 0 ]]; then
		return
	fi

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

	run_with_docker
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		local WAIT_UNTIL_MOD_USERS_FINISH_STARTING=$OKAPI_WAIT_UNTIL_FINISH_STARTING
		log "Wait for $WAIT_UNTIL_MOD_USERS_FINISH_STARTING seconds until mod-users docker containers finish starting ..."
		sleep $WAIT_UNTIL_MOD_USERS_FINISH_STARTING
	fi

	okapi_curl true $OKAPI_URL/users?query=username%3D%3D$USERNAME
	if [[ "$?" -eq 0 ]]; then
		return
	fi

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
	okapi_curl true $OKAPI_URL/authn/credentials-existence?userId=$UUID
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	RESULT=$(echo $CURL_RESPONSE | jq ".credentialsExist == true")
	RESULT=$(echo $RESULT | sed 's/"//g')
	
	if [[ $RESULT == true ]]; then
		return 1
	fi
	
	return 0
}

has_user_permissions() {
	okapi_curl true $OKAPI_URL/perms/users?limit=1000
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	IS_EMPTY=$(echo $CURL_RESPONSE | jq ".permissionUsers | length == 0")
	IS_EMPTY=$(echo $IS_EMPTY | sed 's/"//g')

	if [[ $IS_EMPTY == true ]]; then
		return 0
	fi

	RESULT=$(echo $CURL_RESPONSE | jq ".permissionUsers[] | .userId == \"$UUID\"")
	RESULT=$(echo $RESULT | sed 's/"//g')

	PUUID=$(echo $CURL_RESPONSE | jq ".permissionUsers[] | first(select(.userId == \"$UUID\")) | .id")
	PUUID=$(echo $PUUID | sed 's/"//g')

	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

has_empty_user_permissions() {
	get_user_permissions

	IS_EMPTY=$(echo $USER_PERMISSIONS | jq ". | length == 0")
	IS_EMPTY=$(echo $IS_EMPTY | sed 's/"//g')

	if [[ $IS_EMPTY == true ]]; then
		return 1
	fi

	return 0
}

get_user_permissions() {
	okapi_curl true $OKAPI_URL/perms/users/$UUID/permissions?indexField=userId
	if [[ "$?" -eq 0 ]]; then
		USER_PERMISSIONS="[]"

		return
	fi

	USER_PERMISSIONS=$(echo $CURL_RESPONSE | jq ".permissionNames")
}

get_permission_id_by_user_id() {
	local UUID=$1
	okapi_curl true $OKAPI_URL/perms/users?limit=1000
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# no user permissions exists 
	IS_EMPTY=$(echo $CURL_RESPONSE | jq ".permissionUsers | length == 0")
	IS_EMPTY=$(echo $IS_EMPTY | sed 's/"//g')
	if [[ $IS_EMPTY == true ]]; then
		return
	fi

	RESULT=$(echo $CURL_RESPONSE | jq ".permissionUsers[] | .userId == \"$UUID\"")
	RESULT=$(echo $RESULT | sed 's/"//g')

	# user has no permissions because he does not exists in the response or you need to increase the 1000 limit value   
	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 0 ]]; then
		return
	fi

	USER_PERMISSIONS=$(echo $CURL_RESPONSE | jq ".permissionUsers[] | first(select(.userId == \"$UUID\")) | .permissions")
	PUUID=$(echo $CURL_RESPONSE | jq ".permissionUsers[] | first(select(.userId == \"$UUID\")) | .id")
	PUUID=$(echo $PUUID | sed 's/"//g')
}

get_module_permissions_group() {
	local RELATIVE_PATH=$1
	local MODULE_GROUP=$2
	local PERMISSIONS_RELATIVE_PATH="$RELATIVE_PATH/$PERMISSIONS_PATH"

	MODULE_GROUP_PERMISSIONS=$(jq '."'$MODULE_GROUP'"' $PERMISSIONS_RELATIVE_PATH)
	if [[ $MODULE_GROUP_PERMISSIONS == null ]]; then
		MODULE_GROUP_PERMISSIONS="[]"
	fi
}

combine_permissions() {
	local USER_PERMISSIONS=$1
	local MODULE_GROUP_PERMISSIONS=$2

    COMBINED_PERMISSIONS=$(echo "[$USER_PERMISSIONS, $MODULE_GROUP_PERMISSIONS]" | jq 'flatten | unique')
}

should_login() {
	has_deployed $AUTHTOKEN_MODULE
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then		
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

is_install_params_enabled() {
	local INDEX=$1
	local JSON_LIST=$2
	
	# By default module is install_params enabled if the key is missing
	has "enabled" $INDEX $JSON_LIST "install_params"
	if [[ "$?" -eq 0 ]]; then
		return 1
	fi

	has_value "enabled" $INDEX "true" $JSON_LIST "install_params"
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
	is_okapi_running_as_process
	IS_PORT_USED=$?
	if [[ "$IS_PORT_USED" -eq 1 ]]; then
		return 1
	fi

	is_okapi_running_as_docker_container
	IS_PORT_USED=$?
	if [[ "$IS_PORT_USED" -eq 1 ]]; then
		return 1
	fi

	return 0
}

is_okapi_running_as_process() {
	is_port_used $OKAPI_PORT

	IS_PORT_USED=$?
	if [[ "$IS_PORT_USED" -eq 0 ]]; then
		return 0
	fi

	return 1
}

# NOTE: Here we check on network if this port has been listend upon uring docker or any other program
is_okapi_running_as_docker_container() {
	is_port_used_by_docker_container $OKAPI_PORT
	local IS_OKAPI_CONTAINER_USED=$?
	if [[ $IS_OKAPI_CONTAINER_USED -eq 1 ]]; then
		return 1
	fi

	return 0
}

is_port_used_by_docker_container() {
	local PORT=$1

	if sudo netstat -tuln | grep -q ":$PORT "; then
		return 1
	fi

	return 0
}

is_docker_container_used() {
	local MODULE=$1

	if [ $( docker ps -a | grep $MODULE | wc -l ) -gt 0 ]; then
		return 1
	fi

	return 0
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

free_from_start_to_end_ports() {
	if [[ $ENABLE_FREE_ALLOCATED_PORTS_FOR_OKAPI_MODULES == "false" ]]; then
		return
	fi

	local START_PORT=$((OKAPI_PORT + 1))

	new_line
	new_line

	log "******************************************************"
	log "Free allocated ports from $START_PORT to $END_PORT ..."
	log "******************************************************"

	local SWAP_OKAPI_PORT=$STOP_OKAPI_PROT_ARG
	
	for ((k=$START_PORT; k<=$END_PORT; k++))
	do
		STOP_OKAPI_PROT_ARG=$k
		stop_running_module
	done
	
	new_line
	new_line

	STOP_OKAPI_PROT_ARG=$SWAP_OKAPI_PORT
}

stop_running_module_or_modules() {
	is_okapi_running
	IS_OKAPI_RUNNING=$?
	if [[ "$IS_OKAPI_RUNNING" -eq 0 ]] ; then
		return
	fi

	# stop okapi and its modules all together
	if [[ "$STOP_OKAPI_ARG" -eq 1 ]] && [[ -z "$STOP_OKAPI_PROT_ARG" ]]; then
		stop_okapi_deployed_modules
        stop_okapi
		delete_tmp_files

		exit 0
	fi

	# stop only okapi
	if [[ "$STOP_OKAPI_ARG" -eq 1 ]] && [[ "$STOP_OKAPI_PROT_ARG" == "okapi" ]]; then
        stop_okapi
		delete_tmp_files

		exit 0
	fi

	# stop modules only
    if [[ "$STOP_OKAPI_ARG" -eq 1 ]] && [[ "$STOP_OKAPI_PROT_ARG" == "modules" ]]; then
		stop_okapi_deployed_modules
		delete_tmp_files

		exit 0
	fi

	# stop module runs on that port
	if [[ "$STOP_OKAPI_ARG" -eq 1 ]] && [[ ! -z "$STOP_OKAPI_PROT_ARG" ]]; then
        stop_running_module
		delete_tmp_files

		exit 0
	fi

	if [[ $SHOULD_STOP_RUNNING_MODULES == "false" ]] && [[ "$STOP_OKAPI_ARG" -eq 0 ]]; then
		return
	fi

	stop_okapi_deployed_modules
}

stop_okapi_deployed_modules() {
	log "Stop okapi deployed modules ..."

	set_file_name $BASH_SOURCE
	curl_req true $OPTIONS $OKAPI_URL/_/discovery/modules
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	while read -r DEPLOYED_MODULE; do
		local MODULE_URL=$(echo "$DEPLOYED_MODULE" | jq -r '.url')
		local SERVICE_ID=$(echo "$DEPLOYED_MODULE" | jq -r '.srvcId')
		local INSTANCE_ID=$(echo "$DEPLOYED_MODULE" | jq -r '.instId')

		# Using sed to extract the port and the module host which could be module name in case we are running with docker
		local MODULE_PORT=$(echo "$MODULE_URL" | sed -n 's/.*:\([0-9]\+\)$/\1/p')
		local MODULE=$(echo "$MODULE_URL" | sed -n 's/.*\/\/\([^:\/]*\).*/\1/p')

		is_port_used $MODULE_PORT
        IS_PORT_USED=$?
        if [[ "$IS_PORT_USED" -eq 1 ]]; then
            kill_process_port $MODULE_PORT
			log "Stopping Module running on port: $MODULE_PORT"

			continue
        fi

		is_docker_container_used $MODULE
		IS_CONTAINER_USED=$?
		if [[ "$IS_CONTAINER_USED" -eq 1 ]]; then

			log "Stopping Module ($MODULE) Container"

			stop_container $MODULE
			remove_container $MODULE
			delete_deployed_module $SERVICE_ID $INSTANCE_ID
		fi
	done < <(echo "$CURL_RESPONSE" | jq -c '.[]')
}

stop_running_module() {
    is_port_used $STOP_OKAPI_PROT_ARG
    IS_PORT_USED=$?
    if [[ "$IS_PORT_USED" -eq 1 ]]; then

		log "Stop running module with port $STOP_OKAPI_PROT_ARG ..."

        kill_process_port $STOP_OKAPI_PROT_ARG

		return
    fi

	is_port_used_by_docker_container $STOP_OKAPI_PROT_ARG
	IS_CONTAINER_USED=$?
	if [[ "$IS_CONTAINER_USED" -eq 1 ]]; then

		log "Stop running module with port $STOP_OKAPI_PROT_ARG ..."

		stop_container_by_port $STOP_OKAPI_PROT_ARG

		return
	fi

	log "Module with port $STOP_OKAPI_PROT_ARG already stopped !"
}

re_export_env_vars() {
	db_defaults

	kafka_defaults

	user_defaults
	
	postman_defaults

	set_okapi_env_vars
}

reset_vars() {
	CLOUD_OKAPI_URL=""
}

export_module_envs() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	has "env" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# Do not proceed if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	log "Export module ($MODULE) environment variables"

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
		log "Stopping Okapi Process ..."

		kill_process_port $OKAPI_PORT
	fi

	is_okapi_running_as_docker_container
	IS_OKAPI_CONTAINER_USED=$?
	if [[ "$IS_OKAPI_CONTAINER_USED" -eq 1 ]]; then
		log "Stopping Okapi Container ..."

		stop_container_by_port $OKAPI_PORT

		return
	fi

	log "Okapi already stopped !"
}

start_okapi() {
	run_with_docker
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		run_okapi_container
	else
		new_line
		log "Okapi start command: "
		log "$OKAPI_COMMAND"
		new_line

		eval "cd $OKAPI_DIR && nohup $OKAPI_COMMAND &"
	fi

	log "Wait for $OKAPI_WAIT_UNTIL_FINISH_STARTING seconds until Okapi is fully up an running"
	sleep $OKAPI_WAIT_UNTIL_FINISH_STARTING
}

init_okapi() {
	run_with_docker
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		init_okapi_container
	fi

	new_line
	log "Okapi init command: "
	log "$OKAPI_INIT_COMMAND"
	new_line

	eval "cd $OKAPI_DIR && nohup $OKAPI_INIT_COMMAND &"

	# wait untill okapi is fully up and initialized
	log "Wait a little until Okapi is fully up an running"
	sleep $OKAPI_WAIT_UNTIL_FINISH_STARTING
}

purge_okapi() {
	run_with_docker
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		purge_okapi_container
	fi

	new_line
	log "Okapi purge command: "
	log "$OKAPI_INIT_COMMAND"
	new_line

	eval "cd $OKAPI_DIR && nohup $OKAPI_PURGE_COMMAND &"
	
	# wait untill okapi is fully up and purged
	log "Wait a little until Okapi is fully up an running"
	sleep $OKAPI_WAIT_UNTIL_FINISH_STARTING
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
	local LOCAL_PORT=$1

	FILTERED_PROCESSES=$(lsof -i :$LOCAL_PORT)
	is_port_used_by_docker_container $LOCAL_PORT
	IS_CONTAINER_USED=$?
	if [[ -z "$FILTERED_PROCESSES" ]] && [[ $IS_CONTAINER_USED -eq 0 ]]; then
		export PORT="$LOCAL_PORT"
		export SERVER_PORT="$LOCAL_PORT"
		export HTTP_PORT="$LOCAL_PORT"
		
		set_file_name $BASH_SOURCE
		curl_req -d"{\"name\":\"PORT\",\"value\":\"$PORT\"}" $OKAPI_URL/_/env
		curl_req -d"{\"name\":\"SERVER_PORT\",\"value\":\"$SERVER_PORT\"}" $OKAPI_URL/_/env
		curl_req -d"{\"name\":\"HTTP_PORT\",\"value\":\"$HTTP_PORT\"}" $OKAPI_URL/_/env

		return
	fi

	LOCAL_PORT=$((LOCAL_PORT + 1))
	export_next_port $LOCAL_PORT
}

get_user_uuid_by_username() {
	if [[ -n $UUID ]]; then
		return
	fi

	local OPTIONS="-HX-Okapi-Tenant:$TENANT"
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS="-HX-Okapi-Token:$OKAPI_HEADER_TOKEN"
	fi

	log "Get user UUID for username: $USERNAME"

	set_file_name $BASH_SOURCE
	okapi_curl true $OPTIONS $OKAPI_URL/users?query=username%3D%3D$USERNAME
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	UUID=$(echo $CURL_RESPONSE | jq ".users[] | select(.username == \"$USERNAME\") | .id")

	# Remove extra double quotes at start and end of the string
	UUID=$(echo $UUID | sed 's/"//g')

	log "User UUID: $UUID"

	POSTMAN_ENV_USER_ID_VAL=$UUID
}

get_install_params() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	# Skip install_params if disabled
	is_install_params_enabled $INDEX $JSON_LIST
	IS_ENABLED=$?
	if [[ "$IS_ENABLED" -eq 0 ]]; then
		return
	fi

	local PURGE_KEY=".install_params.tenantParameters"
	FOUND_PURGE=$(jq ".[$INDEX]$PURGE_KEY | first(select(.purge == \"true\")) | .purge == \"true\"" $JSON_LIST)
	FOUND_PURGE=$(echo $FOUND_PURGE | sed 's/"//g')

	local LOAD_REFERENCE_KEY=".install_params.tenantParameters"
	FOUND_LOAD_REFERENCE=$(jq ".[$INDEX]$LOAD_REFERENCE_KEY | first(select(.loadReference == \"true\")) | .loadReference == \"true\"" $JSON_LIST)
	FOUND_LOAD_REFERENCE=$(echo $FOUND_LOAD_REFERENCE | sed 's/"//g')

	local LOAD_SAMPLE_KEY=".install_params.tenantParameters"
	FOUND_LOAD_SAMPLE=$(jq ".[$INDEX]$LOAD_REFERENCE_KEY | first(select(.loadSample == \"true\")) | .loadSample == \"true\"" $JSON_LIST)
	FOUND_LOAD_SAMPLE=$(echo $FOUND_LOAD_SAMPLE | sed 's/"//g')

	INSTALL_PARAMS=""
	if [[ "$FOUND_PURGE" == "true" ]]; then
		INSTALL_PARAMS="?purge=true&"
	fi

	if [[ "$FOUND_LOAD_REFERENCE" == "true" ]] && [[ "$FOUND_LOAD_SAMPLE" == "true" ]]; then
		INSTALL_PARAMS=$INSTALL_PARAMS"tenantParameters=loadReference%3Dtrue%2CloadSample%3Dtrue"

		return
	fi

	if [[ "$FOUND_LOAD_REFERENCE" == "true" ]]; then
		INSTALL_PARAMS=$INSTALL_PARAMS"tenantParameters=loadReference%3Dtrue"

		return
	fi

	if [[ "$FOUND_LOAD_SAMPLE" == "true" ]]; then
		INSTALL_PARAMS=$INSTALL_PARAMS"tenantParameters=loadSample%3Dtrue"
	fi
}

reset_and_verify_password() {
	local UUID=$1
	local WAITING_BEFORE_RETRY=$2

	if [[ -z "$UUID" ]]; then
		get_user_uuid_by_username
	fi

	# Validate that mod-users-bl exists in modules.json and enabled
	if [[ "$HAS_USERS_BL_MODULE" == false ]]; then
		return
	fi

	# Validate that mod-permissions exists in modules.json and enabled
	if [[ "$HAS_PERMISSIONS_MODULE" == false ]]; then
		return
	fi

	# Validate that mod-password-validator exists in modules.json and enabled
	if [[ "$HAS_PASSWORD_VALIDATOR_MODULE" == false ]]; then
		return
	fi

	get_permission_id_by_user_id $UUID

	log "Reset and verify user password"
	okapi_curl true $OKAPI_URL/bl-users/password-reset/link -d"{\"userId\":\"$UUID\"}"

	JSON_DATA=$CURL_RESPONSE

	# Check if the JSON data contains the string "requires permission".
	if grep -q "requires permission" <<< "$JSON_DATA"; then
		# NOTE: this request does not work for the first time, but it works fine the second time
		# the reason why is not clear but may be related to kafka not finished the task yet,
		# so I just try to wait using sleep command and it did work with me just fine.

		log "Access for user '$USERNAME' requires permission: users-bl.password-reset-link.generate"
		
		log "Please wait until permissions added are persisted, which may delay due to underlying kafka process in users module so we will try again now."

		sleep $WAITING_BEFORE_RETRY

		reset_and_verify_password $UUID $WAITING_BEFORE_RETRY

		return
	fi
	unset JSON_DATA

	RESET_PASSWORD_TOKEN=$(echo $CURL_RESPONSE | jq -r '.link' | sed -e 's/.*\/reset-password\/\([^?]*\).*/\1/g')

	log "Reset password token: $RESET_PASSWORD_TOKEN"

	set_file_name $BASH_SOURCE
	curl_req -HX-Okapi-Token:$RESET_PASSWORD_TOKEN $OKAPI_URL/bl-users/password-reset/validate -d'{}'
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

	# Sleep until the deployment process finishes
	local WAIT_UNTIL_MODULE_FINISH_STARTING=15
	log "Wait for $WAIT_UNTIL_MODULE_FINISH_STARTING seconds until the module finishes starting ..."
	sleep $WAIT_UNTIL_MODULE_FINISH_STARTING

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
	local LOCAL_VERSION_FROM=$2

	if  [[ "$LOCAL_VERSION_FROM" == "pom" ]]; then
		get_module_version_from_pom $MODULE
	fi

	if  [[ "$LOCAL_VERSION_FROM" == "azure_pipeline" ]]; then
		get_module_version_from_azure_pipeline $MODULE
	fi
}

get_module_version_from_pom() {
	local MODULE=$1

	if [ ! -f "$MODULE/pom.xml" ] && [ ! -f "$MODULE/azure-pipelines.yml" ]; then
		set_file_name $BASH_SOURCE

		# some modules does not have pom.xml neither azure-pipelines.hml like mod-reporting
		warning "pom.xml file is missing"

		return
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

	has_installed_module okapi
	if [[  $? -eq 0 ]]; then
		enable_okapi $INDEX $JSON_LIST
	fi

	if [ $MODULE != $LOGIN_WITH_MOD ]; then
		return
	fi

	attach_credentials $UUID
}

# Post register mod-authtoken module
post_authenticate() {
	login_user
}

# Store new user
new_user() {

	# Check if users api works at all
	has_user $USERNAME
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		get_user_uuid_by_username

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
	curl_req true --location -XPOST $OKAPI_URL/users $OPTIONS \
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
			"addresses": []
		},
		"proxyFor": '$USER_PROXY_FOR',
		"departments": '$USER_DEPARTMENTS',
		"expirationDate": ""
	}'

	get_user_uuid_by_username
}

delete_user() {
	okapi_curl -XDELETE "$OKAPI_URL/users?query=username%3D%3D$1" >> $OUTPUT_FILE && output_debug
}

delete_deployed_module() {
	local MODULE=$1
	local INSTANCE_ID=$2

	local OPTIONS="-HContent-Type:application/json"
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS="$OPTIONS -HX-Okapi-Token:$OKAPI_HEADER_TOKEN"
	fi

	set_file_name $BASH_SOURCE
	curl_req --location -XDELETE $OKAPI_URL/_/discovery/modules/$MODULE/$INSTANCE_ID $OPTIONS
}

import_aliases() {
	if [[ "$IMPORT_ALIASES_ARG" -eq 0 ]]; then
		return
	fi

	log "Import aliases started ..."

	local RELATIVE_PATH=".."
	local ALIASES_RELATIVE_PATH="$RELATIVE_PATH/$ALIASES_PATH"
	
	if [[ ! -f  "$BASHRC_PATH" ]]; then
		error "$BASHRC_PATH does not exists !"
	fi

	if [[ ! -f "$ALIASES_RELATIVE_PATH" ]]; then
		error "$ALIASES_RELATIVE_PATH does not exists !"
	fi

	if [[ -f  $BASH_ALIASES_PATH ]]; then
		echo "" >> $BASH_ALIASES_PATH & echo "" >> $BASH_ALIASES_PATH
		cat $ALIASES_RELATIVE_PATH >> $BASH_ALIASES_PATH
		source $BASHRC_PATH
	fi

	if [[ ! -f  $BASH_ALIASES_PATH ]]; then
		echo "" >> $BASHRC_PATH & echo "" >> $BASHRC_PATH
		cat $ALIASES_RELATIVE_PATH >> $BASHRC_PATH
		source $BASHRC_PATH
	fi

	log "Import aliases finished ..."

	exit 0
}

get_current_branch() {
	CURRENT_BRANCH=$(git branch | sed -n -e 's/^\* \(.*\)/\1/p')
}

has_tag() {
	local TAG=$1

	if git rev-parse --verify refs/tags/$TAG > /dev/null 2>&1; then
		return 1
	fi

	return 0
}

has_branch() {
	local BRANCH=$1

	if [[ `git rev-parse --verify "$BRANCH" 2>/dev/null` ]]; then
		return 1
	fi

	return 0
}

get_deployed_instance_id() {
	local MODULE=$1
	local LOCAL_VERSION_FROM=$2

	get_module_versioned $MODULE $LOCAL_VERSION_FROM

	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	set_file_name $BASH_SOURCE
	curl_req $OPTIONS $OKAPI_URL/_/discovery/modules
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	DEPLOYED_INSTANCE_ID=$(echo $CURL_RESPONSE | jq ".[] | first(select(.srvcId == \"$VERSIONED_MODULE\")) | .instId")
	DEPLOYED_INSTANCE_ID=$(echo $DEPLOYED_INSTANCE_ID | sed 's/"//g')
}

# NOTE: it does not work if authtoken instance is not up and running
remove_authtoken_and_permissions_if_enabled_previously() {
	if [[ $REMOVE_AUTHTOKEN_IF_ENABLED_PREVIOUSLY == "true" ]]; then
		new_line
		delete_installed_module $AUTHTOKEN_MODULE
		delete_installed_module $PERMISSIONS_MODULE
		new_line
	fi
}

remove_module_from_tenant() {
	local VERSIONED_MODULE=$1
	local TENANT=$2

	log "Remove module (${VERSIONED_MODULE}) from tenant (${TENANT})"

	delete_curl_req true --request DELETE $OKAPI_URL/_/proxy/tenants/$TENANT/modules/$VERSIONED_MODULE --header 'Content-Type: application/json'

	if [[ "$?" -eq 0 ]]; then
		return 0 
	fi

	return 1 
}

remove_deployed_module() {
	local VERSIONED_MODULE=$1
	local INSTANCE_ID=$2

	log "Remove deployed module (${VERSIONED_MODULE})"

	delete_curl_req true --request DELETE $OKAPI_URL/_/discovery/modules/$VERSIONED_MODULE/$INSTANCE_ID --header 'Content-Type: application/json'

	if [[ "$?" -eq 0 ]]; then
		return 0 
	fi

	return 1 
}

deploy_module_request() {
	local MODULE=$1
	local DEPLOY_DESCRIPTOR=$MODULE/target/DeploymentDescriptor.json

	has_deployed $MODULE
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	log "Deploy module (${MODULE})"

	export_next_port $SERVER_PORT

	run_with_docker
	FOUND=$?
	if [[ $FOUND -eq 1 ]]; then
		deploy_module_container $MODULE

		return
	fi

	set_file_name $BASH_SOURCE
	curl_req -d@$DEPLOY_DESCRIPTOR $OKAPI_URL/_/deployment/modules
}

install_module_request() {
	local ACTION=$1
	local MODULE=$2

	# Build Body Json list of modules with action enable comes as argument
	has_installed $MODULE $TENANT $VERSION_FROM
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		# It means the module already installed
		add_installed_module $MODULE

		return
	fi

	local PAYLOAD="[{\"action\":\"$ACTION\",\"id\":\"$VERSIONED_MODULE\"}]"

	# Set Okapi Token if set
	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	# Validate if the list is not empty	
	if [[ "$PAYLOAD" =~ ^\[.+\]$ ]]; then
		log "Install (Enable) $MODULE with version ($MODULE_VERSION)"

		# Install (enable) modules
		set_file_name $BASH_SOURCE
		curl_req $OPTIONS -d "$PAYLOAD" "$OKAPI_URL/_/proxy/tenants/$TENANT/install"
		if [[ $? -eq 1 ]]; then
			add_installed_module $MODULE
		fi
	fi
}

disable_installed_module() {
	local MODULE=$1
	
	get_installed_module_versioned $MODULE

	if [[ -n "$VERSIONED_MODULE" ]]; then
		log "Disable installed (enabled) module ($MODULE)"

		update_installed_module_status $MODULE false
	fi

	unset VERSIONED_MODULE
}

enable_installed_module() {
	local MODULE=$1
	
	get_installed_module_versioned $MODULE
		
	if [[ -n "$VERSIONED_MODULE" ]]; then
		log "Enable installed (enabled) module ($MODULE)"
		
		update_installed_module_status $MODULE true
	fi

	unset VERSIONED_MODULE
}

delete_installed_module() {
	local MODULE=$1

	is_empty $MODULE
	if [[ $? -eq 1 ]]; then
		return
	fi

	delete_installed_module_from_enabled_modules $MODULE
}

update_installed_module_status() {
	local MODULE=$1
	local STATUS=$2

	is_empty $MODULE
	if [[ $? -eq 1 ]]; then
		return
	fi


	is_empty $STATUS
	if [[ $? -eq 1 ]]; then
		return
	fi

	get_update_installed_module_status_query $MODULE $STATUS

	db_run_query "$QUERY"
}

delete_installed_module_from_enabled_modules() {
	local MODULE=$1

	log "Remove installed (enabled) module ($MODULE)"

	get_delete_installed_module_query $MODULE

	db_run_query "$QUERY"
}

get_update_installed_module_status_query() {
	local MODULE="$1"
	local STATUS=$2

	QUERY=`printf "$UPDATE_INSTALLED_MODULE_STATUS_QUERY" $MODULE $STATUS`
}

get_delete_installed_module_query() {
	local MODULE="$1"

	QUERY=`printf "$DELETE_INSTALLED_MODULE_QUERY" $MODULE`
}

empty_requires_array_in_module_descriptor() {
	jq '.requires = []' target/ModuleDescriptor.json > tmp.json && mv tmp.json target/ModuleDescriptor.json
}

checkout_new_tag() {
	local MODULE=$1

	if [[ "$HAS_NEW_TAG" != true ]]; then
		return
	fi

	# Opt in the module
	cd $MODULE

	log "Fetch all remote for $MODULE before checkout tag"

	git fetch --all --tags

	has_tag $NEW_MODULE_TAG
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		SHOULD_REBUILD_MODULE="$MODULE"
		log "Checkout $NEW_MODULE_TAG Tag for module: $MODULE"

		git checkout tags/$NEW_MODULE_TAG
	else
		error "Tag $NEW_MODULE_TAG does not exists !"
	fi

	# Opt out from the module
	cd ..

	unset HAS_NEW_TAG
	unset NEW_MODULE_TAG
}

checkout_new_branch() {
	local MODULE=$1

	if [[ "$HAS_NEW_BRANCH" != true ]]; then
		return
	fi

	# Opt in the module
	cd $MODULE

	log "Fetch all for $MODULE before checkout branch"

	git fetch --all --tags

	has_branch $NEW_MODULE_BRANCH
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		SHOULD_REBUILD_MODULE="$MODULE"
		log "Checkout $NEW_MODULE_BRANCH Branch for module: $MODULE"
		git checkout $NEW_MODULE_BRANCH
	else
		error "Branch $NEW_MODULE_BRANCH does not exists !"
	fi

	# Opt out from the module
	cd ..

	unset HAS_NEW_BRANCH
	unset NEW_MODULE_BRANCH
}

remove_directory() {
	rm -rf $1
}

get_module_versioned() {
	local MODULE=$1
	local LOCAL_VERSION_FROM=$2
	unset VERSIONED_MODULE
	unset MODULE_VERSION

	get_module_version $MODULE $LOCAL_VERSION_FROM

	VERSIONED_MODULE="$MODULE"
	if [[ -n $MODULE_VERSION ]]; then
		VERSIONED_MODULE="$MODULE-$MODULE_VERSION"
	fi
}

get_installed_module_versioned() {
	local MODULE=$1
	unset VERSIONED_MODULE
	unset MODULE_VERSION

	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	set_file_name $BASH_SOURCE
	curl_req true $OPTIONS $OKAPI_URL/_/proxy/tenants/$TENANT/modules
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	RESULT=$(echo $CURL_RESPONSE | jq '[.[] | select(.id | contains("'$MODULE'"))] | .[0].id')
	RESULT=$(echo $RESULT | sed 's/"//g')

	if [[ -n "$RESULT" ]] && [[ "$RESULT" != "null" ]]; then
		VERSIONED_MODULE="$RESULT"
	fi
}

get_okapi_docker_container_env_options() {
	OKAPI_DOCKER_ENV_OPTIONS=""
	while read -r LINE; do
		local NAME=$(echo "$LINE" | jq -r '.name')
		local VALUE=$(echo "$LINE" | jq -r '.value')

		# Within docker we have the default port 8081 or what ever this variable contains $DOCKER_MODULE_DEFAULT_PORT
		if [[ $NAME == "PORT" ]] || [[ $NAME == "SERVER_PORT" ]] || [[ $NAME == "HTTP_PORT" ]]; then
			VALUE=$DOCKER_MODULE_DEFAULT_PORT
		fi

		if [[ $NAME == "OKAPI_URL" ]]; then
			VALUE=$DOCKER_OKAPI_URL
		fi

		OKAPI_DOCKER_ENV_OPTIONS="$OKAPI_DOCKER_ENV_OPTIONS --env $NAME=$VALUE "
	done < <(echo "$OKAPI_ENV_VARS" | jq -c '.[]')
}

get_module_docker_container_env_options() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	has "env" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	local LENGTH=$(jq ".[$INDEX].env | length" $JSON_LIST)

	MODULE_DOCKER_ENV_OPTIONS=""
	for ((k=0; k<$LENGTH; k++))
	do
		ENV_NAME=$(jq ".[$INDEX].env[$k].name" $JSON_LIST)
		ENV_VALUE=$(jq ".[$INDEX].env[$k].value" $JSON_LIST)

		# Remove extra double quotes at start and end of the string
		ENV_NAME=$(echo $ENV_NAME | sed 's/"//g')
		ENV_VALUE=$(echo $ENV_VALUE | sed 's/"//g')

		MODULE_DOCKER_ENV_OPTIONS="$MODULE_DOCKER_ENV_OPTIONS --env $ENV_NAME=$ENV_VALUE "
	done
}

trim() {
    TO_BE_TRIMMED=$1

    # Trim leading spaces
    TRIMMED="${TO_BE_TRIMMED#"${TO_BE_TRIMMED%%[![:space:]]*}"}"

    # Trim trailing spaces
    TRIMMED="${TRIMMED%"${TRIMMED##*[![:space:]]}"}"
}

stop_container_by_port() {
	local PORT=$1

	$DOCKER_CMD stop $($DOCKER_CMD ps --filter "expose=$PORT" -q)
}

does_container_exists() {
    local CONTAINER=$1

    if `$DOCKER_CMD inspect "$CONTAINER" &> /dev/null`; then
        return 1
    fi

    return 0
}

is_container_running() {
    local CONTAINER=$1

    does_container_exists $CONTAINER
    DOES_CONTAINER_EXISTS=$?
    if [ $DOES_CONTAINER_EXISTS -eq 0 ]; then
        return 0
    fi

    if [ "$($DOCKER_CMD container inspect -f '{{.State.Running}}' $CONTAINER)" == "true" ]; then
        return 1
    fi

    return 0
}

stop_container() {
    local CONTAINER=$1

	is_container_running $CONTAINER
	IS_CONTAINER_RUNNING=$?
	if [ $IS_CONTAINER_RUNNING -eq 1 ]; then
		log "Stop Container $CONTAINER"
		
		$DOCKER_CMD stop $CONTAINER
	fi
}
 
remove_container() {
	local CONTAINER=$1

	does_container_exists $CONTAINER
	DOES_CONTAINER_EXISTS=$?
	if [ $DOES_CONTAINER_EXISTS -eq 1 ]; then
		log "Remove Container $CONTAINER"

		$DOCKER_CMD rm -f -v $CONTAINER
	fi
}

start_container() {
	local CONTAINER=$1

	does_container_exists $CONTAINER
	DOES_CONTAINER_EXISTS=$?
	if [ $DOES_CONTAINER_EXISTS -eq 0 ]; then
		return
	fi

	is_container_running $CONTAINER
	IS_CONTAINER_RUNNING=$?
	if [ $IS_CONTAINER_RUNNING -eq 1 ]; then
		return
	fi

	log "Start Container $CONTAINER"

	$DOCKER_CMD start $CONTAINER
}

build_container() {
	local CONTAINER=$1

	stop_container $CONTAINER

	remove_container $CONTAINER

	$DOCKER_CMD build -t $CONTAINER .
}

run_container() {
	local CONTAINER=$1
	local MODULE=$2
	local OUTER_PORT=$3
	local INNER_PORT=$4
	local MODULE_DOCKER_ENV_OPTIONS=$5

	shift && shift && shift && shift && shift

	local ARGS=$*

	build_container $CONTAINER

	get_okapi_docker_container_env_options

	# TODO: JDK_JAVA_OPTIONS should be reviewed and tested properly
	MODULE_DOCKER_ENV_OPTIONS="$MODULE_DOCKER_ENV_OPTIONS -e JDK_JAVA_OPTIONS='-Dport=$DOCKER_MODULE_DEFAULT_PORT -Dhttp.port=$DOCKER_MODULE_DEFAULT_PORT -Dserver.port=$DOCKER_MODULE_DEFAULT_PORT'"

	# If there is duplicate env vars from okapi and module the module env vars will overwrite any duplicates in the okapi env vars as they came the last
	eval "$DOCKER_CMD run -d --name $CONTAINER -p $OUTER_PORT:$INNER_PORT --add-host=$DOCKER_ADDED_HOST --network $DOCKER_NETWORK $OKAPI_DOCKER_ENV_OPTIONS $MODULE_DOCKER_ENV_OPTIONS $MODULE $ARGS"
}

run_module_container() {
	local MODULE=$1
	
	cd $MODULE

	run_container $MODULE $MODULE $SERVER_PORT $DOCKER_MODULE_DEFAULT_PORT "$MODULE_DOCKER_ENV_OPTIONS"

	# remove it after each module so it will not be added to the next modules
	unset MODULE_DOCKER_ENV_OPTIONS

	cd ..
}

run_okapi_container() {
	cd $OKAPI_CORE_DIR

	build_container $OKAPI_DOCKER_CONTAINER_NAME

	$DOCKER_CMD run -d --name $OKAPI_DOCKER_CONTAINER_NAME -p $OKAPI_PORT:$OKAPI_PORT --network $DOCKER_NETWORK --env JAVA_OPTIONS="$OKAPI_JAVA_OPTIONS" $OKAPI_DOCKER_IMAGE_TAG $OKAPI_ARG_DEV

	cd $RETURN_FROM_OKAPI_CORE_DIR
}

init_okapi_container() {
	cd $OKAPI_CORE_DIR

	build_container $OKAPI_DOCKER_CONTAINER_NAME

	$DOCKER_CMD run -d --name $OKAPI_DOCKER_CONTAINER_NAME -p $OKAPI_PORT:$OKAPI_PORT --network $DOCKER_NETWORK --env JAVA_OPTIONS="$OKAPI_JAVA_OPTIONS" $OKAPI_DOCKER_IMAGE_TAG $OKAPI_ARG_INIT

	cd $RETURN_FROM_OKAPI_CORE_DIR
}

purge_okapi_container() {
	cd $OKAPI_CORE_DIR

	build_container $OKAPI_DOCKER_CONTAINER_NAME

	$DOCKER_CMD run -d --name $OKAPI_DOCKER_CONTAINER_NAME -p $OKAPI_PORT:$OKAPI_PORT --network $DOCKER_NETWORK --env JAVA_OPTIONS="$OKAPI_JAVA_OPTIONS" $OKAPI_DOCKER_IMAGE_TAG $OKAPI_ARG_PURGE

	cd $RETURN_FROM_OKAPI_CORE_DIR
}

run_with_docker() {
	if [[ "$RUN_WITH_DOCKER" == "true" ]]; then
		return 1
	fi

	return 0
}

delete_deployed_modules() {
	log "Delete deployed modules ..."

	set_file_name $BASH_SOURCE
	curl_req true $OPTIONS $OKAPI_URL/_/discovery/modules
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	while read -r DEPLOYED_MODULE; do
		local MODULE_URL=$(echo "$DEPLOYED_MODULE" | jq -r '.url')
		local SERVICE_ID=$(echo "$DEPLOYED_MODULE" | jq -r '.srvcId')
		local INSTANCE_ID=$(echo "$DEPLOYED_MODULE" | jq -r '.instId')

		log "Delete deployed Module with Service ID ($SERVICE_ID) Container"

		delete_deployed_module $SERVICE_ID $INSTANCE_ID
	done < <(echo $CURL_RESPONSE | jq -c '.[]')
}

build_directory_exists() {
	local MODULE=$1
	local BUILD_DIR=target

	if [ -d $MODULE/$BUILD_DIR ]; then
		return 1
	fi

	return 0
}

module_dir_exists() {
	local MODULE="$1"
	if [[ -d "$MODULE" ]]; then
		return 1
	fi

	return 0
}

set_module_id() {
	local INDEX=$1
	local JSON_LIST=$2

	# Validate Module Id
	validate_module_id $INDEX $JSON_LIST
}

filter_modules_json() {
	local MODULES_JSON_FILE=$1
	local FILTERED_MODULES=$2
	local ALL_MODULES_JSON=$(jq '.' $MODULES_JSON_FILE)
	FILTERED_MODULES_JSON=$ALL_MODULES_JSON
	for FILTERED_MODULE in $FILTERED_MODULES; do
		FILTERED_MODULES_JSON=$(echo $FILTERED_MODULES_JSON | jq 'map(select(.id | test("'$FILTERED_MODULE'") | not))')
	done
	
	echo $FILTERED_MODULES_JSON > $FILTERED_JSON_FILE
}

filter_disabled_modules() {
	local MODULES_JSON_FILE=$1

	local ENABLED_MODULES_JSON=$(jq '[.[] | select((has("enabled") and .enabled == "true") or (has("enabled") | not))]' $MODULES_JSON_FILE)

	echo $ENABLED_MODULES_JSON > $FILTERED_JSON_FILE
}

delete_files() {
	local DELETED_FILES=$1
	
	for DELETED_FILE in $DELETED_FILES; do
		delete_file $DELETED_FILE
	done
}

delete_file() {
	local DELETED_FILE=$1

	log "Delete file: $DELETED_FILE"

	rm -f $DELETED_FILE
}

get_module_index_by_id() {
    local MODULE=$1
    local FILE=$2

    MODULE_INDEX=$(jq 'map(.id) | index("'$MODULE'")' $FILE)
}

function_exists() {
    if command -v "$1" &>/dev/null; then
        return 0 # Function exists
    else
        return 1 # Function does not exist
    fi
}

create_file() {
	local FILE_NAME=$1

	touch $FILE_NAME
}

delete_tmp_files() {
    new_line
	log "Delete temporary files ..."

	delete_files "$OUTPUT_FILE $RESPONSE_FILE $FILTERED_JSON_FILE $HEADERS_FILE"
}

directory_contains_files_by_extension_check() {
    local DIRECTORY=$1
    local EXT=$2

    if find $1 -maxdepth 1 -name "*.$EXT" | grep -q .; then
        return 1  
    fi

    return 0
}

is_argument_exists_in_available_args() {
	local INPUT_ARG=$1
	local AVAILABLE_ARGS=$2
	
    for AVAILABLE_ARG in $AVAILABLE_ARGS; do
		if [[ $AVAILABLE_ARG == $INPUT_ARG ]]; then
			return
		fi
    done

	error "Invalid argument, please check your arguments"
}

add_installed_module() {
	local MODULE_ID=$1

	has_installed_module $MODULE_ID
	if [[ $? -eq 1 ]]; then
		return
	fi

	log "Add module ($MODULE_ID) to installed module list" 

	if [[ -z $INSTALLED_MODULES ]]; then
		INSTALLED_MODULES=$MODULE_ID

		return
	fi

	INSTALLED_MODULES="$INSTALLED_MODULES $MODULE_ID"
}

has_installed_module() {
	local MODULE_ID=$1
	
	log "Check if module ($MODULE_ID) has been installed already" 

	for INSTALLED_MODULE in $INSTALLED_MODULES; do
		if [[ $INSTALLED_MODULE == $MODULE_ID ]]; then
			return 1
		fi
	done

	return 0
}

is_empty() {
	local VAR=$1

	if [ -z "${VAR+x}" ]; then
		return 1
	elif [ -z "$VAR" ]; then
		return 1
	else
		return 0
	fi
}

log_stars_title() {
    local title="$1"
    local star_line_length=$(( ${#title} + 4 )) # 2 spaces + 2 stars
    local star_line=$(printf '*%.0s' $(seq 1 $star_line_length))
    
    log "$star_line"
    log "* $title *"
    log "$star_line"
}