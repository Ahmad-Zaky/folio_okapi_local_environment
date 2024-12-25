#!/bin/bash

db_cmd_defaults() {    
	DB_CMD_DOCKER_CMD=$(jq ".DB_CMD_DOCKER_CMD" $CONFIG_FILE)
	DB_CMD_STAGING_OKAPI_USERNAMER=$(jq ".DB_CMD_STAGING_OKAPI_USERNAME" $CONFIG_FILE)
	DB_CMD_USERNAME=$(jq ".DB_CMD_USERNAME" $CONFIG_FILE)
	DB_CMD_DATABASE_STAGING=$(jq ".DB_CMD_DATABASE_STAGING" $CONFIG_FILE)
	DB_CMD_DATABASE=$(jq ".DB_CMD_DATABASE" $CONFIG_FILE)
	DB_CMD_DATABASE_SQL_FILE=$(jq ".DB_CMD_DATABASE_SQL_FILE" $CONFIG_FILE)
	DB_CMD_DUMPED_DATABASE_SQL_FILE=$(jq ".DB_CMD_DUMPED_DATABASE_SQL_FILE" $CONFIG_FILE)
	DB_CMD_DATABASE_SQL_DIR_PATH=$(jq ".DB_CMD_DATABASE_SQL_DIR_PATH" $CONFIG_FILE)
	DB_CMD_CONTAINER=$(jq ".DB_CMD_CONTAINER" $CONFIG_FILE)
	DB_CMD_CP_DUMP_DB_DESTINATION=$(jq ".DB_CMD_CP_DUMP_DB_DESTINATION" $CONFIG_FILE)
	DB_CMD_SCHEMAS_PATH=$(jq ".DB_CMD_SCHEMAS_PATH" $CONFIG_FILE)
	DB_CMD_PGDUMP_INCLUDE_SCHEMA_OPTION=$(jq ".DB_CMD_PGDUMP_INCLUDE_SCHEMA_OPTION" $CONFIG_FILE)
	DB_CMD_PGDUMP_EXCLUDE_SCHEMA_OPTION=$(jq ".DB_CMD_PGDUMP_EXCLUDE_SCHEMA_OPTION" $CONFIG_FILE)
	DB_CMD_CREATE_MODULE_ROLE=$(jq ".DB_CMD_CREATE_MODULE_ROLE" $CONFIG_FILE)
	DB_CMD_ALTER_MODULE_ROLE=$(jq ".DB_CMD_ALTER_MODULE_ROLE" $CONFIG_FILE)

	# Remove extra double quotes at start and end of the string
	export DB_CMD_DOCKER_CMD=$(echo $DB_CMD_DOCKER_CMD | sed 's/"//g')
	export DB_CMD_STAGING_OKAPI_USERNAME=$(echo $DB_CMD_STAGING_OKAPI_USERNAME | sed 's/"//g')
	export DB_CMD_USERNAME=$(echo $DB_CMD_USERNAME | sed 's/"//g')	
	export DB_CMD_DATABASE_STAGING=$(echo $DB_CMD_DATABASE_STAGING | sed 's/"//g')	
	export DB_CMD_DATABASE=$(echo $DB_CMD_DATABASE | sed 's/"//g')	
	export DB_CMD_DATABASE_SQL_FILE=$(echo $DB_CMD_DATABASE_SQL_FILE | sed 's/"//g')
	export DB_CMD_DUMPED_DATABASE_SQL_FILE=$(echo $DB_CMD_DUMPED_DATABASE_SQL_FILE | sed 's/"//g')  # dumped sql file name.
	export DB_CMD_DATABASE_SQL_DIR_PATH=$(echo $DB_CMD_DATABASE_SQL_DIR_PATH | sed 's/"//g')	    # sql db relative path to this script's directory. 
	export DB_CMD_CONTAINER=$(echo $DB_CMD_CONTAINER | sed 's/"//g')	                            # service container name found in the `docker-compose.yml` file
	export DB_CMD_CP_DUMP_DB_DESTINATION=$(echo $DB_CMD_CP_DUMP_DB_DESTINATION | sed 's/"//g')	
	export DB_CMD_SCHEMAS_PATH=$(echo $DB_CMD_SCHEMAS_PATH | sed 's/"//g')
	export DB_CMD_PGDUMP_INCLUDE_SCHEMA_OPTION=$(echo $DB_CMD_PGDUMP_INCLUDE_SCHEMA_OPTION | sed 's/"//g')
	export DB_CMD_PGDUMP_EXCLUDE_SCHEMA_OPTION=$(echo $DB_CMD_PGDUMP_EXCLUDE_SCHEMA_OPTION | sed 's/"//g')	
	export DB_CMD_CREATE_MODULE_ROLE=$(echo $DB_CMD_CREATE_MODULE_ROLE | sed 's/"//g')	
	export DB_CMD_ALTER_MODULE_ROLE=$(echo $DB_CMD_ALTER_MODULE_ROLE | sed 's/"//g')	

    DB_CMD_DATABASE_SQL_PATH="$DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DATABASE_SQL_FILE"          # sql file relative path to this script's directory.
    DB_CMD_COMMAND_WRAPPER="$DB_CMD_DOCKER_CMD exec $DB_CMD_CONTAINER /bin/bash -c \"%s\" \n"   # if you use postgres on your local machine directly, replace this with "%s"
    DB_CMD_COMMAND_WRAPPER_ALT="$DB_CMD_DOCKER_CMD exec $DB_CMD_CONTAINER %s \n"                # if you use postgres on your local machine directly, replace this with "%s"
    DB_CMD_CP_DUMP_DB_SOURCE="/$DB_CMD_DUMPED_DATABASE_SQL_FILE"
    DB_CMD_DOCKER_CP_COMMAND="$DB_CMD_DOCKER_CMD cp $DB_CMD_CONTAINER:$DB_CMD_CP_DUMP_DB_SOURCE $DB_CMD_CP_DUMP_DB_DESTINATION"
    DB_CMD_PGDUMP_SCHEMA_OPTION="$DB_CMD_PGDUMP_INCLUDE_SCHEMA_OPTION"
}

db_has_arg() {
    local TO_BE_FOUND_ARG=$1
    shift

    for ARG in "$@"; do
        if [[ "$ARG" == "$TO_BE_FOUND_ARG" ]]; then
            return 1
        fi
    done

    return 0
}

db_get_arg() {
    local INDEX=$1
    shift
    local ARGS=$*
    FOUND_ARGUMENT="" # reinitialize the variable for next call

    # Split the arguments into positional parameters
    set -- $ARGS

    # Access the specific argument by index
    FOUND_ARGUMENT=$(eval echo \$$INDEX)
}

remove_one_from_arguments() {
    local TO_BE_FOUND_ARG=$1
    shift

    DB_ARGS=""
    for ARG in "$@"; do
        if [[ "$ARG" == "$TO_BE_FOUND_ARG" ]]; then
            continue
        fi

        DB_ARGS="$DB_ARGS $ARG"
    done
}

generate_schemas_substring() {
    SCHEMAS_PATTERN=""

    # Check if the file exists
    if ! [ -e "$DB_CMD_SCHEMAS_PATH" ]; then
        echo -e "\e[1;31mERROR: File $DB_CMD_SCHEMAS_PATH not found. \033[0m"

        exit 1
    fi

    IFS=$'\n'
    for LINE in $(cat $DB_CMD_SCHEMAS_PATH); do
        SCHEMAS_PATTERN="$SCHEMAS_PATTERN $DB_CMD_PGDUMP_SCHEMA_OPTION $LINE"
    done

    trim $SCHEMAS_PATTERN
    SCHEMAS_PATTERN="$TRIMMED"
}

list_schemas() {
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -c \\\"\\dn\\\"")
}

handle_arguments() {
    db_has_arg "staging" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        DB_CMD_HAS_STAGING_ARG=true
        DB_CMD_DATABASE="$DB_CMD_DATABASE_STAGING"
        remove_one_from_arguments "staging" $DB_ARGS
	fi

    db_has_arg "print" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        DB_CMD_HAS_PRINT_ARG=true
        remove_one_from_arguments "print" $DB_ARGS
	fi

    db_has_arg "import" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        DB_CMD_HAS_IMPORT_ARG=true
	fi

    db_has_arg "import-schema" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        db_get_arg 2 $DB_ARGS
        DB_SCHEMA=$FOUND_ARGUMENT
        DB_CMD_HAS_IMPORT_SCHEMA_ARG=true
	fi

    db_has_arg "dump" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        DB_CMD_HAS_DUMP_ARG=true
	fi

    db_has_arg "dump-include-schemas" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        DB_CMD_HAS_DUMP_INCLUDE_SCHEMAS_ARG=true
	fi

    db_has_arg "dump-exclude-schemas" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        DB_CMD_PGDUMP_SCHEMA_OPTION="$DB_CMD_PGDUMP_EXCLUDE_SCHEMA_OPTION"
        DB_CMD_HAS_DUMP_EXCLUDE_SCHEMAS_ARG=true
	fi

    db_has_arg "list-schemas" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        DB_CMD_HAS_LIST_SCHEMAS_ARG=true
	fi
}

import() {
    # Check if the database already exists
    if eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -lqt | cut -d \| -f 1 | grep -qw $DB_CMD_DATABASE"); then
        echo "Database $DB_CMD_DATABASE already exists. Dropping it."

        eval $(printf "$DB_CMD_COMMAND_WRAPPER" "dropdb -U $DB_CMD_USERNAME --if-exists $DB_CMD_DATABASE")
    fi

    if eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -lqt | cut -d \| -f 1 | grep -qw $DB_CMD_DATABASE"); then
        echo "Failed Dropping Database $DB_CMD_DATABASE"

        exit 1
    fi

    # Create the database
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "createdb -U $DB_CMD_USERNAME $DB_CMD_DATABASE")
    echo "Database $DB_CMD_DATABASE created successfully."

    # Remove old database sql file inside Docker image
    if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_CMD_DATABASE_SQL_FILE ]; then echo true; else echo false; fi")) == true ]]; then
        echo "Remove old $DB_CMD_DATABASE_SQL_FILE file."
        eval $(printf "$DB_CMD_COMMAND_WRAPPER" "rm $DB_CMD_DATABASE_SQL_FILE")
    fi

    # Copy SQL file to Docker container
    echo "Copy $DB_CMD_DATABASE_SQL_FILE to $DB_CMD_CONTAINER container"
    $DB_CMD_DOCKER_CMD cp $DB_CMD_DATABASE_SQL_PATH $DB_CMD_CONTAINER:/

    if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_CMD_DATABASE_SQL_FILE ]; then echo true; else echo false; fi")) == false ]]; then
        echo "Failed to copy $DB_CMD_DATABASE_SQL_FILE file."

        exit 1
    fi

    # NOTE: we will not use this snippet and we will replace the role name used inside the sql file with existing role instead
    # # Create new role
    # if ! [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -tAc \\\"SELECT 1 FROM pg_roles WHERE rolname='$DB_CMD_STAGING_OKAPI_USERNAME'\\\"")) == 1 ]]; then
    #     eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -c \"CREATE ROLE $DB_CMD_STAGING_OKAPI_USERNAME WITH LOGIN; GRANT $DB_CMD_USERNAME TO $DB_CMD_STAGING_OKAPI_USERNAME;\"")
    # fi

    echo "Replace OWNER $DB_CMD_STAGING_OKAPI_USERNAME to $DB_CMD_USERNAME in $DB_CMD_DATABASE_SQL_FILE file."
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "sed -i 's/Owner: $DB_CMD_STAGING_OKAPI_USERNAME/Owner: $DB_CMD_USERNAME/g' $DB_CMD_DATABASE_SQL_FILE")
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "sed -i 's/OWNER TO $DB_CMD_STAGING_OKAPI_USERNAME/OWNER TO $DB_CMD_USERNAME/g' $DB_CMD_DATABASE_SQL_FILE")

    echo "Import $DB_CMD_DATABASE_SQL_FILE into $DB_CMD_DATABASE database"
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -f $DB_CMD_DATABASE_SQL_FILE")

    # Remove new schema sql file inside Docker image
    if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_CMD_DATABASE_SQL_FILE ]; then echo true; else echo false; fi")) == true ]]; then
        echo "Remove new $DB_CMD_DATABASE_SQL_FILE file."
        eval $(printf "$DB_CMD_COMMAND_WRAPPER" "rm $DB_CMD_DATABASE_SQL_FILE")
    fi
}

import_schema() {
    DB_SCHEMA_FILE="$DB_SCHEMA.sql"
    DB_CMD_SCHEMA_SQL_PATH="$DB_CMD_DATABASE_SQL_DIR_PATH/$DB_SCHEMA_FILE"

    # Drop schema if already exists
    echo "Drop Schema $DB_SCHEMA if exists."

    db_run_query "DROP SCHEMA IF EXISTS $DB_SCHEMA CASCADE"

    # Remove old schema sql file inside Docker image
    if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_CMD_DATABASE_SQL_FILE ]; then echo true; else echo false; fi")) == true ]]; then
        echo "Remove old $DB_SCHEMA_FILE file."
        eval $(printf "$DB_CMD_COMMAND_WRAPPER" "rm $DB_SCHEMA_FILE")
    fi

    # Copy SQL file to Docker container
    echo "Copy $DB_SCHEMA_FILE to $DB_CMD_CONTAINER container"
    $DB_CMD_DOCKER_CMD cp $DB_CMD_SCHEMA_SQL_PATH $DB_CMD_CONTAINER:/

    if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_SCHEMA_FILE ]; then echo true; else echo false; fi")) == false ]]; then
        echo "Failed to copy $DB_SCHEMA_FILE file."

        exit 1
    fi

    # Add schema role
    echo "Create $DB_SCHEMA role"
    local QUERY=$(printf "$DB_CMD_CREATE_MODULE_ROLE" "$DB_SCHEMA")
    db_run_query "$QUERY"

    local QUERY=$(printf "$DB_CMD_ALTER_MODULE_ROLE" "$DB_SCHEMA" "$DB_SCHEMA")
    db_run_query "$QUERY"

    echo "Replace OWNER $DB_CMD_STAGING_OKAPI_USERNAME to $DB_CMD_USERNAME in $DB_SCHEMA_FILE file."
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "sed -i 's/Owner: $DB_CMD_STAGING_OKAPI_USERNAME/Owner: $DB_CMD_USERNAME/g' $DB_SCHEMA_FILE")
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "sed -i 's/OWNER TO $DB_CMD_STAGING_OKAPI_USERNAME/OWNER TO $DB_CMD_USERNAME/g' $DB_SCHEMA_FILE")

    echo "Import $DB_SCHEMA_FILE schema into $DB_CMD_DATABASE database"
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -f $DB_SCHEMA_FILE")

    # Remove new schema sql file inside Docker image
    if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_CMD_DATABASE_SQL_FILE ]; then echo true; else echo false; fi")) == true ]]; then
        echo "Remove new $DB_SCHEMA_FILE file."
        eval $(printf "$DB_CMD_COMMAND_WRAPPER" "rm $DB_SCHEMA_FILE")
    fi
}

dump_db() {
    local WITH_SCHEMAS=$1

    if [[ $WITH_SCHEMAS == true ]]; then

        generate_schemas_substring

        local DB_DUMP_COMMAND=`printf "$DB_CMD_COMMAND_WRAPPER" "pg_dump -b -v -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE $SCHEMAS_PATTERN > $DB_CMD_DUMPED_DATABASE_SQL_FILE"`
        if [[ $DB_CMD_HAS_PRINT_ARG == true ]]; then
            echo $DB_DUMP_COMMAND

            exit 0
        fi

        echo "Dump Database $DB_CMD_DATABASE to $DB_CMD_DUMPED_DATABASE_SQL_FILE"
        eval $($DB_DUMP_COMMAND)

        if echo "$DB_CMD_COMMAND_WRAPPER" | grep -q "docker"; then
            eval $DB_CMD_DOCKER_CP_COMMAND
        fi

        return
    fi

    local DB_DUMP_COMMAND=`printf "$DB_CMD_COMMAND_WRAPPER" "pg_dump -b -v -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE > $DB_CMD_DUMPED_DATABASE_SQL_FILE"`
    if [[ $DB_CMD_HAS_PRINT_ARG == true ]]; then
        echo $DB_DUMP_COMMAND

        exit 0
    fi

    echo "Dump Database $DB_CMD_DATABASE to $DB_CMD_DUMPED_DATABASE_SQL_FILE"
    eval $DB_DUMP_COMMAND

    if echo "$DB_CMD_COMMAND_WRAPPER" | grep -q "docker"; then
        eval $DB_CMD_DOCKER_CP_COMMAND
    fi
}

db_pre_process() {
    db_cmd_defaults

    handle_arguments
}

db_run_query() {
    local QUERY=$1

    db_cmd_defaults

    if [[ $DB_CMD_HAS_STAGING_ARG == true ]]; then
        DB_CMD_DATABASE="$DB_CMD_DATABASE_STAGING"
    fi
    
    eval $(printf "$DB_CMD_COMMAND_WRAPPER_ALT" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -c \"$QUERY\"")
}

db_process() {
    if [[ $DB_CMD_HAS_IMPORT_ARG == true ]]; then
        import

        return
    fi
    
    if [[ $DB_CMD_HAS_IMPORT_SCHEMA_ARG == true ]]; then
        import_schema

        return
    fi

    if [[ $DB_CMD_HAS_DUMP_ARG == true ]]; then
        dump_db

        return
    fi

    if [[ $DB_CMD_HAS_DUMP_INCLUDE_SCHEMAS_ARG == true ]] || [[ $DB_CMD_HAS_DUMP_EXCLUDE_SCHEMAS_ARG == true ]]; then
        dump_db true

        return
    fi

    if [[ $DB_CMD_HAS_LIST_SCHEMAS_ARG == true ]]; then
        list_schemas

        return
    fi

    echo -e "\e[1;31mERROR: No arguments passed. \033[0m"

    exit 1
}
