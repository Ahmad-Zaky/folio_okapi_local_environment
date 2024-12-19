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

################################################
# 		END - VALIDATE PREVIOUS SCRIPTS		   #
################################################


has_registered() {
	local MODULE=$1
	local LOCAL_VERSION_FROM=$2

	# Do not proceed if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	get_module_versioned $MODULE $LOCAL_VERSION_FROM

	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	set_file_name $BASH_SOURCE
	curl_req $OPTIONS $OKAPI_URL/_/proxy/modules
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	RESULT=$(echo $CURL_RESPONSE | jq ".[] | .id == \"$VERSIONED_MODULE\"")
	RESULT=$(echo $RESULT | sed 's/"//g')

	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

has_deployed() {
	local MODULE=$1
	local LOCAL_VERSION_FROM=$2

	# Do not proceed if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

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

	RESULT=$(echo $CURL_RESPONSE | jq ".[] | .srvcId == \"$VERSIONED_MODULE\"")
	RESULT=$(echo $RESULT | sed 's/"//g')

	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

has_installed() {
	local MODULE=$1
	local TENANT=$2
	local LOCAL_VERSION_FROM=$3

	# Do not proceed if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	if [[ -n "$LOCAL_VERSION_FROM" ]]; then
		get_module_versioned $MODULE $LOCAL_VERSION_FROM
	fi

	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	set_file_name $BASH_SOURCE
	curl_req $OPTIONS $OKAPI_URL/_/proxy/tenants/$TENANT/modules
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	if [[ -n "$LOCAL_VERSION_FROM" ]]; then
		RESULT=$(echo $CURL_RESPONSE | jq ".[] | .id == \"$VERSIONED_MODULE\"")
	else
		RESULT=$(echo $CURL_RESPONSE | jq '[.[] | select(.id | contains("'$MODULE'"))] | length > 0')
	fi

	RESULT=$(echo $RESULT | sed 's/"//g')

	has_arg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

should_clone() {
	local INDEX=$1
	local JSON_LIST=$2
	local SUPPRESS_STEP=$3

	if [[ $SUPPRESS_STEP == "clone" ]] || [[ $SUPPRESS_STEP == "build" ]] || [[ $SUPPRESS_STEP == "register" ]] || [[ $SUPPRESS_STEP == "deploy" ]] || [[ $SUPPRESS_STEP == "install" ]]; then
		return 1
	fi

	if [[ ! -z "$SUPPRESS_STEP" ]]; then
		return 0
	fi

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
	local SUPPRESS_STEP=$3

	if [[ $SUPPRESS_STEP == "build" ]] || [[ $SUPPRESS_STEP == "register" ]] || [[ $SUPPRESS_STEP == "deploy" ]] || [[ $SUPPRESS_STEP == "install" ]]; then
		return 1
	fi

	if [[ ! -z "$SUPPRESS_STEP" ]]; then
		return 0
	fi

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
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3
	local SUPPRESS_STEP=$3

	if [[ $SUPPRESS_STEP == "rebuild" ]]; then
		return 1
	fi

	if [[ ! -z "$SUPPRESS_STEP" ]]; then
		return 0
	fi

	if [[ "$SHOULD_REBUILD_MODULE" == "$MODULE" ]]; then
		return 1
	fi
	
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
	local SUPPRESS_STEP=$3

	if [[ $SUPPRESS_STEP == "register" ]] || [[ $SUPPRESS_STEP == "deploy" ]] || [[ $SUPPRESS_STEP == "install" ]]; then
		return 1
	fi

	if [[ ! -z "$SUPPRESS_STEP" ]]; then
		return 0
	fi

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
	local SUPPRESS_STEP=$3

	if [[ $SUPPRESS_STEP == "deploy" ]] || [[ $SUPPRESS_STEP == "install" ]]; then
		return 1
	fi

	if [[ ! -z "$SUPPRESS_STEP" ]]; then
		return 0
	fi

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
	local SUPPRESS_STEP=$3

	if [[ $SUPPRESS_STEP == "install" ]]; then
		return 1
	fi

	if [[ ! -z "$SUPPRESS_STEP" ]]; then
		return 0
	fi

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

pre_clone() {
	local INDEX=$1
	local JSON_LIST=$2
	local MODULE=$3
	local SUPPRESS_STEP=$4

	# Validate Module Repo
	validate_module_repo $MODULE $INDEX $JSON_LIST

	# Validate Module Tags and Branches
	validate_module_tag_branch $INDEX $JSON_LIST

	# Validate New Module Tags
	validate_new_module_tag $MODULE $INDEX $JSON_LIST
	
	# Validate New Module Branches
	validate_new_module_branch $MODULE $INDEX $JSON_LIST

	# Validate Access Token
	validate_module_access_token $INDEX $JSON_LIST

	export_module_envs $MODULE $INDEX $JSON_LIST

	get_module_docker_container_env_options $MODULE $INDEX $JSON_LIST
}

pre_build() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3
	local SUPPRESS_STEP=$4

	should_build $INDEX $JSON_LIST $SUPPRESS_STEP
	if [[ "$?" -eq 0 ]]; then
		return
	fi
	
	checkout_new_tag $MODULE
	checkout_new_branch $MODULE
}

post_build() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3
	local SUPPRESS_STEP=$4

	should_build $INDEX $JSON_LIST $SUPPRESS_STEP
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	if [[ $EMPTY_REQUIRES_ARRAY_IN_MODULE_DESCRIPTOR == "true" ]]; then
		build_directory_exists $MODULE
		FOUND=$?
		if [[ $FOUND -eq 0 ]]; then
			return
		fi

		# Opt in the module
		cd $MODULE

		empty_requires_array_in_module_descriptor

		# Opt out from the module
		cd ..
	fi
}

pre_register() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3
	local SUPPRESS_STEP=$4

	handle_cloud_okapi $MODULE $INDEX $JSON_LIST

	if [[ $MODULE == $PERMISSIONS_MODULE ]]; then
		HAS_PERMISSIONS_MODULE=true
	fi

	if [[ $MODULE == $USERS_BL_MODULE ]]; then
		HAS_USERS_BL_MODULE=true
	fi

	if [[ $MODULE == $PASSWORD_VALIDATOR_MODULE ]]; then
		HAS_PASSWORD_VALIDATOR_MODULE=true
	fi

	if [[ $MODULE == $USERS_MODULE ]]; then
		HAS_USERS_MODULE=true
	fi
}

pre_install() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3
	local SUPPRESS_STEP=$4

	should_install $INDEX $JSON_LIST $SUPPRESS_STEP
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	pre_authenticate $MODULE $INDEX $JSON_LIST
}

post_install() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3
	local SUPPRESS_STEP=$4

	postman $MODULE $INDEX $JSON_LIST

	# Do not proceed  if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	# Add new user
	should_login
	local SHOULD_LOGIN=$?
	if [[ $SHOULD_LOGIN -eq 1 ]]; then
		post_authenticate
	fi

	if [[ $HAS_USERS_MODULE == true ]] && [[ -z "$UUID" ]]; then
		new_user
		update_env_postman $POSTMAN_API_KEY # Update postman environment variables
	fi

	should_install $INDEX $JSON_LIST $SUPPRESS_STEP
	if [[ "$?" -eq 1 ]]; then
		# Set permissions related to mod-users-bl
		if [[ $HAS_USERS_BL_MODULE == true ]] && [[ $MODULE == "$USERS_BL_MODULE" ]]; then
			set_users_bl_module_permissions $INDEX

			# Update postman environment variables
			update_env_postman $POSTMAN_API_KEY
		fi
	fi

	re_export_env_vars

	reset_vars
}

# Clone module
clone_module() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3
	local SUPPRESS_STEP=$4

	should_clone $INDEX $JSON_LIST $SUPPRESS_STEP
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# Clone the module repo
	JUST_CLONED_MODULE=0
	if [ ! -d $MODULE ]; then
		log "Clone module $MODULE"
		
		# Print Repo Link
		log $REPO

		eval "$REPO"
		
		JUST_CLONED_MODULE=1
	fi

	if [[ ! -d "$MODULE" ]]; then
		set_file_name $BASH_SOURCE
		error "$MODULE is missing. git clone failed?"
	fi
}

# Build (compile) module
build_module() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3
	local SUPPRESS_STEP=$4

	should_build $INDEX $JSON_LIST $SUPPRESS_STEP
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	should_rebuild $MODULE $INDEX $JSON_LIST
	SHOULD_REBUILD=$?

	# Opt in the module
	cd $MODULE

	# not a java with maven module for now skip the build step
	if [[ ! -f pom.xml ]]; then
		# Opt out from the module
		cd ..

		return
	fi

	# NOTE: sometimes in linux if the module directory is previously deleted when the module will be cloned again
	# the target module some how appears with no complete content, so we will remove the target folder and rebuild
	# again.
	local JAR_EXT="jar"
	local TARGET_DIR="target"
	local TARGET_HAS_JAR_FILES=0
	if [[ -d $TARGET_DIR ]] && [[ $JUST_CLONED_MODULE -eq 1 ]]; then
		directory_contains_files_by_extension_check $TARGET_DIR $JAR_EXT
		local TARGET_HAS_JAR_FILES=$?
		if [[ $TARGET_HAS_JAR_FILES -eq 1 ]]; then
			# Opt out from the module
			cd ..

			return
		fi
	fi

	local MODULE_DESCRIPTOR=target/ModuleDescriptor.json
	if [[ -f $MODULE_DESCRIPTOR ]] && [[ "$SHOULD_REBUILD" -eq 0 ]]; then
		# Opt out from the module
		cd ..

		return
	fi

	# remove the target directory to start building fresh
	if [[ $TARGET_HAS_JAR_FILES -eq 0 ]]; then
		remove_directory $TARGET_DIR
	fi

	# Default Build command
	BUILD="mvn -DskipTests -Dmaven.test.skip=true package"

	# Custom Build command
	has "build" $INDEX ../$JSON_LIST
	if [[ "$?" -eq 1 ]]; then
		local BUILD=$(jq ".[$INDEX].build" ../$JSON_LIST)
		
		# Remove extra double quotes at start and end of the string
		BUILD=$(echo $BUILD | sed 's/"//g')	
	fi

	log "Build module $MODULE"

	# build
	eval "$BUILD"

	# Opt out from the module
	cd ..
}

# Register (store) module into Okapi
register_module() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3
	local SUPPRESS_STEP=$4
	local MODULE_DESCRIPTOR=$MODULE/target/ModuleDescriptor.json

	should_register $INDEX $JSON_LIST $SUPPRESS_STEP
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# Do not use local okapi instance instead use already running okapi instance on the cloud
	if [ -n "$CLOUD_OKAPI_URL" ]; then

		# Do not Skip server okapi if enabled
		is_server_okapi_enabled $INDEX $JSON_LIST
		IS_ENABLED=$?
		if [[ "$IS_ENABLED" -eq 1 ]]; then
			return
		fi
	fi

	# Do not run modules that depend on local Okapi instance if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	has_registered $MODULE $VERSION_FROM
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	# Validate module descriptor file
	if [[ ! -f $MODULE_DESCRIPTOR ]]; then
		set_file_name $BASH_SOURCE
		error "$MODULE_DESCRIPTOR missing pwd=`pwd`"
	fi

	log "Register module $MODULE with version ($MODULE_VERSION)"

	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	set_file_name $BASH_SOURCE
	curl_req $OPTIONS -d@$MODULE_DESCRIPTOR $OKAPI_URL/_/proxy/modules
}

# Deploy module into Okapi
deploy_module() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3
	local SUPPRESS_STEP=$4
	local DEPLOY_DESCRIPTOR=$MODULE/target/DeploymentDescriptor.json

	should_deploy $INDEX $JSON_LIST $SUPPRESS_STEP
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# Do not use local okapi instance instead use already running okapi instance on the cloud
	has "okapi" $INDEX $JSON_LIST
	FOUND=$?
	if [[ -n "$CLOUD_OKAPI_URL" ]] && [[ "$FOUND" -eq 1 ]]; then

		# Do not Skip server okapi if enabled
		is_server_okapi_enabled $INDEX $JSON_LIST
		IS_ENABLED=$?
		if [[ "$IS_ENABLED" -eq 1 ]]; then
			deploy_module_directly $MODULE $INDEX $JSON_LIST

			return
		fi
	fi

	# Do not run modules that depend on local Okapi instance if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	has_deployed $MODULE $VERSION_FROM
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	export_next_port $SERVER_PORT

	log "Deploy module $MODULE with version ($MODULE_VERSION) on port: $SERVER_PORT"

	run_with_docker
	FOUND=$?
	if [[ $FOUND -eq 1 ]]; then
		deploy_module_container $MODULE

		return
	fi

	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	set_file_name $BASH_SOURCE
	curl_req $OPTIONS -d@$DEPLOY_DESCRIPTOR $OKAPI_URL/_/deployment/modules
}

deploy_module_container() {
	local MODULE=$1

	# Do not proceed if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi
	
	run_module_container $MODULE

	get_module_versioned $MODULE $VERSION_FROM

	local OPTIONS="-HContent-Type:application/json"
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS="$OPTIONS -HX-Okapi-Token:$OKAPI_HEADER_TOKEN"
	fi

	set_file_name $BASH_SOURCE
	curl_req true --location -XPOST $OKAPI_URL/_/discovery/modules $OPTIONS \
		--data '{
			"instId": "'$VERSIONED_MODULE'",
			"srvcId": "'$VERSIONED_MODULE'",
			"url": "http://'$MODULE':8081"
		}'

	sleep 5
}

# Install (enable) modules for a tenant
install_module() {
	local ACTION=$1
	local MODULE=$2
	local INDEX=$3
	local JSON_LIST=$4
	local SUPPRESS_STEP=$5

	should_install $INDEX $JSON_LIST $SUPPRESS_STEP
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# Do not use local okapi instance instead use already running okapi instance on the cloud
	has "okapi" $INDEX $JSON_LIST
	FOUND=$?
	if [[ -n "$CLOUD_OKAPI_URL" ]] && [[ "$FOUND" -eq 1 ]]; then

		# Do not Skip server okapi if enabled
		is_server_okapi_enabled $INDEX $JSON_LIST
		IS_ENABLED=$?
		if [[ "$IS_ENABLED" -eq 1 ]]; then
			enable_module_directly $MODULE $INDEX $JSON_LIST
			unset CLOUD_OKAPI_URL

			return
		fi
	fi

	# Do not run modules that depend on local Okapi instance Okapi if the argument without-okapi has been set
	if [[ "$WITHOUT_OKAPI_ARG" -eq 1 ]]; then
		return
	fi

	# Build Body Json list of modules with action enable comes as argument
	has_installed $MODULE $TENANT $VERSION_FROM
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
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

		get_install_params $MODULE $INDEX $JSON_LIST

		# Install (enable) modules
		set_file_name $BASH_SOURCE
		curl_req $OPTIONS -d "$PAYLOAD" "$OKAPI_URL/_/proxy/tenants/$TENANT/install$INSTALL_PARAMS"
	fi
}

process() {

	new_line
	log "***********"
	log "Process ..."
	log "***********"

	# Skip okapi module if exists with other modules sent as a parameter to the process method
	FILTERED_MODULE="okapi"
	if [ -n "$1" ]; then
		local FILTERED_MODULE="$FILTERED_MODULE $1"
	fi

	filter_modules_json $JSON_FILE $FILTERED_MODULE

	# Do not filter if SKIP_ENABLE_CHECK is 1
	if [[ $SKIP_ENABLE_CHECK -eq 0 ]]; then
		filter_disabled_modules $FILTERED_JSON_FILE
	fi

	local LENGTH=$(jq '. | length' $FILTERED_JSON_FILE)
	for ((i=0; i<$LENGTH; i++))
	do
		new_line
		process_module $i $FILTERED_JSON_FILE
	done
}

# Clone, Build (compile), Register (declare), Deploy, Install (enable) the module
process_module() {
	local INDEX=$1
	local JSON_LIST=$2
	local SUPPRESS_STEP=$3
	
	# skip enable check for each module
	local SKIP_ENABLE_CHECK=0
	if [ -n "$4" ]; then
		SKIP_ENABLE_CHECK=$4
	fi

	# Skip disabled module
	is_enabled $INDEX $JSON_LIST
	IS_ENABLED=$?
	if [[ "$IS_ENABLED" -eq 0 ]] && [[ "$SKIP_ENABLE_CHECK" -eq 0 ]]; then
		return
	fi

	# Set $MODULE_ID variable to proceed
	set_module_id $INDEX $JSON_LIST

	# Step No. 1
	pre_clone $INDEX $JSON_LIST	$MODULE_ID $SUPPRESS_STEP
	clone_module $MODULE_ID $INDEX $JSON_LIST $SUPPRESS_STEP

	# Step No. 2
	pre_build $MODULE_ID $INDEX $JSON_LIST $SUPPRESS_STEP
	build_module $MODULE_ID $INDEX $JSON_LIST $SUPPRESS_STEP
	post_build $MODULE_ID $INDEX $JSON_LIST $SUPPRESS_STEP

	# Step No. 3
	pre_register $MODULE_ID $INDEX $JSON_LIST $SUPPRESS_STEP
	register_module $MODULE_ID $INDEX $JSON_LIST $SUPPRESS_STEP

	# Step No. 4
	deploy_module $MODULE_ID $INDEX $JSON_LIST $SUPPRESS_STEP

	# Step No. 5
	pre_install $MODULE_ID $INDEX $JSON_LIST $SUPPRESS_STEP
	install_module enable $MODULE_ID $INDEX $JSON_LIST $SUPPRESS_STEP
	post_install $MODULE_ID $INDEX $JSON_LIST $SUPPRESS_STEP
}
