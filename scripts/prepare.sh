#!/bin/bash

####################################################
# 		START - VALIDATE PREVIOUS SCRIPTS		   #
####################################################

if [ ! -f scripts/helpers.sh ]; then
	echo -e "["$(date +"%A, %b %d, %Y %I:%M:%S %p")"] \n\e[1;31m ERROR: Helpers script file is missing \033[0m"
	
    exit 1
fi

################################################
# 		END - VALIDATE PREVIOUS SCRIPTS		   #
################################################


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

	has_tenant $TENANT
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	log "Add new tenant: $TENANT"
	new_line

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
