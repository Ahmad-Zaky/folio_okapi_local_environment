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

if [ ! -f scripts/process.sh ]; then
	echo -e "["$(date +"%A, %b %d, %Y %I:%M:%S %p")"] \n\e[1;31m ERROR: Process script file is missing \033[0m"
	
    exit 1
fi

################################################
# 		END - VALIDATE PREVIOUS SCRIPTS		   #
################################################


validate_modules_list() {
	if [ ! -z "$1" ]; then
		JSON_FILE=$1
	fi  

	if [ ! -f "$JSON_FILE" ]; then
		set_file_name $BASH_SOURCE
		error "JSON LIST is missing"
	fi
}

validate_configurations_list() {
	if [ ! -z "$1" ]; then
		CONFIG_FILE=$1
	fi  

	if [ ! -f "$CONFIG_FILE" ]; then
		set_file_name $BASH_SOURCE
		error "Configuration list is missing"
	fi
}

validate_module_id() {
	local INDEX=$1
	local JSON_LIST=$2

	has "id" $INDEX $JSON_LIST
	if [[ "$?" -eq 0 ]]; then
		set_file_name $BASH_SOURCE
		error "Id property is missing"
	fi

	MODULE_ID=$(jq ".[$INDEX].id" $JSON_LIST)
	
	# Remove extra double quotes at start and end of the string
	MODULE_ID=$(echo $MODULE_ID | sed 's/"//g')
}

validate_module_repo() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3

	# Default repo url (FOLIO ORG)
	REPO="git clone --recurse-submodules git@github.com:folio-org/$MODULE"

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
		set_file_name $BASH_SOURCE
		error "Either one of both tag, or branch should be provided"
	fi

	if [[ "$HAS_TAG" -eq 1 ]] && [[ "$HAS_BRANCH" -eq 0 ]]; then
		local TAG=$(jq ".[$INDEX].tag" $JSON_LIST)
		
		# Remove extra double quotes at start and end of the string
		TAG=$(echo $TAG | sed 's/"//g')
		
		# Escape all forward slashes in the string
		TAG=$(echo "$TAG" | sed 's/\//\\\//g')

		REPO=$(echo "$REPO" | sed "s/^git clone/git clone -b $TAG/g")
	fi
	
	if [[ "$HAS_BRANCH" -eq 1 ]] && [[ "$HAS_TAG" -eq 0 ]]; then
		local BRANCH=$(jq ".[$INDEX].branch" $JSON_LIST)
		
		# Remove extra double quotes at start and end of the string
		BRANCH=$(echo $BRANCH | sed 's/"//g')
		
		# Escape all forward slashes in the string
		BRANCH=$(echo "$BRANCH" | sed 's/\//\\\//g')

		REPO=$(echo "$REPO" | sed "s/^git clone/git clone -b $BRANCH/g")
	fi
}

validate_new_module_tag() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3
	NEW_MODULE_TAG=""
	HAS_NEW_TAG=false

	has "tag" $INDEX $JSON_LIST
	local HAS_TAG=$?
	if [[ "$HAS_TAG" -eq 0 ]]; then
		return
	fi

	NEW_MODULE_TAG=$(jq ".[$INDEX].tag" $JSON_LIST)

	# Remove extra double quotes at start and end of the string
	NEW_MODULE_TAG=$(echo $NEW_MODULE_TAG | sed 's/"//g')
	
	if [ ! -d $MODULE ]; then
		return
	fi
	
	get_module_version $MODULE $VERSION_FROM

	if [[ "$NEW_MODULE_TAG" != "v$MODULE_VERSION" ]]; then
		HAS_NEW_TAG=true
	fi
}

validate_new_module_branch() {
	local MODULE=$1
	local INDEX=$2
	local JSON_LIST=$3
	NEW_MODULE_BRANCH=""
	HAS_NEW_BRANCH=false

	has "branch" $INDEX $JSON_LIST
	local HAS_BRANCH=$?
	if [[ "$HAS_BRANCH" -eq 0 ]]; then
		return
	fi

	NEW_MODULE_BRANCH=$(jq ".[$INDEX].branch" $JSON_LIST)

	# Remove extra double quotes at start and end of the string
	NEW_MODULE_BRANCH=$(echo $NEW_MODULE_BRANCH | sed 's/"//g')

	if [ ! -d $MODULE ]; then
		return
	fi

	# Opt in the module
	cd $MODULE

	get_current_branch

	# Opt out from the module
	cd ..

	if [[ "$NEW_MODULE_BRANCH" != "$CURRENT_BRANCH" ]]; then
		HAS_NEW_BRANCH=true
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
		set_file_name $BASH_SOURCE
		error "Postman Open API File is missing"
	fi

	OPEN_API_FILE=$(jq ".[$INDEX].postman.file" $JSON_LIST)
	
	# Remove extra double quotes at start and end of the string
	OPEN_API_FILE=$(echo $OPEN_API_FILE | sed 's/"//g')

	# Validate Open API file exists
	if [ ! -f "$MODULE/$OPEN_API_FILE" ]; then
		set_file_name $BASH_SOURCE
		error "Open API file is missing"
	fi
}

validate_module_postman_api_key() {
	local INDEX=$1
	local JSON_LIST=$2

	has "api_key" $INDEX $JSON_LIST "postman"
	if [[ "$?" -eq 0 ]]; then
		set_file_name $BASH_SOURCE
		error "Postman API Key is missing"
	fi

	MODULE_POSTMAN_API_KEY=$(jq ".[$INDEX].postman.api_key" $JSON_LIST)

	# Remove extra double quotes at start and end of the string
	MODULE_POSTMAN_API_KEY=$(echo $MODULE_POSTMAN_API_KEY | sed 's/"//g')

	if [ -z "$MODULE_POSTMAN_API_KEY" ]; then
		set_file_name $BASH_SOURCE
		error "Postman API Key is empty"
	fi
}

validate_okapi_url() {
	local INDEX=$1
	local JSON_LIST=$2

	has "url" $INDEX $JSON_LIST "okapi"
	if [[ "$?" -eq 0 ]]; then
		set_file_name $BASH_SOURCE
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
		set_file_name $BASH_SOURCE
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
		set_file_name $BASH_SOURCE
		error "Okapi credentials username key is missing"
	fi

	has "password" $INDEX $JSON_LIST "okapi.credentials"
	if [[ "$?" -eq 0 ]]; then
		set_file_name $BASH_SOURCE
		error "Okapi credentials password key is missing"
	fi

	SERVER_USERNAME=$(jq ".[$INDEX].okapi.credentials.username" $JSON_LIST)
	SERVER_PASSWORD=$(jq ".[$INDEX].okapi.credentials.password" $JSON_LIST)

	# Remove extra double quotes at start and end of the string
	SERVER_USERNAME=$(echo $SERVER_USERNAME | sed 's/"//g')
	SERVER_PASSWORD=$(echo $SERVER_PASSWORD | sed 's/"//g')
}

validate_linux_tools() {
    for TOOL in "$@"; do
        validate_linux_tool_exists $TOOL
    done
}

validate_linux_tool_exists() {
    local TOOL=$1

    if ! [[ -x "$(command -v $TOOL)" ]]; then
        error "Linux tool ($TOOL) not found !"
    fi
}