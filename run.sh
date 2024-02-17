#!/bin/bash

#############################################################################################
# - Sections order:																			#
# 	+ Helpers																				#
# 	+ Prepare																				#
#	+ Validation																			#
# 	+ Processing (Clone, Build (Compile), Register (Declare), Deploy, Install (Enable))		#
# 	+ Run																					#
#############################################################################################


################################
# 		START - HELPERS		   #
################################

log() {
	local MSG=$1

	echo -e "["$(date +"%A, %b %d, %Y %I:%M:%S %p")"] $MSG"
}

new_line() {
	echo -e "\n"
}

# Output Error
error() {
    log "\n\e[1;31m ERROR: $1 \033[0m"
	
    exit 1
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

# Get file content
get_file_content() {
	# Get the name of the JSON file.
	local FILE_NAME=$1

	# Read the contents of the JSON file.
	JSON_DATA="$(cat $FILE_NAME)"
}

# Search in arguments
has_arg() {
	local ARGS=$1
	local FIND=$2
	
	for ARG in $ARGS; do
		if [[ "$ARG" =~ "$FIND" ]]; then
			return 1
		fi
	done

	return 0
}

# Basic Okapi curl boilerplate
okapi_curl() {
	local OPTIONS="-HX-Okapi-Tenant:$TENANT"
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS="-HX-Okapi-Token:$OKAPI_HEADER_TOKEN"
	fi

	curl -s $OPTIONS -HContent-Type:application/json $*
	new_line
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

pre_clone() {
	local INDEX=$1
	local JSON_LIST=$2

	# Validate Module Id
	validate_module_id $INDEX $JSON_LIST

	# Validate Module Repo
	validate_module_repo $MODULE_ID $INDEX $JSON_LIST

	# Validate Module Tags and Branches
	validate_module_tag_branch $INDEX $JSON_LIST

	# Validate Access Token
	validate_module_access_token $INDEX $JSON_LIST

	export_module_envs $MODULE_ID $INDEX $JSON_LIST
}

pre_register() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	handle_cloud_okapi $MODULE $INDEX $JSON_LIST

	# Do not export next port for Okapi modules if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	should_register $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	pre_authenticate $MODULE $INDEX $JSON_LIST
}

post_install() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	postman $MODULE $INDEX $JSON_LIST

	# Do not proceed  if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	# Add new user
	local USERS_MODULE="mod-users"
	if [ $MODULE = $USERS_MODULE ]; then
		new_user
		
		get_user_uuid_by_username

		# Update postman environment variables
		update_env_postman $POSTMAN_API_KEY
	fi

	should_install $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	post_authenticate $MODULE

	# Set permissions related to mod-users-bl
	local USERS_BL_MODULE="mod-users-bl"
	if [ $MODULE = $USERS_BL_MODULE ]; then
		set_users_bl_module_permissions $INDEX

		# Update postman environment variables
		update_env_postman $POSTMAN_API_KEY
	fi

	re_export_env_vars
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

	local AUTHTOKEN_MODULE="mod-authtoken"
	if [ $MODULE != $AUTHTOKEN_MODULE ]; then
		return
	fi

	enable_okapi $INDEX $JSON_LIST

	should_login
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		login_admin
		get_user_uuid_by_username

		return
	fi

	make_adminuser
}

# Post register mod-authtoken module
post_authenticate() {
	local MODULE=$1
	local AUTHTOKEN_MODULE="mod-authtoken"

	if [ $MODULE != $AUTHTOKEN_MODULE ]; then
		return
	fi

	login_admin
}

# New admin user with all permissions
make_adminuser() {
	log "Make Admin User with credentials: "
	log "username: $USERNAME"
	log "password: $PASSWORD"
	new_line

	# Delete admin user firstly if exists
	delete_user $USERNAME

	# New admin user
	new_user

	# Attach Credentials
	UUID=`uuidgen`
	attach_credentials $UUID

	# Set permissions for the new admin user
	attach_permissions $UUID
	new_line
}

attach_credentials() {
	local UUID=$1

	okapi_curl -d"{\"username\":\"$USERNAME\",\"userId\":\"$UUID\",\"password\":\"$PASSWORD\"}" $OKAPI_URL/authn/credentials
	new_line
}

attach_permissions() {
	local UUID=$1

	PUUID=`uuidgen`
	okapi_curl -d"{\"id\":\"$PUUID\",\"userId\":\"$UUID\",\"permissions\":[\"okapi.all\",\"perms.all\",\"users.all\",\"login.item.post\",\"perms.users.assign.immutable\"]}" $OKAPI_URL/perms/users
}

# Login to obtain the token from the header
login_admin() {
	log "Login with credentials: "
	log "username: $USERNAME"
	log "password: $PASSWORD"
	new_line

	login_admin_curl $OKAPI_URL $TENANT $USERNAME $PASSWORD
	new_line

	OKAPI_HEADER_TOKEN=$TOKEN
	POSTMAN_ENV_TOKEN_VAL=$TOKEN
}

login_admin_curl() {
	local URL=$1
	local TNT=$2
	local USR=$3
	local PWD=$4
	
	curl -s -Dheaders -HX-Okapi-Tenant:$TNT -HContent-Type:application/json -d"{\"username\":\"$USR\",\"password\":\"$PWD\"}" $URL/authn/login
	new_line

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

	validate_postman_api_key $INDEX $JSON_LIST

	import_postman_openapi $POSTMAN_API_KEY $OPEN_API_FILE $MODULE
}

import_postman_openapi() {
	log "Import postman openapi collection"

	local POSTMAN_API_KEY=$1
	local OPEN_API_FILE=$2
	local MODULE=$3

	curl -s $POSTMAN_URL$POSTMAN_IMPORT_OPENAPI_PATH \
		-HContent-Type:multipart/form-data \
		-HAccept:application/vnd.api.v10+json \
		-HX-API-Key:$POSTMAN_API_KEY \
		-Ftype="file" \
		-Finput=@"$MODULE/$OPEN_API_FILE" | jq .

	new_line
}

update_env_postman() {
	log "Update env postman"

	local POSTMAN_API_KEY=$1

	curl -s --location -XPUT $POSTMAN_URL$POSTMAN_ENVIRONMENT_PATH'/'$POSTMAN_ENV_LOCAL_WITH_OKAPI_UUID \
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
					}
				]
			}
		}'

	new_line
}

has_tenant() {
	local TENANT=$1
	
	RESULT=$(curl -s $OKAPI_URL/_/proxy/tenants | jq ".[] | .id | contains(\"$TENANT\")")

	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

has_user() {
	local USERNAME=$1
	
	RESULT=$(okapi_curl $OKAPI_URL/users | jq ".users[] | .username | contains(\"$USERNAME\")")

	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

has_registered() {
	local MODULE_ID=$1

	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	RESULT=$(curl -s $OPTIONS $OKAPI_URL/_/proxy/modules | jq ".[] | .id | contains(\"$MODULE_ID\")")

	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

has_deployed() {
	local MODULE_ID=$1

	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	RESULT=$(curl -s $OPTIONS $OKAPI_URL/_/discovery/modules | jq ".[] | .srvcId | contains(\"$MODULE_ID\")")

	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

has_installed() {
	local MODULE_ID=$1
	local TENANT=$2

	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	RESULT=$(curl -s $OPTIONS $OKAPI_URL/_/proxy/tenants/$TENANT/modules | jq ".[] | .id | contains(\"$MODULE_ID\")")

	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

should_login() {
	STATUS_CODE=$(curl -s -w "%{http_code}" -HX-Okapi-Tenant:$TENANT $OKAPI_URL/users -o /dev/null)

	if [[ "$STATUS_CODE" != "200" ]]; then
		return 1
	fi

	return 0
}

should_clone() {
	local INDEX=$1
	local JSON_LIST=$2

	has "step" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return 1
	fi

	has_value "step" $INDEX "clone" $JSON_LIST
	local SHOULD_CLONE=$?

	has_value "step" $INDEX "build" $JSON_LIST
	local SHOULD_BUILD=$?

	has_value "step" $INDEX "register" $JSON_LIST
	local SHOULD_REGISTER=$?

	has_value "step" $INDEX "deploy" $JSON_LIST
	local SHOULD_DEPLOY=$?

	has_value "step" $INDEX "install" $JSON_LIST
	local SHOULD_INSTALL=$?

	if [[ "$SHOULD_CLONE" -eq 1 ]] || [[ "$SHOULD_BUILD" -eq 1 ]] || [[ "$SHOULD_REGISTER" -eq 1 ]] || [[ "$SHOULD_DEPLOY" -eq 1 ]] || [[ "$SHOULD_INSTALL" -eq 1 ]]; then
		return 1
	fi

	return 0
}

should_build() {
	local INDEX=$1
	local JSON_LIST=$2

	has "step" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return 1
	fi

	has_value "step" $INDEX "build" $JSON_LIST
	local SHOULD_BUILD=$?

	has_value "step" $INDEX "register" $JSON_LIST
	local SHOULD_REGISTER=$?

	has_value "step" $INDEX "deploy" $JSON_LIST
	local SHOULD_DEPLOY=$?

	has_value "step" $INDEX "install" $JSON_LIST
	local SHOULD_INSTALL=$?

	if [[ "$SHOULD_BUILD" -eq 1 ]] || [[ "$SHOULD_REGISTER" -eq 1 ]] || [[ "$SHOULD_DEPLOY" -eq 1 ]] || [[ "$SHOULD_INSTALL" -eq 1 ]]; then
		return 1
	fi

	return 0
}

should_rebuild() {
	local INDEX=$1
	local JSON_LIST=$2
	
	# By default module should not be rebuilt if the key is missing
	has "rebuild" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return 0
	fi

	has_value "rebuild" $INDEX "true" $JSON_LIST
	if [[ "$?" -eq 1 ]]; then
		return 1
	fi

	return 0
}

should_register() {
	local INDEX=$1
	local JSON_LIST=$2

	has "step" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return 1
	fi

	has_value "step" $INDEX "register" $JSON_LIST
	local SHOULD_REGISTER=$?

	has_value "step" $INDEX "deploy" $JSON_LIST
	local SHOULD_DEPLOY=$?

	has_value "step" $INDEX "install" $JSON_LIST
	local SHOULD_INSTALL=$?

	if [[ "$SHOULD_REGISTER" -eq 1 ]] || [[ "$SHOULD_DEPLOY" -eq 1 ]] || [[ "$SHOULD_INSTALL" -eq 1 ]]; then
		return 1
	fi

	return 0
}

should_deploy() {
	local INDEX=$1
	local JSON_LIST=$2

	has "step" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return 1
	fi

	has_value "step" $INDEX "deploy" $JSON_LIST
	local SHOULD_DEPLOY=$?

	has_value "step" $INDEX "install" $JSON_LIST
	local SHOULD_INSTALL=$?

	if [[ "$SHOULD_DEPLOY" -eq 1 ]] || [[ "$SHOULD_INSTALL" -eq 1 ]]; then
		return 1
	fi

	return 0
}

should_install() {
	local INDEX=$1
	local JSON_LIST=$2

	has "step" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return 1
	fi

	has_value "step" $INDEX "install" $JSON_LIST
	local SHOULD_INSTALL=$?

	if [[ "$SHOULD_INSTALL" -eq 1 ]]; then
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

  	new_line
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

	new_line
}

rebuild_okapi() {
	# Check if Okapi exists in modules.json and build default okapi repo
	SHOULD_REBUILD_OKAPI=$(jq '.[] | first(select(.id == "okapi")) | .id == "okapi" and .rebuild == "true"' $JSON_FILE)
	if [[ "$SHOULD_REBUILD_OKAPI" == "true" ]]; then
    	log "Rebuild Okapi ..."

    	build_okapi

    	new_line
	fi
}

stop_running_modules() {
	if [ $SHOULD_STOP_RUNNING_MODULES == "false" ]; then
		return
	fi

	log "Stop running modules ..."

	for ((j=$START_PORT; j<=$END_PORT; j++))
	do
        local PORT=$j

        is_port_used $PORT
        IS_PORT_USED=$?
        if [[ "$IS_PORT_USED" -eq 1 ]]; then
            kill_process_port $PORT
        fi
	done

  	new_line
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

		okapi_curl $OKAPI_URL/_/env -d"{\"name\":\"$ENV_VAR\",\"value\":\"$ENV_VALUE\"}" -o /dev/null
	done
}

stop_okapi() {
  	log "Stopping Okapi ..."

	kill_process_port $OKAPI_PORT
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

		curl -s -d"{\"name\":\"PORT\",\"value\":\"$PORT\"}" $OKAPI_URL/_/env -o /dev/null
		curl -s -d"{\"name\":\"SERVER_PORT\",\"value\":\"$SERVER_PORT\"}" $OKAPI_URL/_/env -o /dev/null
		curl -s -d"{\"name\":\"HTTP_PORT\",\"value\":\"$HTTP_PORT\"}" $OKAPI_URL/_/env -o /dev/null

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

	UUID=$(curl -s $OPTIONS $OKAPI_URL/users | jq ".users[] | select(.username == \"$USERNAME\") | .id")

	# Remove extra double quotes at start and end of the string
	UUID=$(echo $UUID | sed 's/"//g')

	POSTMAN_ENV_USER_ID_VAL=$UUID
}

get_random_permission_uuid_by_user_uuid() {
	local UUID=$1

	local OPTIONS="-HX-Okapi-Tenant:$TENANT"
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS="-HX-Okapi-Token:$OKAPI_HEADER_TOKEN"
	fi

	USER_PUUIDS=$(curl -s $OPTIONS $OKAPI_URL/perms/users | jq ".permissionUsers[] | select(.userId == \"$UUID\") | .id")
	
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

	okapi_curl $OKAPI_URL/bl-users/password-reset/link -d"{\"userId\":\"$UUID\"}" -o reset.json

	get_file_content reset.json

	# Check if the JSON data contains the string "requires permission".
	if grep -q "requires permission" <<< "$JSON_DATA"; then
		# NOTE: this request does not work for the first time, but it works fine the second time
		# the reason why is not clear but may be related to kafka not finished the task yet,
		# so I just try to wait using sleep command and it did work with me just fine.

		log "Access for user '$USERNAME' requires permission: users-bl.password-reset-link.generate"
		
		new_line
		
		log "Please wait until permissions added are persisted, which may delay due to underlying kafka process in users module so we will try again now."

		sleep 50

		reset_and_verify_password $UUID

		return
	fi
	unset JSON_DATA

	TOKEN_2=`jq -r '.link' < reset.json | sed -e 's/.*\/reset-password\/\([^?]*\).*/\1/g'`

	log "Second token: $TOKEN_2"

	curl -s -HX-Okapi-Token:$TOKEN_2 $OKAPI_URL/bl-users/password-reset/validate -d'{}'

	new_line
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
	new_line

	okapi_curl $OKAPI_URL/perms/users/$PUUID/permissions -d'{"permissionName":"users-bl.password-reset-link.generate"}'
	new_line

	login_admin
	new_line

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
	login_admin_curl $CLOUD_OKAPI_URL $CLOUD_TENANT $CLOUD_USERNAME $CLOUD_PASSWORD
	
	log "Install (Enable) $MODULE"
	
	curl --location "http://localhost:$SERVER_PORT/_/tenant" \
		--header "x-okapi-tenant: $CLOUD_TENANT" \
		--header "x-okapi-token: $TOKEN" \
		--header "x-okapi-url: $CLOUD_OKAPI_URL" \
		--header 'Content-Type: application/json' \
		--header "x-okapi-url-to: http://localhost:$SERVER_PORT" \
		--data "$ENABLE_PAYLOAD"

	new_line

	# Local Okapi login if we should for the consecutive modules
	should_login
	if [[ "$STATUS_CODE" == "200" ]] || [[ "$STATUS_CODE" == "204" ]]; then
		login_admin

		new_line
	fi
}

kill_process_port() {
	local PORT=$1

	kill -9 $(lsof -t -i:$PORT)
}


################################
# 		 END - HELPERS		   #
################################





################################
# 		 START - PREPARE	   #
################################

pre_process() {
	defaults

	set_args $*

	stop_running_modules

	run_okapi

	set_env_vars_to_okapi

	new_tenant

	validate_modules_list

	validate_configurations_list
}

# Default Variable values
defaults() {
	module_defaults
	
	db_defaults

	kafka_defaults

	okapi_defaults

	user_defaults
	
	postman_defaults
}

module_defaults() {
	# Modules directory path
	MODULES_DIR=modules
	
	go_to_modules_dir

	# Modules list file
	JSON_FILE="modules.json"

	# Configurations list file
	CONFIG_FILE="configuration.json"

	SHOULD_STOP_RUNNING_MODULES=$(jq ".SHOULD_STOP_RUNNING_MODULES" $CONFIG_FILE)

	# Remove extra double quotes at start and end of the string
	SHOULD_STOP_RUNNING_MODULES=$(echo $SHOULD_STOP_RUNNING_MODULES | sed 's/"//g')
}

db_defaults() {
	DB_HOST=$(jq ".DB_HOST" $CONFIG_FILE)
	DB_PORT=$(jq ".DB_PORT" $CONFIG_FILE)
	DB_DATABASE=$(jq ".DB_DATABASE" $CONFIG_FILE)
	DB_USERNAME=$(jq ".DB_USERNAME" $CONFIG_FILE)
	DB_PASSWORD=$(jq ".DB_PASSWORD" $CONFIG_FILE)
	DB_QUERYTIMEOUT=$(jq ".DB_QUERYTIMEOUT" $CONFIG_FILE)
	DB_MAXPOOLSIZE=$(jq ".DB_MAXPOOLSIZE" $CONFIG_FILE)
	
	# Remove extra double quotes at start and end of the string
	DB_HOST=$(echo $DB_HOST | sed 's/"//g')
	DB_PORT=$(echo $DB_PORT | sed 's/"//g')
	DB_DATABASE=$(echo $DB_DATABASE | sed 's/"//g')
	DB_USERNAME=$(echo $DB_USERNAME | sed 's/"//g')
	DB_PASSWORD=$(echo $DB_PASSWORD | sed 's/"//g')
	DB_QUERYTIMEOUT=$(echo $DB_QUERYTIMEOUT | sed 's/"//g')
	DB_MAXPOOLSIZE=$(echo $DB_MAXPOOLSIZE | sed 's/"//g')
}

kafka_defaults() {
	# DB env vars
	KAFKA_PORT=$(jq ".KAFKA_PORT" $CONFIG_FILE)
	KAFKA_HOST=$(jq ".KAFKA_HOST" $CONFIG_FILE)
	
	# Remove extra double quotes at start and end of the string
	KAFKA_PORT=$(echo $KAFKA_PORT | sed 's/"//g')
	KAFKA_HOST=$(echo $KAFKA_HOST | sed 's/"//g')
}

okapi_defaults() {
	# Default OKAPI Header with value which is used at setting curl request headers
	OKAPI_HEADER_TOKEN=x

	# Okapi Port
	OKAPI_PORT=9130

	# Start Port
	START_PORT=$((OKAPI_PORT + 1))

	# End Port
	END_PORT=9200

	# Server/Http Port
	PORT=$OKAPI_PORT
	SERVER_PORT=$OKAPI_PORT
	HTTP_PORT=$OKAPI_PORT

	# Okapi Url
	OKAPI_URL=http://localhost:$OKAPI_PORT

	# Okapi Directory
	OKAPI_DIR=okapi

	# Okapi repository
	OKAPI_REPO="git@github.com:folio-org/okapi.git"

	# Okapi Options
	OKAPI_DB_OPTIONS="-Dpostgres_host=$DB_HOST -Dpostgres_port=$DB_PORT -Dpostgres_database=$DB_DATABASE -Dpostgres_username=$DB_USERNAME -Dpostgres_password=$DB_PASSWORD"
	OKAPI_OPTIONS="-Denable_system_auth=false -Dport_end=$END_PORT -Dstorage=postgres -Dtrace_headers=true $OKAPI_DB_OPTIONS"

	# Okapi build command
	OKAPI_BUILD_COMMAND="mvn install -DskipTests $OKAPI_DB_OPTIONS"

	# Okapi Command
	OKAPI_COMMAND="java $OKAPI_OPTIONS -jar okapi-core/target/okapi-core-fat.jar dev"

	# Okapi Initialize Database Command
	OKAPI_INIT_COMMAND="java $OKAPI_OPTIONS -jar okapi-core/target/okapi-core-fat.jar initdatabase"

	# Okapi Purge Database tables Command
	OKAPI_PURGE_COMMAND="java $OKAPI_OPTIONS -jar okapi-core/target/okapi-core-fat.jar purgedatabase"

	# Elastic search url
	ELASTIC_SEARCH_URL=http://localhost:9200
}

user_defaults() {
	# Test Tenant
	TENANT=$(jq ".TENANT" $CONFIG_FILE)

	# Test User
	USERNAME=$(jq ".USERNAME" $CONFIG_FILE)
	PASSWORD=$(jq ".PASSWORD" $CONFIG_FILE)
	USER_ACTIVE=$(jq ".USER_ACTIVE" $CONFIG_FILE)
	USER_BARCODE=$(jq ".USER_BARCODE" $CONFIG_FILE)
	USER_PERSONAL_FIRSTNAME=$(jq ".USER_PERSONAL_FIRSTNAME" $CONFIG_FILE)
	USER_PERSONAL_LASTNAME=$(jq ".USER_PERSONAL_LASTNAME" $CONFIG_FILE)
	USER_PERSONAL_MIDDLENAME=$(jq ".USER_PERSONAL_MIDDLENAME" $CONFIG_FILE)
	USER_PERSONAL_PREFERRED_FIRST_NAME=$(jq ".USER_PERSONAL_PREFERRED_FIRST_NAME" $CONFIG_FILE)
	USER_PERSONAL_PHONE=$(jq ".USER_PERSONAL_PHONE" $CONFIG_FILE)
	USER_PERSONAL_MOBILE_PHONE=$(jq ".USER_PERSONAL_MOBILE_PHONE" $CONFIG_FILE)
	USER_PERSONAL_PREFERRED_CONTACT_TYPE_ID=$(jq ".USER_PERSONAL_PREFERRED_CONTACT_TYPE_ID" $CONFIG_FILE)
	USER_PERSONAL_EMAIL=$(jq ".USER_PERSONAL_EMAIL" $CONFIG_FILE)
	USER_PERSONAL_ADDRESSES_CITY=$(jq ".USER_PERSONAL_ADDRESSES_CITY" $CONFIG_FILE)
	USER_PERSONAL_ADDRESSES_COUNTRY_ID=$(jq ".USER_PERSONAL_ADDRESSES_COUNTRY_ID" $CONFIG_FILE)
	USER_PERSONAL_ADDRESSES_POSTAL_CODE=$(jq ".USER_PERSONAL_ADDRESSES_POSTAL_CODE" $CONFIG_FILE)
	USER_PERSONAL_ADDRESSES_ADDRESS_LINE_1=$(jq ".USER_PERSONAL_ADDRESSES_ADDRESS_LINE_1" $CONFIG_FILE)
	USER_PERSONAL_ADDRESSES_ADDRESS_TYPE_ID=$(jq ".USER_PERSONAL_ADDRESSES_ADDRESS_TYPE_ID" $CONFIG_FILE)
	USER_PROXY_FOR=$(jq ".USER_PROXY_FOR" $CONFIG_FILE)
	USER_DEPARTMENTS=$(jq ".USER_DEPARTMENTS" $CONFIG_FILE)
	USER_PATRON_GROUP=$(jq ".USER_PATRON_GROUP" $CONFIG_FILE)

	# Remove extra double quotes at start and end of the string
	TENANT=$(echo $TENANT | sed 's/"//g')
	USERNAME=$(echo $USERNAME | sed 's/"//g')
	PASSWORD=$(echo $PASSWORD | sed 's/"//g')
	USER_ACTIVE=$(echo $USER_ACTIVE | sed 's/"//g')
	USER_BARCODE=$(echo $USER_BARCODE | sed 's/"//g')
	USER_PERSONAL_FIRSTNAME=$(echo $USER_PERSONAL_FIRSTNAME | sed 's/"//g')
	USER_PERSONAL_LASTNAME=$(echo $USER_PERSONAL_LASTNAME | sed 's/"//g')
	USER_PERSONAL_MIDDLENAME=$(echo $USER_PERSONAL_MIDDLENAME | sed 's/"//g')
	USER_PERSONAL_PREFERRED_FIRST_NAME=$(echo $USER_PERSONAL_PREFERRED_FIRST_NAME | sed 's/"//g')
	USER_PERSONAL_PHONE=$(echo $USER_PERSONAL_PHONE | sed 's/"//g')
	USER_PERSONAL_MOBILE_PHONE=$(echo $USER_PERSONAL_MOBILE_PHONE | sed 's/"//g')
	USER_PERSONAL_PREFERRED_CONTACT_TYPE_ID=$(echo $USER_PERSONAL_PREFERRED_CONTACT_TYPE_ID | sed 's/"//g')
	USER_PERSONAL_EMAIL=$(echo $USER_PERSONAL_EMAIL | sed 's/"//g')
	USER_PERSONAL_ADDRESSES_CITY=$(echo $USER_PERSONAL_ADDRESSES_CITY | sed 's/"//g')
	USER_PERSONAL_ADDRESSES_COUNTRY_ID=$(echo $USER_PERSONAL_ADDRESSES_COUNTRY_ID | sed 's/"//g')
	USER_PERSONAL_ADDRESSES_POSTAL_CODE=$(echo $USER_PERSONAL_ADDRESSES_POSTAL_CODE | sed 's/"//g')
	USER_PERSONAL_ADDRESSES_ADDRESS_LINE_1=$(echo $USER_PERSONAL_ADDRESSES_ADDRESS_LINE_1 | sed 's/"//g')
	USER_PERSONAL_ADDRESSES_ADDRESS_TYPE_ID=$(echo $USER_PERSONAL_ADDRESSES_ADDRESS_TYPE_ID | sed 's/"//g')
	USER_PROXY_FOR=$(echo $USER_PROXY_FOR | sed 's/"//g')
	USER_DEPARTMENTS=$(echo $USER_DEPARTMENTS | sed 's/"//g')
	USER_PATRON_GROUP=$(echo $USER_PATRON_GROUP | sed 's/"//g')
	
}

postman_defaults() {
	POSTMAN_API_KEY=$(jq ".POSTMAN_API_KEY" $CONFIG_FILE)
	POSTMAN_URL=$(jq ".POSTMAN_URL" $CONFIG_FILE)
	POSTMAN_IMPORT_OPENAPI_PATH=$(jq ".POSTMAN_IMPORT_OPENAPI_PATH" $CONFIG_FILE)
	POSTMAN_ENVIRONMENT_PATH=$(jq ".POSTMAN_ENVIRONMENT_PATH" $CONFIG_FILE)
	POSTMAN_ENV_LOCAL_WITH_OKAPI_UUID=$(jq ".POSTMAN_ENV_LOCAL_WITH_OKAPI_UUID" $CONFIG_FILE)

	# Environment variable's values
	POSTMAN_ENV_NAME="Local with okapi"
	POSTMAN_ENV_OKAPI_URL_VAL=$OKAPI_URL
	POSTMAN_ENV_MOD_URL_VAL="http://localhost:9135"
	POSTMAN_ENV_TENANT_VAL=$TENANT
	POSTMAN_ENV_TOKEN_VAL=""
	POSTMAN_ENV_USER_ID_VAL=""

	# Remove extra double quotes at start and end of the string
	POSTMAN_API_KEY=$(echo $POSTMAN_API_KEY | sed 's/"//g')
	POSTMAN_URL=$(echo $POSTMAN_URL | sed 's/"//g')
	POSTMAN_IMPORT_OPENAPI_PATH=$(echo $POSTMAN_IMPORT_OPENAPI_PATH | sed 's/"//g')
	POSTMAN_ENVIRONMENT_PATH=$(echo $POSTMAN_ENVIRONMENT_PATH | sed 's/"//g')
	POSTMAN_ENV_LOCAL_WITH_OKAPI_UUID=$(echo $POSTMAN_ENV_LOCAL_WITH_OKAPI_UUID | sed 's/"//g')
}

set_args() {
	ARGS=$*
	for ARG in $ARGS; do
		set_init_arg $ARG
		set_purge_arg $ARG
		set_restart_okapi_arg $ARG
		set_without_okapi_arg $ARG
	done
}

set_init_arg() {
	local ARGUMENT=$1

	if [[ "$INIT_ARG" -eq 1 ]]; then
		return
	fi

	INIT_ARG=0
	if [ $ARGUMENT == "init" ]; then
		INIT_ARG=1
	fi
}

set_purge_arg() {
	local ARGUMENT=$1

	if [[ "$PURGE_ARG" -eq 1 ]]; then
		return
	fi

	PURGE_ARG=0
	if [ $ARGUMENT == "purge" ]; then
		PURGE_ARG=1
	fi
}

set_restart_okapi_arg() {
	local ARGUMENT=$1

	if [[ "$RESTART_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	RESTART_OKAPI_ARG=0
	if [ $ARGUMENT == "restart" ]; then
		RESTART_OKAPI_ARG=1
	fi
}

set_without_okapi_arg() {
	local ARGUMENT=$1

	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	WITHOUT_OKAPI_ARG=0
	if [ $ARGUMENT == "without-okapi" ]; then
		WITHOUT_OKAPI_ARG=1
	fi
}

go_to_modules_dir() {
	cd "$MODULES_DIR"
}

run_okapi() {
	# Do not run Okapi if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	# Do nothing if Okapi is already running without setting restart argument
	is_okapi_running
	IS_OKAPI_RUNNING=$?
	if [[ "$IS_OKAPI_RUNNING" -eq 1 ]] && [[ "$RESTART_OKAPI_ARG" -eq 0 ]]; then
		return
	fi

  	log "Running Okapi ..."

	# If Okapi is missing in the modules directory then clone and compile
	is_okapi_exists
	IS_OKAPI_EXISTS=$?
	if [[ "$IS_OKAPI_EXISTS" -eq 0 ]]; then
		clone_okapi && build_okapi
	fi

	# Rebuild Okapi if enabled in the modules.json
	if [[ "$IS_OKAPI_EXISTS" -eq 1 ]]; then
		rebuild_okapi $INDEX $JSON_LIST
	fi

	# Restart Okapi by stopping it first and then start it again
	if [[ "$IS_OKAPI_RUNNING" -eq 1 ]] && [[ "$RESTART_OKAPI_ARG" -eq 1 ]]; then
		stop_okapi
	fi

	# Init Okapi
	if [[ "$INIT_ARG" -eq 1 ]]; then
	    log "Init Okapi ..."

		eval "cd $OKAPI_DIR && nohup $OKAPI_INIT_COMMAND &"
	fi

	# Purge Okapi
	if [[ "$PURGE_ARG" -eq 1 ]]; then
	    log "Purge Okapi ..."

		eval "cd $OKAPI_DIR && nohup $OKAPI_PURGE_COMMAND &"
	fi

	# Run Okapi
	log "Start Okapi ..."
	eval "cd $OKAPI_DIR && nohup $OKAPI_COMMAND &"

	# wait untill okapi is fully up and running
	sleep 5
}

# Set Environment Variables to Okapi
set_env_vars_to_okapi() {
	# Do not set Okapi env variables if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	log "Set environment variables to okapi"

	new_line

	curl -s -d"{\"name\":\"DB_HOST\",\"value\":\"$DB_HOST\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"DB_PORT\",\"value\":\"$DB_PORT\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"DB_USERNAME\",\"value\":\"$DB_USERNAME\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"DB_PASSWORD\",\"value\":\"$DB_PASSWORD\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"DB_DATABASE\",\"value\":\"$DB_DATABASE\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"SPRING_DATASOURCE_URL\",\"value\":\"jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_DATABASE?reWriteBatchedInserts=true\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"SPRING_DATASOURCE_USERNAME\",\"value\":\"$DB_USERNAME\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"SPRING_DATASOURCE_PASSWORD\",\"value\":\"$DB_PASSWORD\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"OKAPI_URL\",\"value\":\"$OKAPI_URL\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"KAFKA_PORT\",\"value\":\"$KAFKA_PORT\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"KAFKA_HOST\",\"value\":\"$KAFKA_HOST\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"PORT\",\"value\":\"$PORT\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"SERVER_PORT\",\"value\":\"$SERVER_PORT\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"HTTP_PORT\",\"value\":\"$HTTP_PORT\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"ELASTICSEARCH_URL\",\"value\":\"$ELASTIC_SEARCH_URL\"}" $OKAPI_URL/_/env -o /dev/null

	new_line
}

# Store new tenant
new_tenant() {
	# Do not call for adding new tenant if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	log "Add new tenant: $TENANT"
	new_line
	
	has_tenant $TENANT
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	curl -d"{\"id\":\"$TENANT\", \"name\":\"Test Library #1\", \"description\":\"Test Libarary Number One\"}" $OKAPI_URL/_/proxy/tenants

	new_line
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

	log "Add New User with username: $USERNAME"

	PAYLOAD="{\"username\":\"$USERNAME\", \"id\":\"$UUID\", \"active\":true, \"scopes\": [], \"barcode\": \"123456789\", \"personal\": {\"email\": \"ahmed@email.com\", \"phone\": \"010111111111\", \"imageUrl\": \"\", \"lastName\": \"Zaky\", \"addresses\": [{\"city\": \"\", \"countryId\": \"EG\", \"postalCode\": \"11111\", \"addressLine1\": \"\", \"addressTypeId\": \"93d3d88d-499b-45d0-9bc7-ac73c3a19880\"}], \"firstName\": \"Ahmed\", \"middleName\": \"Mohamed\", \"mobilePhone\": \"010111111111\", \"preferredFirstName\": \"Ahmed\", \"preferredContactTypeId\": \"002\"}, \"proxyFor\": [], \"username\": \"ui_admin\", \"departments\": [], \"patronGroup\": \"503a81cd-6c26-400f-b620-14c08943697c\"}"

	local OPTIONS="-HX-Okapi-Tenant:$TENANT -HContent-Type:application/json"
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS="$OPTIONS -HX-Okapi-Token:$OKAPI_HEADER_TOKEN"
	fi

	curl -s --location -XPOST $OKAPI_URL/users $OPTIONS \
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
		"patronGroup": "'$USER_PATRON_GROUP'"
	}'

	new_line
}

delete_user() {
	local USERNAME=$1

	okapi_curl -XDELETE "$OKAPI_URL/users?query=username%3D%3D$USERNAME"
	new_line
}

# Enable okapi module to tenant
enable_okapi() {
	local INDEX=$1
	local JSON_LIST=$2

	install_module enable okapi $INDEX $JSON_LIST
}


################################
# 		 END - PREPARE		   #
################################






################################
# 		START - VALIDATION	   #
################################


validate_modules_list() {
	if [ ! -z "$1" ]; then
		JSON_FILE=$1
	fi  

	if [ ! -f "$JSON_FILE" ]; then
		error "JSON LIST is missing"
	fi
}

validate_configurations_list() {
	if [ ! -z "$1" ]; then
		CONFIG_FILE=$1
	fi  

	if [ ! -f "$CONFIG_FILE" ]; then
		error "Configuration list is missing"
	fi
}

validate_module_id() {
	local INDEX=$1
	local JSON_LIST=$2

	has "id" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		error "Id property is missing"
	fi

	MODULE_ID=$(jq ".[$INDEX].id" $JSON_LIST)
	
	# Remove extra double quotes at start and end of the string
	MODULE_ID=$(echo $MODULE_ID | sed 's/"//g')
}

validate_module_repo() {
	local MODULE_ID=$1
	local INDEX=$2
	local JSON_LIST=$3

	# Default repo url (FOLIO ORG)
	REPO="git clone --recurse-submodules git@github.com:folio-org/$MODULE_ID"

	# Custom Repo url
	has "repo" $INDEX $JSON_LIST
	if [[ "$?" -eq 1 ]]; then
		local REPO_URL=$(jq ".[$INDEX].repo" $JSON_LIST)
		
		# Remove extra double quotes at start and end of the string
		REPO_URL=$(echo $REPO_URL | sed 's/"//g')
	
		REPO="git clone --recurse-submodules $REPO_URL"
	fi
}

validate_module_tag_branch() {
	local INDEX=$1
	local JSON_LIST=$2

	has "branch" $INDEX $JSON_LIST
	local HAS_BRANCH=$?

	has "tag" $INDEX $JSON_LIST
	local HAS_TAG=$?

	if [[ "$HAS_TAG" -eq 1 ]] && [[ "$HAS_BRANCH" -eq 1 ]]; then
		error "Either one of both tag, or branch should be provided"
	fi

	if [[ "$HAS_TAG" -eq 1 ]] && [[ "$HAS_BRANCH" -eq 0 ]]; then
		local TAG=$(jq ".[$INDEX].tag" $JSON_LIST)
		
		# Remove extra double quotes at start and end of the string
		TAG=$(echo $TAG | sed 's/"//g')
		
		REPO=$(echo "$REPO" | sed "s/^git clone/git clone -b $TAG/g")
	fi
	
	if [[ "$HAS_BRANCH" -eq 1 ]] && [[ "$HAS_TAG" -eq 0 ]]; then
		local BRANCH=$(jq ".[$INDEX].branch" $JSON_LIST)
		
		# Remove extra double quotes at start and end of the string
		BRANCH=$(echo $BRANCH | sed 's/"//g')
		
		REPO=$(echo "$REPO" | sed "s/^git clone/git clone -b $BRANCH/g")
	fi
}

validate_module_access_token() {
	local INDEX=$1
	local JSON_LIST=$2

	has "access_token" $INDEX $JSON_LIST
	local HAS_ACCESS_TOKEN=$?
	if [[ "$HAS_ACCESS_TOKEN" -eq 1 ]]; then
		local ACCESS_TOKEN=$(jq ".[$INDEX].access_token" $JSON_LIST)

		# Remove extra double quotes at start and end of the string
		ACCESS_TOKEN=$(echo $ACCESS_TOKEN | sed 's/"//g')
		
		B64_ACCESS_TOKEN=$(printf ":%s" "$ACCESS_TOKEN" | base64)
		REPO=$(echo "$REPO" | sed "s/^git/git -c http.extraHeader=\"Authorization: Basic ${B64_ACCESS_TOKEN}\"/g")
	fi
}

validate_open_api_file() {
	local INDEX=$1
	local JSON_LIST=$2
	local MODULE=$3

	has "file" $INDEX $JSON_LIST "postman"
	if [[ "$?" -eq 0 ]]; then
		error "Postman Open API File is missing" 
	fi

	OPEN_API_FILE=$(jq ".[$INDEX].postman.file" $JSON_LIST)
	
	# Remove extra double quotes at start and end of the string
	OPEN_API_FILE=$(echo $OPEN_API_FILE | sed 's/"//g')

	# Validate Open API file exists
	if [ ! -f "$MODULE/$OPEN_API_FILE" ]; then
		error "Open API file is missing"
	fi
}

validate_postman_api_key() {
	local INDEX=$1
	local JSON_LIST=$2

	has "api_key" $INDEX $JSON_LIST "postman"
	if [[ "$?" -eq 0 ]]; then
		error "Postman API Key is missing" 
	fi

	POSTMAN_API_KEY=$(jq ".[$INDEX].postman.api_key" $JSON_LIST)

	# Remove extra double quotes at start and end of the string
	POSTMAN_API_KEY=$(echo $POSTMAN_API_KEY | sed 's/"//g')
}

validate_okapi_url() {
	local INDEX=$1
	local JSON_LIST=$2

	has "url" $INDEX $JSON_LIST "okapi"
	if [[ "$?" -eq 0 ]]; then
		error "Okapi Url Key is missing" 
	fi

	CLOUD_OKAPI_URL=$(jq ".[$INDEX].okapi.url" $JSON_LIST)

	# Remove extra double quotes at start and end of the string
	CLOUD_OKAPI_URL=$(echo $CLOUD_OKAPI_URL | sed 's/"//g')
}

validate_okapi_tenant() {
	local INDEX=$1
	local JSON_LIST=$2

	has "tenant" $INDEX $JSON_LIST "okapi"
	if [[ "$?" -eq 0 ]]; then
		error "Okapi Tenant Key is missing" 
	fi

	SERVER_TENANT=$(jq ".[$INDEX].okapi.tenant" $JSON_LIST)

	# Remove extra double quotes at start and end of the string
	SERVER_TENANT=$(echo $SERVER_TENANT | sed 's/"//g')
}

validate_okapi_credentials() {
	local INDEX=$1
	local JSON_LIST=$2

	has "username" $INDEX $JSON_LIST "okapi.credentials"
	if [[ "$?" -eq 0 ]]; then
		error "Okapi credentials username key is missing" 
	fi

	has "password" $INDEX $JSON_LIST "okapi.credentials"
	if [[ "$?" -eq 0 ]]; then
		error "Okapi credentials password key is missing" 
	fi

	SERVER_USERNAME=$(jq ".[$INDEX].okapi.credentials.username" $JSON_LIST)
	SERVER_PASSWORD=$(jq ".[$INDEX].okapi.credentials.password" $JSON_LIST)

	# Remove extra double quotes at start and end of the string
	SERVER_USERNAME=$(echo $SERVER_USERNAME | sed 's/"//g')
	SERVER_PASSWORD=$(echo $SERVER_PASSWORD | sed 's/"//g')
}


################################
# 		END - VALIDATION	   #
################################





####################################################################################
#   START - Clone, Build (Compile), Register (Declare), Deploy, Install (Enable)   #
####################################################################################

# Clone module
clone_module() {
	local INDEX=$1
	local JSON_LIST=$2

	should_clone $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi
	
	# Clone the module repo
	if [ ! -d $MODULE_ID ]; then
		log "Clone module $MODULE_ID"
		
		# Print Repo Link
		new_line
		log $REPO
		new_line

		eval "$REPO"
	fi

	if [[ ! -d "$MODULE_ID" ]]; then
		error "$MODULE_ID is missing. git clone failed?"
	fi
}

# Build (compile) module
build_module() {
	local MODULE_ID=$1
	local INDEX=$2
	local JSON_LIST=$3

	should_build $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	should_rebuild $INDEX $JSON_LIST
	SHOULD_REBUILD=$?
	local MODULE_DESCRIPTOR=$MODULE_ID/target/ModuleDescriptor.json
	if [[ -f $MODULE_DESCRIPTOR ]] && [[ "$SHOULD_REBUILD" -eq 0 ]]; then
		return
	fi

	# Opt in the module
	cd $MODULE_ID

	# Default Build command
	BUILD="mvn -DskipTests -Dmaven.test.skip=true verify"

	# Custom Build command
	has "build" $INDEX ../$JSON_LIST
	if [[ "$?" -eq 1 ]]; then
		local BUILD=$(jq ".[$INDEX].build" ../$JSON_LIST)
		
		# Remove extra double quotes at start and end of the string
		BUILD=$(echo $BUILD | sed 's/"//g')	
	fi

	log "Build module $MODULE_ID"

	# build
	eval "$BUILD"

	# Opt out from the module
	cd ..
}

# Register (store) module into Okapi
register_module() {
	local MODULE_ID=$1
	local INDEX=$2
	local JSON_LIST=$3
	local MODULE_DESCRIPTOR=$MODULE_ID/target/ModuleDescriptor.json

	should_register $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi
	
	# Do not use local okapi instance instead use already running okapi instance on the cloud
	if [ -n "$CLOUD_OKAPI_URL" ]; then
		return
	fi

	# Do not run modules that depend on local Okapi instance if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	has_registered $MODULE_ID
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	# Validate module descriptor file
	if [[ ! -f $MODULE_DESCRIPTOR ]]; then
		error "$MODULE_DESCRIPTOR missing pwd=`pwd`"
	fi

	log "Register module $MODULE_ID"

	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	curl -s $OPTIONS -d@$MODULE_DESCRIPTOR $OKAPI_URL/_/proxy/modules -o /dev/null

	new_line
}

# Deploy module into Okapi
deploy_module() {
	local MODULE_ID=$1
	local INDEX=$2
	local JSON_LIST=$3
	local DEPLOY_DESCRIPTOR=$MODULE_ID/target/DeploymentDescriptor.json

	should_deploy $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# Do not use local okapi instance instead use already running okapi instance on the cloud
	has "okapi" $INDEX $JSON_LIST
	FOUND=$?
	if [[ -n "$CLOUD_OKAPI_URL" ]] && [[ "$FOUND" -eq 1 ]]; then
		deploy_module_directly $MODULE_ID $INDEX $JSON_LIST

		return
	fi

	# Do not run modules that depend on local Okapi instance if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	has_deployed $MODULE_ID
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	export_next_port $SERVER_PORT

	log "Deploy module $MODULE_ID on port: $SERVER_PORT"

	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	curl -s $OPTIONS -d@$DEPLOY_DESCRIPTOR $OKAPI_URL/_/deployment/modules -o /dev/null

	new_line
}

# Install (enable) modules for a tenant
install_module() {
	local ACTION=$1
	local MODULE=$2
	local INDEX=$3
	local JSON_LIST=$4
	
	should_install $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# Do not use local okapi instance instead use already running okapi instance on the cloud
	has "okapi" $INDEX $JSON_LIST
	FOUND=$?
	if [[ -n "$CLOUD_OKAPI_URL" ]] && [[ "$FOUND" -eq 1 ]]; then
		enable_module_directly $MODULE_ID $INDEX $JSON_LIST
		unset CLOUD_OKAPI_URL

		return
	fi

	# Do not run modules that depend on local Okapi instance Okapi if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	# Build Body Json list of modules with action enable comes as argument
	has_installed $MODULE $TENANT
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	local PAYLOAD="[{\"action\":\"$ACTION\",\"id\":\"$MODULE\"}]"

	# Set Okapi Token if set
	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	# Validate if the list is not empty	
	if [[ "$PAYLOAD" =~ ^\[.+\]$ ]]; then
		log "Install (Enable) $MODULE"
		
		get_install_params $MODULE $i $JSON_LIST

		# Install (enable) modules
		curl -s $OPTIONS "-d$PAYLOAD" "$OKAPI_URL/_/proxy/tenants/$TENANT/install?$INSTALL_PARAMS" -o /dev/null

		new_line
	fi
}

# Clone, Build (compile), Register (declare), Deploy, Install (enable) modules one by one
process() {
	local LENGTH=$(jq '. | length' $JSON_FILE)

	for ((i=0; i<$LENGTH; i++))
	do
		# Skip okapi module if exists
		has_value "id" $i "okapi" $JSON_FILE
		FOUND=$?
		if [[ "$FOUND" -eq 1 ]]; then
			continue
		fi

		# Skip disabled modules
		is_enabled $i $JSON_FILE
		IS_ENALBLED=$?
		if [[ "$IS_ENALBLED" -eq 0 ]]; then
			continue
		fi

		# Step No. 1
		pre_clone $i $JSON_FILE		
		clone_module $i $JSON_FILE		
		
		# Step No. 2
		build_module $MODULE_ID $i $JSON_FILE

		# Step No. 3
		pre_register $MODULE_ID $i $JSON_FILE
		register_module $MODULE_ID $i $JSON_FILE

		# Step No. 4
		deploy_module $MODULE_ID $i $JSON_FILE

		# Step No. 5
		install_module enable $MODULE_ID $i $JSON_FILE
		post_install $MODULE_ID $i $JSON_FILE
	done
}

###################################################################################
#    END - Clone, Build (Compile), Register (Declare), Deploy, Install (Enable)   #
###################################################################################







#####################################
# 			 START - RUN			#
#####################################


pre_process $*

process


#####################################
# 			  END - RUN 			#
#####################################
