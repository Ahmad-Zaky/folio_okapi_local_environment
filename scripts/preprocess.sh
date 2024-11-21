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
	local ARGS=$*

	defaults

	set_args $ARGS
	
	validate_linux_tools $TOOLS_LIST
	
	handle_db_operations $ARGS

	empty_logs

	stop_running_module_or_modules

	free_from_start_to_end_ports

	# we need to run okapi first because we cannot fetch mod-authtoken and mod-permissions module version unless okapi is up and running
	run_okapi

	# we remove them before running okapi as okapi cache the enabled modules list so any db change will not affect the cached list
	remove_authtoken_and_permissions_if_enabled_previously

	rerun_okapi

	set_env_vars_to_okapi

	new_tenant

	validate_modules_list

	validate_configurations_list
}

# Default Variable values
defaults() {
	general_defaults

	module_defaults

	db_defaults

	kafka_defaults

	okapi_defaults

	docker_defaults

	user_defaults
	
	postman_defaults
}

general_defaults() {
	export HOME_PATH=`echo ~`
	export BASHRC_PATH="$HOME_PATH/.bashrc"
	export BASH_ALIASES_PATH="$HOME_PATH/.bash_aliases"
	export ALIASES_PATH="../scripts/aliases.txt"
	export TOOLS_LIST="git java jq yq xmllint lsof docker netstat"
}

module_defaults() {
	# Modules directory path
	export MODULES_DIR=modules
	export JSON_FILE="modules.json"
	export FILTERED_JSON_FILE="filtered_modules.json"
	export CONFIG_FILE="configuration.json"
	export LOGIN_WITH_MOD="mod-authtoken"
	export PERMISSIONS_MODULE="mod-permissions"
	export AUTHTOKEN_MODULE="mod-authtoken"
	export USERS_MODULE="mod-users"
	export USERS_BL_MODULE="mod-users-bl"
	export OUTPUT_FILE="output.txt"
	export RESPONSE_FILE="response.txt"
	export HAS_PERMISSIONS_MODULE=false
	export HAS_USERS_MODULE=false
	export HAS_USERS_BL_MODULE=false
	export VERSION_FROM="pom" # for now we will keep it like this ...

	go_to_modules_dir

	SHOULD_STOP_RUNNING_MODULES=$(jq ".SHOULD_STOP_RUNNING_MODULES" $CONFIG_FILE)
	EMPTY_REQUIRES_ARRAY_IN_MODULE_DESCRIPTOR=$(jq ".EMPTY_REQUIRES_ARRAY_IN_MODULE_DESCRIPTOR" $CONFIG_FILE)
	REMOVE_AUTHTOKEN_IF_ENABLED_PREVIOUSLY=$(jq ".REMOVE_AUTHTOKEN_IF_ENABLED_PREVIOUSLY" $CONFIG_FILE)

	# Remove extra double quotes at start and end of the string
	export SHOULD_STOP_RUNNING_MODULES=$(echo $SHOULD_STOP_RUNNING_MODULES | sed 's/"//g')
	export EMPTY_REQUIRES_ARRAY_IN_MODULE_DESCRIPTOR=$(echo $EMPTY_REQUIRES_ARRAY_IN_MODULE_DESCRIPTOR | sed 's/"//g')
	export REMOVE_AUTHTOKEN_IF_ENABLED_PREVIOUSLY=$(echo $REMOVE_AUTHTOKEN_IF_ENABLED_PREVIOUSLY | sed 's/"//g')	
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
	export DB_HOST=$(echo $DB_HOST | sed 's/"//g')
	export DB_PORT=$(echo $DB_PORT | sed 's/"//g')
	export DB_DATABASE=$(echo $DB_DATABASE | sed 's/"//g')
	export DB_USERNAME=$(echo $DB_USERNAME | sed 's/"//g')
	export DB_PASSWORD=$(echo $DB_PASSWORD | sed 's/"//g')
	export DB_QUERYTIMEOUT=$(echo $DB_QUERYTIMEOUT | sed 's/"//g')
	export DB_MAXPOOLSIZE=$(echo $DB_MAXPOOLSIZE | sed 's/"//g')
}

kafka_defaults() {
	# DB env vars
	KAFKA_PORT=$(jq ".KAFKA_PORT" $CONFIG_FILE)
	KAFKA_HOST=$(jq ".KAFKA_HOST" $CONFIG_FILE)
	
	# Remove extra double quotes at start and end of the string
	export KAFKA_PORT=$(echo $KAFKA_PORT | sed 's/"//g')
	export KAFKA_HOST=$(echo $KAFKA_HOST | sed 's/"//g')
}

okapi_defaults() {
	ENABLE_SYSTEM_AUTH_FOR_OKAPI=$(jq ".ENABLE_SYSTEM_AUTH_FOR_OKAPI" $CONFIG_FILE)
	OKAPI_STORAGE=$(jq ".OKAPI_STORAGE" $CONFIG_FILE)
	OKAPI_TRACE_HEADERS=$(jq ".OKAPI_TRACE_HEADERS" $CONFIG_FILE)
	OKAPI_OPTION_ENABLE_SYSTEM_AUTH=$(jq ".OKAPI_OPTION_ENABLE_SYSTEM_AUTH" $CONFIG_FILE)
	OKAPI_OPTION_ENABLE_VERTX_METRICS=$(jq ".OKAPI_OPTION_ENABLE_VERTX_METRICS" $CONFIG_FILE)
	OKAPI_OPTION_STORAGE=$(jq ".OKAPI_OPTION_STORAGE" $CONFIG_FILE)
	OKAPI_OPTION_TRACE_HEADERS=$(jq ".OKAPI_OPTION_TRACE_HEADERS" $CONFIG_FILE)
	OKAPI_OPTION_LOG_LEVEL=$(jq ".OKAPI_OPTION_LOG_LEVEL" $CONFIG_FILE)
	OKAPI_ARG_DEV=$(jq ".OKAPI_ARG_DEV" $CONFIG_FILE)
	OKAPI_ARG_INIT=$(jq ".OKAPI_ARG_INIT" $CONFIG_FILE)
	OKAPI_ARG_PURGE=$(jq ".OKAPI_ARG_PURGE" $CONFIG_FILE)
	OKAPI_PORT=$(jq ".OKAPI_PORT" $CONFIG_FILE)
	OKAPI_HOST=$(jq ".OKAPI_HOST" $CONFIG_FILE)
	OKAPI_DOCKER_CONTAINER_NAME=$(jq ".OKAPI_DOCKER_CONTAINER_NAME" $CONFIG_FILE)
	OKAPI_DOCKER_IMAGE_TAG=$(jq ".OKAPI_DOCKER_IMAGE_TAG" $CONFIG_FILE)
	OKAPI_CORE_DIR=$(jq ".OKAPI_CORE_DIR" $CONFIG_FILE)
	RETURN_FROM_OKAPI_CORE_DIR=$(jq ".RETURN_FROM_OKAPI_CORE_DIR" $CONFIG_FILE)
	END_PORT=$(jq ".END_PORT" $CONFIG_FILE)

	# Remove extra double quotes at start and end of the string
	export OKAPI_OPTION_ENABLE_SYSTEM_AUTH=$(echo $OKAPI_OPTION_ENABLE_SYSTEM_AUTH | sed 's/"//g')
	export OKAPI_OPTION_ENABLE_VERTX_METRICS=$(echo $OKAPI_OPTION_ENABLE_VERTX_METRICS | sed 's/"//g')
	export OKAPI_OPTION_STORAGE=$(echo $OKAPI_OPTION_STORAGE | sed 's/"//g')
	export OKAPI_OPTION_TRACE_HEADERS=$(echo $OKAPI_OPTION_TRACE_HEADERS | sed 's/"//g')
	export OKAPI_OPTION_LOG_LEVEL=$(echo $OKAPI_OPTION_LOG_LEVEL | sed 's/"//g')
	export OKAPI_ARG_DEV=$(echo $OKAPI_ARG_DEV | sed 's/"//g')
	export OKAPI_ARG_INIT=$(echo $OKAPI_ARG_INIT | sed 's/"//g')
	export OKAPI_ARG_PURGE=$(echo $OKAPI_ARG_PURGE | sed 's/"//g')
	export OKAPI_PORT=$(echo $OKAPI_PORT | sed 's/"//g')
	export OKAPI_HOST=$(echo $OKAPI_HOST | sed 's/"//g')
	export OKAPI_URL=http://$OKAPI_HOST:$OKAPI_PORT
	export OKAPI_DOCKER_CONTAINER_NAME=$(echo $OKAPI_DOCKER_CONTAINER_NAME | sed 's/"//g')
	export OKAPI_DOCKER_IMAGE_TAG=$(echo $OKAPI_DOCKER_IMAGE_TAG | sed 's/"//g')
	export OKAPI_CORE_DIR=$(echo $OKAPI_CORE_DIR | sed 's/"//g')
	export RETURN_FROM_OKAPI_CORE_DIR=$(echo $RETURN_FROM_OKAPI_CORE_DIR | sed 's/"//g')
	export END_PORT=$(echo $END_PORT | sed 's/"//g')

	export OKAPI_HEADER_TOKEN=x # Default OKAPI Header value instead of the real token.
	export PORT=$OKAPI_PORT
	export SERVER_PORT=$OKAPI_PORT
	export HTTP_PORT=$OKAPI_PORT

	export OKAPI_DIR=okapi
	export OKAPI_NOHUP_FILE="okapi/nohub.out"
	export OKAPI_REPO="git@github.com:folio-org/okapi.git"
	export OKAPI_DB_OPTIONS="-Dpostgres_host=$DB_HOST -Dpostgres_port=$DB_PORT -Dpostgres_database=$DB_DATABASE -Dpostgres_username=$DB_USERNAME -Dpostgres_password=$DB_PASSWORD"
	export OKAPI_OPTIONS="-Dloglevel=$OKAPI_OPTION_LOG_LEVEL -Denable_system_auth=$OKAPI_OPTION_ENABLE_SYSTEM_AUTH -Dvertx.metrics.options.enabled=$OKAPI_OPTION_ENABLE_VERTX_METRICS -Dport_end=$END_PORT -Dstorage=$OKAPI_OPTION_STORAGE -Dtrace_headers=$OKAPI_OPTION_TRACE_HEADERS $OKAPI_DB_OPTIONS"
	export OKAPI_BUILD_COMMAND="mvn install -DskipTests $OKAPI_DB_OPTIONS"
	export OKAPI_COMMAND="java $OKAPI_OPTIONS -jar okapi-core/target/okapi-core-fat.jar $OKAPI_ARG_DEV"
	export OKAPI_INIT_COMMAND="java $OKAPI_OPTIONS -jar okapi-core/target/okapi-core-fat.jar $OKAPI_ARG_INIT"
	export OKAPI_PURGE_COMMAND="java $OKAPI_OPTIONS -jar okapi-core/target/okapi-core-fat.jar $OKAPI_ARG_PURGE"
	export DOCKER_OKAPI_URL=http://$OKAPI_DOCKER_IMAGE_TAG:$OKAPI_PORT
	export OKAPI_JAVA_OPTIONS="$OKAPI_OPTIONS -Dokapiurl=$DOCKER_OKAPI_URL"

	ELASTICSEARCH_URL=$(jq ".ELASTICSEARCH_URL" $CONFIG_FILE)
	ELASTICSEARCH_HOST=$(jq ".ELASTICSEARCH_HOST" $CONFIG_FILE)
	ELASTICSEARCH_PORT=$(jq ".ELASTICSEARCH_PORT" $CONFIG_FILE)
	ELASTICSEARCH_USERNAME=$(jq ".ELASTICSEARCH_USERNAME" $CONFIG_FILE)
	ELASTICSEARCH_PASSWORD=$(jq ".ELASTICSEARCH_PASSWORD" $CONFIG_FILE)

	# Remove extra double quotes at start and end of the string
	export ELASTICSEARCH_URL=$(echo $ELASTICSEARCH_URL | sed 's/"//g')
	export ELASTICSEARCH_HOST=$(echo $ELASTICSEARCH_HOST | sed 's/"//g')
	export ELASTICSEARCH_PORT=$(echo $ELASTICSEARCH_PORT | sed 's/"//g')
	export ELASTICSEARCH_USERNAME=$(echo $ELASTICSEARCH_USERNAME | sed 's/"//g')
	export ELASTICSEARCH_PASSWORD=$(echo $ELASTICSEARCH_PASSWORD | sed 's/"//g')

	export OKAPI_ENV_VARS="[
		{\"name\":\"DB_HOST\",\"value\":\"$DB_HOST\"},
		{\"name\":\"DB_PORT\",\"value\":\"$DB_PORT\"},
		{\"name\":\"DB_USERNAME\",\"value\":\"$DB_USERNAME\"},
		{\"name\":\"DB_PASSWORD\",\"value\":\"$DB_PASSWORD\"},
		{\"name\":\"DB_DATABASE\",\"value\":\"$DB_DATABASE\"},
		{\"name\":\"SPRING_DATASOURCE_URL\",\"value\":\"jdbc:postgresql://$DB_HOST:$DB_PORT/$DB_DATABASE?reWriteBatchedInserts=true\"},
		{\"name\":\"SPRING_DATASOURCE_USERNAME\",\"value\":\"$DB_USERNAME\"},
		{\"name\":\"SPRING_DATASOURCE_PASSWORD\",\"value\":\"$DB_PASSWORD\"},
		{\"name\":\"OKAPI_URL\",\"value\":\"$OKAPI_URL\"},
		{\"name\":\"KAFKA_PORT\",\"value\":\"$KAFKA_PORT\"},
		{\"name\":\"KAFKA_HOST\",\"value\":\"$KAFKA_HOST\"},
		{\"name\":\"PORT\",\"value\":\"$PORT\"},
		{\"name\":\"SERVER_PORT\",\"value\":\"$SERVER_PORT\"},
		{\"name\":\"HTTP_PORT\",\"value\":\"$HTTP_PORT\"},
		{\"name\":\"ELASTICSEARCH_URL\",\"value\":\"$ELASTICSEARCH_URL\"},
		{\"name\":\"ELASTICSEARCH_HOST\",\"value\":\"$ELASTICSEARCH_HOST\"},
		{\"name\":\"ELASTICSEARCH_PORT\",\"value\":\"$ELASTICSEARCH_PORT\"}
	]"
}

docker_defaults() {
	DOCKER_CMD=$(jq ".DOCKER_CMD" $CONFIG_FILE)
	DOCKER_NETWORK=$(jq ".DOCKER_NETWORK" $CONFIG_FILE)
	DOCKER_ADDED_HOST=$(jq ".DOCKER_ADDED_HOST" $CONFIG_FILE)
	DOCKER_MODULE_DEFAULT_PORT=$(jq ".DOCKER_MODULE_DEFAULT_PORT" $CONFIG_FILE)
	RUN_WITH_DOCKER=$(jq ".RUN_WITH_DOCKER" $CONFIG_FILE)

	export DOCKER_CMD=$(echo $DOCKER_CMD | sed 's/"//g')
	export DOCKER_NETWORK=$(echo $DOCKER_NETWORK | sed 's/"//g')
	export DOCKER_ADDED_HOST=$(echo $DOCKER_ADDED_HOST | sed 's/"//g')
	export DOCKER_MODULE_DEFAULT_PORT=$(echo $DOCKER_MODULE_DEFAULT_PORT | sed 's/"//g')
	export RUN_WITH_DOCKER=$(echo $RUN_WITH_DOCKER | sed 's/"//g')
}

user_defaults() {
	TENANT=$(jq ".TENANT" $CONFIG_FILE)
	TENANT_NAME=$(jq ".TENANT_NAME" $CONFIG_FILE)
	TENANT_DESCRIPTION=$(jq ".TENANT_DESCRIPTION" $CONFIG_FILE)
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
	USER_PROXY_FOR=$(jq ".USER_PROXY_FOR" $CONFIG_FILE)
	USER_DEPARTMENTS=$(jq ".USER_DEPARTMENTS" $CONFIG_FILE)

	# Remove extra double quotes at start and end of the string
	export TENANT=$(echo $TENANT | sed 's/"//g')
	export TENANT_NAME=$(echo $TENANT_NAME | sed 's/"//g')
	export TENANT_DESCRIPTION=$(echo $TENANT_DESCRIPTION | sed 's/"//g')
	export USERNAME=$(echo $USERNAME | sed 's/"//g')
	export PASSWORD=$(echo $PASSWORD | sed 's/"//g')
	export USER_ACTIVE=$(echo $USER_ACTIVE | sed 's/"//g')
	export USER_BARCODE=$(echo $USER_BARCODE | sed 's/"//g')
	export USER_PERSONAL_FIRSTNAME=$(echo $USER_PERSONAL_FIRSTNAME | sed 's/"//g')
	export USER_PERSONAL_LASTNAME=$(echo $USER_PERSONAL_LASTNAME | sed 's/"//g')
	export USER_PERSONAL_MIDDLENAME=$(echo $USER_PERSONAL_MIDDLENAME | sed 's/"//g')
	export USER_PERSONAL_PREFERRED_FIRST_NAME=$(echo $USER_PERSONAL_PREFERRED_FIRST_NAME | sed 's/"//g')
	export USER_PERSONAL_PHONE=$(echo $USER_PERSONAL_PHONE | sed 's/"//g')
	export USER_PERSONAL_MOBILE_PHONE=$(echo $USER_PERSONAL_MOBILE_PHONE | sed 's/"//g')
	export USER_PERSONAL_PREFERRED_CONTACT_TYPE_ID=$(echo $USER_PERSONAL_PREFERRED_CONTACT_TYPE_ID | sed 's/"//g')
	export USER_PERSONAL_EMAIL=$(echo $USER_PERSONAL_EMAIL | sed 's/"//g')
	export USER_PROXY_FOR=$(echo $USER_PROXY_FOR | sed 's/"//g')
	export USER_DEPARTMENTS=$(echo $USER_DEPARTMENTS | sed 's/"//g')
}

postman_defaults() {
	POSTMAN_API_KEY=$(jq ".POSTMAN_API_KEY" $CONFIG_FILE)
	POSTMAN_URL=$(jq ".POSTMAN_URL" $CONFIG_FILE)
	POSTMAN_IMPORT_OPENAPI_PATH=$(jq ".POSTMAN_IMPORT_OPENAPI_PATH" $CONFIG_FILE)
	POSTMAN_ENVIRONMENT_PATH=$(jq ".POSTMAN_ENVIRONMENT_PATH" $CONFIG_FILE)
	POSTMAN_ENV_LOCAL_WITH_OKAPI_UUID=$(jq ".POSTMAN_ENV_LOCAL_WITH_OKAPI_UUID" $CONFIG_FILE)

	# Environment variable's values
	export POSTMAN_ENV_NAME="Local with okapi"
	export POSTMAN_ENV_OKAPI_URL_VAL=$OKAPI_URL
	export POSTMAN_ENV_MOD_URL_VAL="http://localhost:9131"
	export POSTMAN_ENV_TENANT_VAL=$TENANT
	export POSTMAN_ENV_TOKEN_VAL=""
	export POSTMAN_ENV_USER_ID_VAL=""

	# Remove extra double quotes at start and end of the string
	export POSTMAN_API_KEY=$(echo $POSTMAN_API_KEY | sed 's/"//g')
	export POSTMAN_URL=$(echo $POSTMAN_URL | sed 's/"//g')
	export POSTMAN_IMPORT_OPENAPI_PATH=$(echo $POSTMAN_IMPORT_OPENAPI_PATH | sed 's/"//g')
	export POSTMAN_ENVIRONMENT_PATH=$(echo $POSTMAN_ENVIRONMENT_PATH | sed 's/"//g')
	export POSTMAN_ENV_LOCAL_WITH_OKAPI_UUID=$(echo $POSTMAN_ENV_LOCAL_WITH_OKAPI_UUID | sed 's/"//g')
}

set_args() {
	ARGS=$*
	for ARG in $ARGS; do
		set_db_arg $ARG
		set_init_arg $ARG
		set_purge_arg $ARG
		set_restart_okapi_arg $ARG
		set_start_okapi_arg $ARG
		set_without_okapi_arg $ARG
		set_import_aliases_arg $ARG
	done

	set_stop_okapi_arg $ARGS
}

set_db_arg() {
	local ARGUMENT=$1

	if [[ "$DB_ARG" -eq 1 ]]; then
		return
	fi

	DB_ARG=0
	if [ $ARGUMENT == "db" ]; then
		DB_ARG=1
	fi
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

set_start_okapi_arg() {
	local ARGUMENT=$1

	if [[ "$START_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	START_OKAPI_ARG=0
	if [ $ARGUMENT == "start" ]; then
		START_OKAPI_ARG=1
	fi
}

set_import_aliases_arg() {
	local ARGUMENT=$1
	
	IMPORT_ALIASES_ARG=0
	if [ $ARGUMENT == "import-aliases" ]; then
		IMPORT_ALIASES_ARG=1
	fi

	import_aliases
}

set_stop_okapi_arg() {
	local ARGUMENT=$1
	local PORT=$2

	if [[ "$STOP_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	if [ ! -z "$PORT" ]; then
        STOP_OKAPI_PROT_ARG=$PORT
	fi

	STOP_OKAPI_ARG=0
	if [[ $ARGUMENT == "stop" ]]; then
		STOP_OKAPI_ARG=1
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

handle_db_operations() {
	if [[ "$DB_ARG" -eq 0 ]]; then
		return
	fi

	shift
	DB_ARGS=$*

	db_pre_process

	db_process

	exit 0
}

empty_logs() {
	empty_output_file

	empty_okapi_nohup_file
}

empty_output_file() {
	clear_file $OUTPUT_FILE
}

# TODO: it does not work, try to find a solution
empty_okapi_nohup_file() {
	clear_file $OKAPI_NOHUP_FILE
}

clear_file() {
	: > $1
}

go_to_modules_dir() {
	cd "$MODULES_DIR"
}

rerun_okapi() {
	if [[ "$RESTART_OKAPI_ARG" -eq 0 ]]; then
		REVERT_RESTART_OKAPI_ARG=1
	fi

	RESTART_OKAPI_ARG=1
	run_okapi

	if [[ "$REVERT_RESTART_OKAPI_ARG" -eq 1 ]]; then
		REVERT_RESTART_OKAPI_ARG=0
	fi
}

run_okapi() {
	# Do not run Okapi if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	# Do nothing if Okapi is already running without setting restart argument
	is_okapi_running
	IS_OKAPI_RUNNING=$?
	if [[ "$IS_OKAPI_RUNNING" -eq 1 ]] && [[ "$RESTART_OKAPI_ARG" -eq 0 ]] && [[ "$START_OKAPI_ARG" -eq 0 ]] && [[ "$INIT_ARG" -eq 0 ]] && [[ "$PURGE_ARG" -eq 0 ]]; then
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
	if [[ "$IS_OKAPI_RUNNING" -eq 1 ]] && ([[ "$RESTART_OKAPI_ARG" -eq 1 ]] || [[ "$START_OKAPI_ARG" -eq 1 ]] || [[ "$INIT_ARG" -eq 1 ]] || [[ "$PURGE_ARG" -eq 1 ]]); then
		stop_okapi
	fi

	# Init Okapi
	if [[ "$INIT_ARG" -eq 1 ]]; then
	    log "Init Okapi ..."

		init_okapi
	fi

	# Purge Okapi
	if [[ "$PURGE_ARG" -eq 1 ]]; then
	    log "Purge Okapi ..."

		purge_okapi
	fi

	# Start Okapi
	log "Start Okapi ..."

	start_okapi

	delete_deployed_modules
}

# Set Environment Variables to Okapi
set_env_vars_to_okapi() {
	# Do not set Okapi env variables if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	log "Set environment variables to okapi"

	set_file_name $BASH_SOURCE
	while read -r LINE; do
		local NAME=$(echo "$LINE" | jq -r '.name')
		local VALUE=$(echo "$LINE" | jq -r '.value')

		run_with_docker
		FOUND=$?
		if [[ $NAME == "OKAPI_URL" ]] && [[ "$FOUND" -eq 1 ]]; then
			VALUE=$DOCKER_OKAPI_URL
		fi

		curl_req -d"{\"name\":\"$NAME\",\"value\":\"$VALUE\"}" $OKAPI_URL/_/env
	done < <(echo "$OKAPI_ENV_VARS" | jq -c '.[]')
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

	set_file_name $BASH_SOURCE
	curl_req -d"{\"id\":\"$TENANT\", \"name\":\"$TENANT_NAME\", \"description\":\"$TENANT_DESCRIPTION\"}" $OKAPI_URL/_/proxy/tenants
}

# Enable okapi module to tenant
enable_okapi() {
	local INDEX=$1
	local JSON_LIST=$2

	log "Enable okapi for tenant: $TENANT"

	install_module enable okapi $INDEX $JSON_LIST
}
