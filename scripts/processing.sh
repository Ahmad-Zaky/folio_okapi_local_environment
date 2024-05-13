#!/bin/bash

####################################################
# 		START - VALIDATE PREVIOUS SCRIPTS		   #
####################################################

if [ ! -f scripts/helpers.sh ]; then
	echo -e "["$(date +"%A, %b %d, %Y %I:%M:%S %p")"] \n\e[1;31m ERROR: Helpers script file is missing \033[0m"
	
    exit 1
fi

if [ ! -f scripts/prepare.sh ]; then
	echo -e "["$(date +"%A, %b %d, %Y %I:%M:%S %p")"] \n\e[1;31m ERROR: Prepare script file is missing \033[0m"
	
    exit 1
fi

################################################
# 		END - VALIDATE PREVIOUS SCRIPTS		   #
################################################


has_registered() {
	local MODULE=$1
	local LOCAL_VERSION_FROM=$2

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

	get_module_versioned $MODULE $LOCAL_VERSION_FROM

	OPTIONS=""
	if test "$OKAPI_HEADER_TOKEN" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER_TOKEN
	fi

	set_file_name $BASH_SOURCE
	curl_req $OPTIONS $OKAPI_URL/_/proxy/tenants/$TENANT/modules
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
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

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

pre_clone() {
	local INDEX=$1
	local JSON_LIST=$2

	# Validate Module Id
	validate_module_id $INDEX $JSON_LIST

	local MODULE=$MODULE_ID

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

	checkout_new_tag $MODULE
	checkout_new_branch $MODULE
}

post_build() {
	local MODULE=$1

	if [[ $EMPTY_REQUIRES_ARRAY_IN_MODULE_DESCRIPTOR == "true" ]]; then
		# Opt in the module
		cd $MODULE

		empty_requires_array_in_module_desriptor

		# Opt out from the module
		cd ..
	fi
}

pre_register() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	handle_cloud_okapi $MODULE $INDEX $JSON_LIST

	if [[ $MODULE == $PERMISSIONS_MODULE ]]; then
		HAS_PERMISSIONS_MODULE=true
	fi

	if [[ $MODULE == $USERS_BL_MODULE ]]; then
		HAS_USERS_BL_MODULE=true
	fi

	if [[ $MODULE == $USERS_MODULE ]]; then
		HAS_USERS_MODULE=true
	fi
}

pre_install() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	should_install $INDEX $JSON_LIST
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
	should_login
	local SHOULD_LOGIN=$?
	if [[ $SHOULD_LOGIN -eq 1 ]]; then
		post_authenticate
	fi

	if [[ $HAS_USERS_MODULE == true ]] && [[ -z "$UUID" ]]; then
		new_user
		update_env_postman $POSTMAN_API_KEY # Update postman environment variables
	fi

	should_install $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# Set permissions related to mod-users-bl
	if [[ $HAS_USERS_BL_MODULE == true ]] && [[ $MODULE == "$USERS_BL_MODULE" ]]; then
		set_users_bl_module_permissions $INDEX

		# Update postman environment variables
		update_env_postman $POSTMAN_API_KEY
	fi

	re_export_env_vars

	reset_vars
}

# Clone module
clone_module() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	should_clone $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# Clone the module repo
	if [ ! -d $MODULE ]; then
		log "Clone module $MODULE"
		
		# Print Repo Link
		log $REPO

		eval "$REPO"
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

	should_build $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	should_rebuild $MODULE $INDEX $JSON_LIST
	SHOULD_REBUILD=$?
	local MODULE_DESCRIPTOR=$MODULE/target/ModuleDescriptor.json
	if [[ -f $MODULE_DESCRIPTOR ]] && [[ "$SHOULD_REBUILD" -eq 0 ]]; then
		return
	fi

	# Opt in the module
	cd $MODULE

	# Default Build command
	BUILD="mvn -DskipTests -Dmaven.test.skip=true verify"

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
	local MODULE_DESCRIPTOR=$MODULE/target/ModuleDescriptor.json

	should_register $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# Do not use local okapi instance instead use already running okapi instance on the cloud
	if [ -n "$CLOUD_OKAPI_URL" ]; then

		# Do not Skip server okapi if enabled
		is_server_okapi_enabled $INDEX $JSON_LIST
		IS_ENALBLED=$?
		if [[ "$IS_ENALBLED" -eq 1 ]]; then
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
	local DEPLOY_DESCRIPTOR=$MODULE/target/DeploymentDescriptor.json

	should_deploy $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# Do not use local okapi instance instead use already running okapi instance on the cloud
	has "okapi" $INDEX $JSON_LIST
	FOUND=$?
	if [[ -n "$CLOUD_OKAPI_URL" ]] && [[ "$FOUND" -eq 1 ]]; then

		# Do not Skip server okapi if enabled
		is_server_okapi_enabled $INDEX $JSON_LIST
		IS_ENALBLED=$?
		if [[ "$IS_ENALBLED" -eq 1 ]]; then
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

	should_install $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		return
	fi

	# Do not use local okapi instance instead use already running okapi instance on the cloud
	has "okapi" $INDEX $JSON_LIST
	FOUND=$?
	if [[ -n "$CLOUD_OKAPI_URL" ]] && [[ "$FOUND" -eq 1 ]]; then

		# Do not Skip server okapi if enabled
		is_server_okapi_enabled $INDEX $JSON_LIST
		IS_ENALBLED=$?
		if [[ "$IS_ENALBLED" -eq 1 ]]; then
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

		get_install_params $MODULE $i $JSON_LIST

		# Install (enable) modules
		set_file_name $BASH_SOURCE
		curl_req $OPTIONS -d "$PAYLOAD" "$OKAPI_URL/_/proxy/tenants/$TENANT/install$INSTALL_PARAMS"
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
		clone_module $MODULE_ID $i $JSON_FILE	
		
		# Step No. 2
		pre_build $MODULE_ID
		build_module $MODULE_ID $i $JSON_FILE
		post_build $MODULE_ID

		# Step No. 3
		pre_register $MODULE_ID $i $JSON_FILE
		register_module $MODULE_ID $i $JSON_FILE

		# Step No. 4
		deploy_module $MODULE_ID $i $JSON_FILE

		# Step No. 5
		pre_install $MODULE_ID $i $JSON_FILE
		install_module enable $MODULE_ID $i $JSON_FILE
		post_install $MODULE_ID $i $JSON_FILE
	done
}
