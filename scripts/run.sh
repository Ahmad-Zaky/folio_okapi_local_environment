#!/bin/bash

################################
# 		START - HELPERS		   #
################################


# Output Error
error() {
    echo -e "\n\e[1;31m ERROR: $1 \033[0m"
    exit 1 
}

# Check if key exists
has() {
	if grep -q $(jq ".[$2] | has(\"$1\")" $3) <<< "true"; then
		return 1
	fi

	return 0
}

# Get file content
getFileContent() {
	# Get the name of the JSON file.
	local FILE_NAME=$1

	# Read the contents of the JSON file.
	JSON_DATA="$(cat $FILE_NAME)"
}

# Search in arguments
hasArg() {
	local ARGS=$1
	local FIND=$2
	
	for ARG in $ARGS; do
		if [[ "$ARG" =~ "$FIND" ]]; then
				return 1
			break
		fi
	done

	return 0
}

# Default Variable values
defaults() {
	echo -e "Setting default env variables"
	echo -e ""

	OKAPI_HEADER=x

	# Okapi Url
	OKAPI_URL=http://localhost:9130

	# Test Tenant
	TENANT=testlib1

	# Test User
	USERNAME=testing_admin
	PASSWORD=admin

	# Modules directory path
	MODULE_DIR=../modules

	# Modules list file
	# JSON_FILE="$MODULE_DIR/modules.json"
	JSON_FILE="modules.json"
}

# Basic Okapi curl boilerplate
okapi_curl() {
	local OKAPI_HEADER=$1

	local OPTIONS="-HX-Okapi-Tenant:$TENANT"
	if test "$OKAPI_HEADER" != "x"; then
		OPTIONS="-HX-Okapi-Token:$OKAPI_HEADER"
	fi
	
	shift

	curl -s $OPTIONS -HContent-Type:application/json $*
	echo -e ""
}

# Generate the modules list in this format "mod-users mod-login mod-permissions mod-configuration"
set_modules_list() {
	local MODULE=$1

	# First time
	if [[ ! -v MODULES ]]; then
		MODULES="$MODULE"

		return
	fi

	MODULES="$MODULES $MODULE"
}

pre_register() {
	local MODULE=$1

	pre_authenticate $MODULE
}

post_install() {
	local MODULE=$1

	post_authenticate $MODULE
}

# Pre register mod-authtoken module
pre_authenticate() {
	local MODULE=$1
	local AUTHTOKEN_MODULE="mod-authtoken"

	if [ $MODULE != $AUTHTOKEN_MODULE ]; then
		return
	fi

	enable_okapi

	should_login $OKAPI_HEADER

	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		login_admin
		get_user_uuid_by_username $OKAPI_HEADER $USERNAME

		return
	fi

	make_adminuser $OKAPI_HEADER $USERNAME $PASSWORD
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

has_tenant() {
	local TENANT=$1
	
	RESULT=$(curl -s $OKAPI_URL/_/proxy/tenants | jq ".[] | .id | contains(\"$TENANT\")")

	hasArg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

has_registered() {
	local OKAPI_HEADER=$1
	local MODULE_ID=$2

	OPTIONS=""
	if test "$OKAPI_HEADER" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER
	fi

	RESULT=$(curl -s $OPTIONS $OKAPI_URL/_/proxy/modules | jq ".[] | .id | contains(\"$MODULE_ID\")")

	hasArg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

has_deployed() {
	local OKAPI_HEADER=$1
	local MODULE_ID=$2

	OPTIONS=""
	if test "$OKAPI_HEADER" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER
	fi

	RESULT=$(curl -s $OPTIONS $OKAPI_URL/_/discovery/modules | jq ".[] | .srvcId | contains(\"$MODULE_ID\")")

	hasArg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

has_installed() {
	local OKAPI_HEADER=$1
	local MODULE_ID=$2
	local TENANT=$3

	OPTIONS=""
	if test "$OKAPI_HEADER" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER
	fi

	# Remove extra double quotes at start and end of the string
	MODULE_ID=$(echo $MODULE_ID | sed 's/"//g')
	RESULT=$(curl -s $OPTIONS $OKAPI_URL/_/proxy/tenants/$TENANT/modules | jq ".[] | .id | contains(\"$MODULE_ID\")")

	hasArg "$RESULT" "true"
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return 1
	fi

	return 0
}

should_login() {
	local OKAPI_HEADER=$1

	STATUS_CODE=$(curl -s -w "%{http_code}" -HX-Okapi-Tenant:$TENANT $OKAPI_URL/users -o /dev/null)
	if [[ "$STATUS_CODE" != "200" ]]; then
		return 1
	fi

	return 0
}

get_random_permission_uuid_by_user_uuid() {
	local OKAPI_HEADER=$1
	local UUID=$2

	local OPTIONS="-HX-Okapi-Tenant:$TENANT"
	if test "$OKAPI_HEADER" != "x"; then
		OPTIONS="-HX-Okapi-Token:$OKAPI_HEADER"
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

# Set extra permissions related to module mod-users-bl
set_users_bl_module_permissions() {
	local MODULES=$*
	local USERS_BL_MODULE="mod-users-bl"
	
	# Validate that mod-users-bl is installed
	hasArg "$MODULES" "$USERS_BL_MODULE"
	FOUND=$?
	if [[ "$FOUND" -eq 0 ]]; then
		return
	fi

	get_user_uuid_by_username $TOKEN $USERNAME
	get_random_permission_uuid_by_user_uuid $TOKEN $UUID

	okapi_curl $TOKEN $OKAPI_URL/perms/users/$PUUID/permissions -d'{"permissionName":"users-bl.all"}'
	echo -e ""

	okapi_curl $TOKEN $OKAPI_URL/perms/users/$PUUID/permissions -d'{"permissionName":"users-bl.password-reset-link.generate"}'
	echo -e ""

	login_admin
	echo -e ""

	# NOTE: this request does not work for the first time, but it works fine the second time
	# the reason why is not clear but may be related to the UUID, AND PUUID
	
	okapi_curl $TOKEN $OKAPI_URL/bl-users/password-reset/link -d"{\"userId\":\"$UUID\"}" -o reset.json

	getFileContent reset.json

	# Check if the JSON data contains the string "requires permission".
	if grep -q "requires permission" <<< "$JSON_DATA"; then
		echo "Access for user '$USERNAME' requires permission: users-bl.password-reset-link.generate"
		exit 1
	fi
	unset JSON_DATA

	TOKEN_2=`jq -r '.link' < reset.json | sed -e 's/.*\/reset-password\/\([^?]*\).*/\1/g'`

	echo -e "Second token: $TOKEN_2"

	curl -s -HX-Okapi-Token:$TOKEN_2 $OKAPI_URL/bl-users/password-reset/validate -d'{}'

	echo -e ""
}

################################
# 		 END - HELPERS		   #
################################







################################
# 		 START - PREPARE	   #
################################


# Set Environment Variables to Okapi
set_env_vars_to_okapi() {
	echo -e "Set environment variables to okapi"

	echo -e ""

	curl -s -d'{"name":"DB_HOST","value":"localhost"}' $OKAPI_URL/_/env -o /dev/null
	curl -s -d'{"name":"DB_PORT","value":"5432"}' $OKAPI_URL/_/env -o /dev/null
	curl -s -d'{"name":"DB_USERNAME","value":"okapi"}' $OKAPI_URL/_/env -o /dev/null
	curl -s -d'{"name":"DB_PASSWORD","value":"okapi25"}' $OKAPI_URL/_/env -o /dev/null
	curl -s -d'{"name":"DB_DATABASE","value":"okapi"}' $OKAPI_URL/_/env -o /dev/null
	curl -s -d"{\"name\":\"OKAPI_URL\",\"value\":\"$OKAPI_URL\"}" $OKAPI_URL/_/env -o /dev/null
	curl -s -d'{"name":"KAFKA_PORT","value":"9093"}' $OKAPI_URL/_/env -o /dev/null
	curl -s -d'{"name":"KAFKA_HOST","value":"localhost"}' $OKAPI_URL/_/env -o /dev/null
	curl -s -d'{"name":"ELASTICSEARCH_URL","value":"http://localhost:9200"}' $OKAPI_URL/_/env -o /dev/null

	echo -e ""
}

# Store new tenant
new_tenant() {
	echo -e "Add new tenant: $TENANT"
	echo -e ""
	
	has_tenant $TENANT
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	curl -s -d"{\"id\":\"$TENANT\"}" $OKAPI_URL/_/proxy/tenants

	echo -e ""
}

# Enable okapi module to tenant
enable_okapi() {
	install_modules $OKAPI_HEADER enable okapi
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

validate_module_id() {
	local INDEX=$1
	local JSON_LIST=$2

	$(has "id" $INDEX $JSON_LIST)
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
	$(has "repo" $INDEX $JSON_LIST)
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

	$(has "branch" $INDEX $JSON_LIST)
	local HAS_BRANCH=$?

	$(has "tag" $INDEX $JSON_LIST)
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

	$(has "access_token" $INDEX $JSON_LIST)
	local HAS_ACCESS_TOKEN=$?
	if [[ "$HAS_ACCESS_TOKEN" -eq 1 ]]; then
		local ACCESS_TOKEN=$(jq ".[$INDEX].access_token" $JSON_LIST)

		# Remove extra double quotes at start and end of the string
		ACCESS_TOKEN=$(echo $ACCESS_TOKEN | sed 's/"//g')
		
		B64_ACCESS_TOKEN=$(printf ":%s" "$ACCESS_TOKEN" | base64)
		REPO=$(echo "$REPO" | sed "s/^git/git -c http.extraHeader=\"Authorization: Basic ${B64_ACCESS_TOKEN}\"/g")
	fi
}


################################
# 		END - VALIDATION	   #
################################





##################################################################
#   START - Clone, Compile, Register, Deploy, Install (Enable)   #
##################################################################

# Clone module
clone_module() {
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

	# Clone the module repo
	if [ ! -d $MODULE_ID ]; then
		echo -e "Clone module $MODULE_ID"
		
		echo -e ""
		echo -e $REPO
		echo -e ""

		eval "$REPO"
	fi

	if [[ ! -d "$MODULE_ID" ]]; then
		error "$MODULE_ID is missing. git clone failed?"
	fi
}

# Compile module
compile_module() {
	local MODULE_ID=$1
	local INDEX=$2
	local JSON_LIST=$3

	local MODULE_DESCRIPTOR=$MODULE_ID/target/ModuleDescriptor.json
	if [[ -f $MODULE_DESCRIPTOR ]]; then
		return
	fi

	# Opt in the module
	cd $MODULE_ID
	
	# Default Compile command
	COMPILE="mvn -DskipTests -Dmaven.test.skip=true verify"

	# Custom Compile command
	$(has "compile" $INDEX ../$JSON_LIST)
	if [[ "$?" -eq 1 ]]; then
		local COMPILE=$(jq ".[$INDEX].compile" ../$JSON_LIST)
		
		# Remove extra double quotes at start and end of the string
		COMPILE=$(echo $COMPILE | sed 's/"//g')	
	fi

	echo -e "Compile module $MODULE_ID"

	# compile
	eval "$COMPILE"

	# Opt out from the module
	cd ..
}

# Clone and compile modules one by one
clone_compile_modules() {
	validate_modules_list

	local LENGTH=$(jq '. | length' $JSON_FILE)

	for ((i=0; i<$LENGTH; i++))
	do
		clone_module $i $JSON_FILE		
		compile_module $MODULE_ID $i $JSON_FILE
		set_modules_list $MODULE_ID # its useful for upcomming steps
	done
}

# Register (store) module into Okapi
register_module() {
	local OKAPI_HEADER=$1
	local MODULE_ID=$2
	local MODULE_DESCRIPTOR=$MODULE_ID/target/ModuleDescriptor.json

	has_registered $OKAPI_HEADER $MODULE_ID
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	# Validate module descriptor file
	if [[ ! -f $MODULE_DESCRIPTOR ]]; then
		error "$MODULE_DESCRIPTOR missing pwd=`pwd`"
	fi

	echo -e "Register module $MODULE_ID"

	OPTIONS=""
	if test "$OKAPI_HEADER" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER
	fi

	curl -s $OPTIONS -d@$MODULE_DESCRIPTOR $OKAPI_URL/_/proxy/modules -o /dev/null

	echo -e ""
}

# Deploy module into Okapi
deploy_module() {
	local OKAPI_HEADER=$1
	local MODULE_ID=$2
	local DEPLOY_DESCRIPTOR=$MODULE_ID/target/DeploymentDescriptor.json
	
	has_deployed $OKAPI_HEADER $MODULE_ID
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
		return
	fi

	echo "Deploy module $MODULE_ID"

	OPTIONS=""
	if test "$1" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER
	fi

	curl -s $OPTIONS -d@$DEPLOY_DESCRIPTOR $OKAPI_URL/_/deployment/modules

	echo -e ""
}

# Install (enable) modules for a tenant
install_modules() {
	local OKAPI_HEADER=$1
	local ACTION=$2
	
	shift && shift

	local MODULES=$*

	# Build Body Json list of modules with action enable comes as argument
	local PAYLOAD="["
	local SEPERATOR=""
	for MODULE in $MODULES; do
		has_installed $OKAPI_HEADER $MODULE $TENANT
		FOUND=$?
		if [[ "$FOUND" -eq 1 ]]; then
			continue
		fi

		PAYLOAD="$PAYLOAD $SEPERATOR {\"action\":\"$ACTION\",\"id\":\"$MODULE\"}"
		SEPERATOR=","
	done
	PAYLOAD="$PAYLOAD]"

	# Set Okapi Token if set
	OPTIONS=""
	if test "$OKAPI_HEADER" != "x"; then
		OPTIONS=-HX-Okapi-Token:$OKAPI_HEADER
	fi

	# Validate if the list is empty	
	LENGTH=$(echo "$PAYLOAD" | jq ". | length")
	if [ $LENGTH -eq 0 ]; then
		return
	fi

	echo -e "Install (Enable) $MODULES"

	# Install (enable) modules
	curl -s $OPTIONS "-d$PAYLOAD" "$OKAPI_URL/_/proxy/tenants/$TENANT/install?purge=true"

	echo -e ""
}

# Register, deploy, and install (enable) modules one by one
register_deploy_install_modules() {
	local OKAPI_HEADER=$1 && shift
	local MODULES=$*

	for MODULE in $MODULES; do
		pre_register $MODULE		
		register_module $OKAPI_HEADER $MODULE

		deploy_module $OKAPI_HEADER $MODULE

		install_modules $OKAPI_HEADER enable $MODULE
		post_install $MODULE
	done
}

#################################################################
#    END - Clone, Compile, Register, Deploy, Install (Enable)   #
#################################################################





################################
# 	START - Additional Steps   #
################################


# New admin user with all permissions
make_adminuser() {
	local OKAPI_HEADER=$1
	local USERNAME=$2
	local PASSWORD=$3

	echo -e "Make Admin User with credentials: "
	echo -e "username: $USERNAME"
	echo -e "password: $PASSWORD"
	echo -e ""

	# Delete admin user firstly if exists
	okapi_curl $OKAPI_HEADER -XDELETE "$OKAPI_URL/users?query=username%3D%3D$USERNAME"
	echo -e ""

	# New admin user
	UUID=`uuidgen`
	okapi_curl $OKAPI_HEADER -d"{\"username\":\"$USERNAME\",\"id\":\"$UUID\",\"active\":true}" $OKAPI_URL/users
	echo -e ""

	okapi_curl $OKAPI_HEADER -d"{\"username\":\"$USERNAME\",\"userId\":\"$UUID\",\"password\":\"$PASSWORD\"}" $OKAPI_URL/authn/credentials
	echo -e ""
	
	# Set permissions for the new admin user
	PUUID=`uuidgen`
	okapi_curl $OKAPI_HEADER -d"{\"id\":\"$PUUID\",\"userId\":\"$UUID\",\"permissions\":[\"okapi.all\",\"perms.all\",\"users.all\",\"login.item.post\",\"perms.users.assign.immutable\"]}" $OKAPI_URL/perms/users

	echo -e ""
}

# Login to obtain the token from the header
login_admin() {
	
	echo -e "Login with credentials: "
	echo -e "username: $USERNAME"
	echo -e "password: $PASSWORD"
	echo -e ""

	curl -s -Dheaders -HX-Okapi-Tenant:$TENANT -HContent-Type:application/json -d"{\"username\":\"$USERNAME\",\"password\":\"$PASSWORD\"}" $OKAPI_URL/authn/login
	echo -e ""

	TOKEN=`awk '/x-okapi-token/ {print $2}' <headers|tr -d '[:space:]'`
	OKAPI_HEADER=$TOKEN

	echo -e ""
}

get_user_uuid_by_username() {
	local OKAPI_HEADER=$1
	local USERNAME=$2

	local OPTIONS="-HX-Okapi-Tenant:$TENANT"
	if test "$OKAPI_HEADER" != "x"; then
		OPTIONS="-HX-Okapi-Token:$OKAPI_HEADER"
	fi

	UUID=$(curl -s $OPTIONS $OKAPI_URL/users | jq ".users[] | select(.username == \"$USERNAME\") | .id")

	# Remove extra double quotes at start and end of the string
	UUID=$(echo $UUID | sed 's/"//g')
}

################################
# 	 END - Additional Steps    #
################################





#####################################
# 			 START - RUN			#
#####################################

defaults

new_tenant

set_env_vars_to_okapi

clone_compile_modules

register_deploy_install_modules $OKAPI_HEADER $MODULES

set_users_bl_module_permissions $MODULES

#####################################
# 			  END - RUN 			#
#####################################
