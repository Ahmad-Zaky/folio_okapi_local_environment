#!/bin/bash

db_cmd_defaults() {    
	DB_CMD_DOCKER_CMD=$(jq ".DB_CMD_DOCKER_CMD" $CONFIG_FILE)
	DB_CMD_STAGING_OKAPI_USERNAME=$(jq ".DB_CMD_STAGING_OKAPI_USERNAME" $CONFIG_FILE)
	DB_CMD_USERNAME=$(jq ".DB_CMD_USERNAME" $CONFIG_FILE)
	DB_CMD_DATABASE_STAGING=$(jq ".DB_CMD_DATABASE_STAGING" $CONFIG_FILE)
	DB_CMD_DATABASE=$(jq ".DB_CMD_DATABASE" $CONFIG_FILE)
	DB_CMD_DATABASE_SQL_FILE=$(jq ".DB_CMD_DATABASE_SQL_FILE" $CONFIG_FILE)
	DB_CMD_DUMPED_DATABASE_SQL_FILE=$(jq ".DB_CMD_DUMPED_DATABASE_SQL_FILE" $CONFIG_FILE)
	DB_CMD_DUMPED_DATABASE_SQL_FILE_PREFIX=$(jq ".DB_CMD_DUMPED_DATABASE_SQL_FILE_PREFIX" $CONFIG_FILE)
	DB_CMD_DUMPED_DATABASE_DIR_PATH=$(jq ".DB_CMD_DUMPED_DATABASE_DIR_PATH" $CONFIG_FILE)
	DB_CMD_DATABASE_SQL_DIR_PATH=$(jq ".DB_CMD_DATABASE_SQL_DIR_PATH" $CONFIG_FILE)
	DB_CMD_CONTAINER=$(jq ".DB_CMD_CONTAINER" $CONFIG_FILE)
	DB_CMD_CP_DUMP_DB_DESTINATION=$(jq ".DB_CMD_CP_DUMP_DB_DESTINATION" $CONFIG_FILE)
	DB_CMD_SCHEMAS_FILE=$(jq ".DB_CMD_SCHEMAS_FILE" $CONFIG_FILE)
	DB_CMD_PGDUMP_INCLUDE_SCHEMA_OPTION=$(jq ".DB_CMD_PGDUMP_INCLUDE_SCHEMA_OPTION" $CONFIG_FILE)
	DB_CMD_PGDUMP_EXCLUDE_SCHEMA_OPTION=$(jq ".DB_CMD_PGDUMP_EXCLUDE_SCHEMA_OPTION" $CONFIG_FILE)
	DB_CMD_CREATE_MODULE_ROLE=$(jq ".DB_CMD_CREATE_MODULE_ROLE" $CONFIG_FILE)
	DB_CMD_ALTER_MODULE_ROLE=$(jq ".DB_CMD_ALTER_MODULE_ROLE" $CONFIG_FILE)
	DB_CMD_PSQL_WITH_DOCKER=$(jq ".DB_CMD_PSQL_WITH_DOCKER" $CONFIG_FILE)
	DB_CMD_REMOTE_HOST=$(jq ".DB_CMD_REMOTE_HOST" $CONFIG_FILE)
	DB_CMD_REMOTE_USERNAME=$(jq ".DB_CMD_REMOTE_USERNAME" $CONFIG_FILE)
	DB_CMD_REMOTE_PASSWORD=$(jq ".DB_CMD_REMOTE_PASSWORD" $CONFIG_FILE)
	DB_CMD_REMOTE_DATABASE=$(jq ".DB_CMD_REMOTE_DATABASE" $CONFIG_FILE)
	DB_CMD_REMOTE_DIR_PATH=$(jq ".DB_CMD_REMOTE_DIR_PATH" $CONFIG_FILE)

	# Remove extra double quotes at start and end of the string
	export DB_CMD_DOCKER_CMD=$(echo $DB_CMD_DOCKER_CMD | sed 's/"//g')
	export DB_CMD_STAGING_OKAPI_USERNAME=$(echo $DB_CMD_STAGING_OKAPI_USERNAME | sed 's/"//g')
	export DB_CMD_USERNAME=$(echo $DB_CMD_USERNAME | sed 's/"//g')
	export DB_CMD_DATABASE_STAGING=$(echo $DB_CMD_DATABASE_STAGING | sed 's/"//g')
	export DB_CMD_DATABASE=$(echo $DB_CMD_DATABASE | sed 's/"//g')
	export DB_CMD_DATABASE_SQL_FILE=$(echo $DB_CMD_DATABASE_SQL_FILE | sed 's/"//g')
	export DB_CMD_DUMPED_DATABASE_SQL_FILE=$(echo $DB_CMD_DUMPED_DATABASE_SQL_FILE | sed 's/"//g')                  # dumped sql file name.
	export DB_CMD_DUMPED_DATABASE_SQL_FILE_PREFIX=$(echo $DB_CMD_DUMPED_DATABASE_SQL_FILE_PREFIX | sed 's/"//g')    # dumped sql file name.
	export DB_CMD_DUMPED_DATABASE_DIR_PATH=$(echo $DB_CMD_DUMPED_DATABASE_DIR_PATH | sed 's/"//g')                  # dumped sql file name.
	export DB_CMD_DATABASE_SQL_DIR_PATH=$(echo $DB_CMD_DATABASE_SQL_DIR_PATH | sed 's/"//g')	                    # sql db relative path to this script's directory. 
	export DB_CMD_CONTAINER=$(echo $DB_CMD_CONTAINER | sed 's/"//g')                                                # service container name found in the `docker-compose.yml` file
	export DB_CMD_CP_DUMP_DB_DESTINATION=$(echo $DB_CMD_CP_DUMP_DB_DESTINATION | sed 's/"//g')
	export DB_CMD_SCHEMAS_FILE=$(echo $DB_CMD_SCHEMAS_FILE | sed 's/"//g')
	export DB_CMD_PGDUMP_INCLUDE_SCHEMA_OPTION=$(echo $DB_CMD_PGDUMP_INCLUDE_SCHEMA_OPTION | sed 's/"//g')
	export DB_CMD_PGDUMP_EXCLUDE_SCHEMA_OPTION=$(echo $DB_CMD_PGDUMP_EXCLUDE_SCHEMA_OPTION | sed 's/"//g')
	export DB_CMD_CREATE_MODULE_ROLE=$(echo $DB_CMD_CREATE_MODULE_ROLE | sed 's/"//g')
	export DB_CMD_ALTER_MODULE_ROLE=$(echo $DB_CMD_ALTER_MODULE_ROLE | sed 's/"//g')
    export DB_CMD_PSQL_WITH_DOCKER=$(echo $DB_CMD_PSQL_WITH_DOCKER | sed 's/"//g')
    export DB_CMD_REMOTE_HOST=$(echo $DB_CMD_REMOTE_HOST | sed 's/"//g')
    export DB_CMD_REMOTE_USERNAME=$(echo $DB_CMD_REMOTE_USERNAME | sed 's/"//g')
    export DB_CMD_REMOTE_PASSWORD=$(echo $DB_CMD_REMOTE_PASSWORD | sed 's/"//g')
    export DB_CMD_REMOTE_DATABASE=$(echo $DB_CMD_REMOTE_DATABASE | sed 's/"//g')
    export DB_CMD_REMOTE_DIR_PATH=$(echo $DB_CMD_REMOTE_DIR_PATH | sed 's/"//g')

    DB_CMD_DATABASE_SQL_PATH="$DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DATABASE_SQL_FILE"                              # sql file relative path to this script's directory.
    DB_CMD_REMOTE_DIR_RELATIVE_PATH="$DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_REMOTE_DIR_PATH"

    # if you use docker for postgres go to if block else you go in the `else` block
    if [[ $DB_CMD_PSQL_WITH_DOCKER == "true" ]]; then
        DB_CMD_COMMAND_WRAPPER="$DB_CMD_DOCKER_CMD exec $DB_CMD_CONTAINER /bin/bash -c \"%s\" \n"
        DB_CMD_COMMAND_WRAPPER_ALT="$DB_CMD_DOCKER_CMD exec $DB_CMD_CONTAINER %s \n"
        DB_CMD_COMMAND_WRAPPER_ALT_INTERACTIVE="$DB_CMD_DOCKER_CMD exec -i $DB_CMD_CONTAINER %s \n"
    else
        DB_CMD_COMMAND_WRAPPER="%s \n"
        DB_CMD_COMMAND_WRAPPER_ALT="%s \n"
        DB_CMD_COMMAND_WRAPPER_ALT_INTERACTIVE="%s \n"
    fi

    DB_CMD_CP_DUMP_DB_SOURCE="/$DB_CMD_DUMPED_DATABASE_SQL_FILE"
    DB_CMD_DOCKER_CP_COMMAND="$DB_CMD_DOCKER_CMD cp $DB_CMD_CONTAINER:$DB_CMD_CP_DUMP_DB_SOURCE $DB_CMD_CP_DUMP_DB_DESTINATION"
    DB_CMD_PGDUMP_SCHEMA_OPTION="$DB_CMD_PGDUMP_INCLUDE_SCHEMA_OPTION"                              # default value is include '-n' option
    DB_CMD_SCHEMAS_PATH=$DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_SCHEMAS_FILE
}

log() {
	echo -e "["$(date +"%A, %b %d, %Y %I:%M:%S %p")"] $1"
}

log_stars_title() {
    local title="$1"
    local star_line_length=$(( ${#title} + 4 )) # 2 spaces + 2 stars
    local star_line=$(printf '*%.0s' $(seq 1 $star_line_length))
    
    log "$star_line"
    log "* $title *"
    log "$star_line"
}

new_line() {
	echo -e "\n"
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
        log -e "\e[1;31mERROR: File $DB_CMD_SCHEMAS_PATH not found. \033[0m"

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

list_remote_schemas() {
    export PG_LIST_SCHEMAS_CMD=$(printf "$DB_CMD_COMMAND_WRAPPER_ALT_INTERACTIVE" "psql -h $DB_CMD_REMOTE_HOST -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -c \"\\dn\"")

    remote_auto_authenticate "$PG_LIST_SCHEMAS_CMD" "Password*" $DB_CMD_REMOTE_PASSWORD

    unset PG_LIST_SCHEMAS_CMD
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

    db_has_arg "import-table" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        db_get_arg 2 $DB_ARGS
        DB_SCHEMA=$FOUND_ARGUMENT

        db_get_arg 3 $DB_ARGS
        DB_TABLE=$FOUND_ARGUMENT

        DB_CMD_HAS_IMPORT_TABLE_ARG=true
	fi

    db_has_arg "import-remote-schema" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        db_get_arg 2 $DB_ARGS
        REMOTE_SCHEMA=$FOUND_ARGUMENT
        DB_CMD_HAS_IMPORT_REMOTE_SCHEMA_ARG=true
	fi

    db_has_arg "import-remote-table" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        db_get_arg 2 $DB_ARGS
        REMOTE_SCHEMA=$FOUND_ARGUMENT

        db_get_arg 3 $DB_ARGS
        REMOTE_TABLE=$FOUND_ARGUMENT

        DB_CMD_HAS_IMPORT_REMOTE_TABLE_ARG=true
	fi

    db_has_arg "dump" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        DB_CMD_HAS_DUMP_ARG=true
	fi

    db_has_arg "dump-schema" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        db_get_arg 2 $DB_ARGS
        DB_SCHEMA=$FOUND_ARGUMENT
        DB_CMD_HAS_DUMP_SCHEMA_ARG=true
	fi

    db_has_arg "dump-table" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        db_get_arg 2 $DB_ARGS
        DB_SCHEMA=$FOUND_ARGUMENT

        db_get_arg 3 $DB_ARGS
        DB_TABLE=$FOUND_ARGUMENT

        DB_CMD_HAS_DUMP_TABLE_ARG=true
	fi

    db_has_arg "dump-remote-schema" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        db_get_arg 2 $DB_ARGS
        REMOTE_SCHEMA=$FOUND_ARGUMENT
        DB_CMD_HAS_DUMP_REMOTE_SCHEMA_ARG=true
	fi

    db_has_arg "dump-remote-table" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        db_get_arg 2 $DB_ARGS
        REMOTE_SCHEMA=$FOUND_ARGUMENT

        db_get_arg 3 $DB_ARGS
        REMOTE_TABLE=$FOUND_ARGUMENT

        DB_CMD_HAS_DUMP_REMOTE_TABLE_ARG=true
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

    db_has_arg "list-remote-schemas" $DB_ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        DB_CMD_HAS_LIST_REMOTE_SCHEMAS_ARG=true
	fi
}

import() {
    new_line
    log_stars_title "Import database $DB_CMD_DATABASE"
    new_line

    # Check if the database already exists
    if eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -lqt | cut -d \| -f 1 | grep -qw $DB_CMD_DATABASE"); then
        new_line
        log "Database $DB_CMD_DATABASE already exists. Dropping it."
        new_line

        eval $(printf "$DB_CMD_COMMAND_WRAPPER" "dropdb -U $DB_CMD_USERNAME --if-exists $DB_CMD_DATABASE")
    fi

    if eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -lqt | cut -d \| -f 1 | grep -qw $DB_CMD_DATABASE"); then
        new_line
        log "Failed Dropping Database $DB_CMD_DATABASE"
        new_line

        exit 1
    fi

    # Create the database
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "createdb -U $DB_CMD_USERNAME $DB_CMD_DATABASE")

    new_line
    log "Database $DB_CMD_DATABASE created successfully."
    new_line

    DB_CMD_DATABASE_SQL_FILE_PATH=$DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DATABASE_SQL_FILE
    if echo "$DB_CMD_COMMAND_WRAPPER" | grep -q "docker"; then
        DB_CMD_DATABASE_SQL_FILE_PATH=$DB_CMD_DATABASE_SQL_FILE

        # Remove old database sql file inside Docker image
        if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_CMD_DATABASE_SQL_FILE ]; then echo true; else echo false; fi")) == true ]]; then
            new_line
            log "Remove old $DB_CMD_DATABASE_SQL_FILE file."
            new_line

            eval $(printf "$DB_CMD_COMMAND_WRAPPER" "rm $DB_CMD_DATABASE_SQL_FILE")
        fi

        # Copy SQL file to Docker container
        new_line
        log "Copy $DB_CMD_DATABASE_SQL_FILE to $DB_CMD_CONTAINER container"
        new_line

        $DB_CMD_DOCKER_CMD cp $DB_CMD_DATABASE_SQL_PATH $DB_CMD_CONTAINER:/

        if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_CMD_DATABASE_SQL_FILE ]; then echo true; else echo false; fi")) == false ]]; then
            new_line
            log "Failed to copy $DB_CMD_DATABASE_SQL_FILE file."
            new_line

            exit 1
        fi
    fi

    # NOTE: we will not use this snippet and we will replace the role name used inside the sql file with existing role instead
    # # Create new role
    # if ! [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -tAc \\\"SELECT 1 FROM pg_roles WHERE rolname='$DB_CMD_STAGING_OKAPI_USERNAME'\\\"")) == 1 ]]; then
    #     eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -c \"CREATE ROLE $DB_CMD_STAGING_OKAPI_USERNAME WITH LOGIN; GRANT $DB_CMD_USERNAME TO $DB_CMD_STAGING_OKAPI_USERNAME;\"")
    # fi

    new_line
    log "Replace OWNER $DB_CMD_STAGING_OKAPI_USERNAME to $DB_CMD_USERNAME in $DB_CMD_DATABASE_SQL_FILE_PATH file."
    new_line

    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "sed -i 's/Owner: $DB_CMD_STAGING_OKAPI_USERNAME/Owner: $DB_CMD_USERNAME/g' $DB_CMD_DATABASE_SQL_FILE_PATH")
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "sed -i 's/OWNER TO $DB_CMD_STAGING_OKAPI_USERNAME/OWNER TO $DB_CMD_USERNAME/g' $DB_CMD_DATABASE_SQL_FILE_PATH")

    new_line
    log "Import $DB_CMD_DATABASE_SQL_FILE_PATH into $DB_CMD_DATABASE database"
    new_line

    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -f $DB_CMD_DATABASE_SQL_FILE_PATH")

    # Remove new schema sql file inside Docker image
    if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_CMD_DATABASE_SQL_FILE_PATH ]; then echo true; else echo false; fi")) == true ]]; then
        new_line
        log "Remove new $DB_CMD_DATABASE_SQL_FILE_PATH file."
        new_line

        eval $(printf "$DB_CMD_COMMAND_WRAPPER" "rm $DB_CMD_DATABASE_SQL_FILE_PATH")
    fi
}

import_schema() {
    local DB_SCHEMA=$1
    local DB_SCHEMA_FILE=$2
    local DB_CMD_SCHEMA_SQL_PATH=$3

    new_line
    log_stars_title "Import database schema $DB_SCHEMA"
    new_line

    # Drop schema if already exists
    new_line
    log "Drop Schema $DB_SCHEMA if exists."
    new_line

    db_run_query "DROP SCHEMA IF EXISTS $DB_SCHEMA CASCADE"

    DB_SCHEMA_FILE_PATH=$DB_CMD_DATABASE_SQL_DIR_PATH/$DB_SCHEMA_FILE
    if echo "$DB_CMD_COMMAND_WRAPPER" | grep -q "docker"; then
        DB_SCHEMA_FILE_PATH=$DB_SCHEMA_FILE

        # Remove old schema sql file inside Docker image
        if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_SCHEMA_FILE_PATH ]; then echo true; else echo false; fi")) == true ]]; then
            new_line
            log "Remove old $DB_SCHEMA_FILE_PATH file."
            new_line

            eval $(printf "$DB_CMD_COMMAND_WRAPPER" "rm $DB_SCHEMA_FILE_PATH")
        fi

        # Copy SQL file to Docker container
        new_line
        log "Copy $DB_SCHEMA_FILE_PATH to $DB_CMD_CONTAINER container"
        new_line

        $DB_CMD_DOCKER_CMD cp $DB_CMD_SCHEMA_SQL_PATH $DB_CMD_CONTAINER:/

        if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_SCHEMA_FILE_PATH ]; then echo true; else echo false; fi")) == false ]]; then
            new_line
            log "Failed to copy $DB_SCHEMA_FILE_PATH file."
            new_line

            exit 1
        fi
    fi

    # Add schema role
    new_line
    log "Create $DB_SCHEMA role"
    new_line

    local QUERY=$(printf "$DB_CMD_CREATE_MODULE_ROLE" "$DB_SCHEMA")
    db_run_query "$QUERY"

    local QUERY=$(printf "$DB_CMD_ALTER_MODULE_ROLE" "$DB_SCHEMA" "$DB_SCHEMA")
    db_run_query "$QUERY"

    new_line
    log "Replace OWNER $DB_CMD_STAGING_OKAPI_USERNAME to $DB_CMD_USERNAME in $DB_SCHEMA_FILE_PATH file."
    new_line

    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "sed -i 's/Owner: $DB_CMD_STAGING_OKAPI_USERNAME/Owner: $DB_CMD_USERNAME/g' $DB_SCHEMA_FILE_PATH")
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "sed -i 's/OWNER TO $DB_CMD_STAGING_OKAPI_USERNAME/OWNER TO $DB_CMD_USERNAME/g' $DB_SCHEMA_FILE_PATH")

    new_line
    log "Import $DB_SCHEMA_FILE_PATH schema into $DB_CMD_DATABASE database"
    new_line

    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -f $DB_SCHEMA_FILE_PATH")

    # Remove new schema sql file inside Docker image
    if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_CMD_DATABASE_SQL_FILE ]; then echo true; else echo false; fi")) == true ]]; then
        new_line
        log "Remove new $DB_SCHEMA_FILE_PATH file."
        new_line

        eval $(printf "$DB_CMD_COMMAND_WRAPPER" "rm $DB_SCHEMA_FILE_PATH")
    fi
}

import_table() {
    local DB_TABLE=$1
    local DB_SCHEMA=$2
    local DB_TABLE_FILE=$3
    local DB_CMD_TABLE_SQL_PATH=$4

    new_line
    log_stars_title "Import table $DB_TABLE into $DB_SCHEMA schema"
    new_line

    new_line
    log_stars_title "NOTE: Drop a table may affect its relations with other tables, press Ctlr + c if you do not want to proceed !!!"
    new_line

    sleep 10

    # Drop table if already exists
    log "Drop Table $DB_TABLE from Schema $DB_SCHEMA if exists."

    db_run_query "DROP TABLE IF EXISTS $DB_SCHEMA.$DB_TABLE  CASCADE;"

    DB_TABLE_FILE_PATH=$DB_CMD_DATABASE_SQL_DIR_PATH/$DB_TABLE_FILE
    if echo "$DB_CMD_COMMAND_WRAPPER" | grep -q "docker"; then
        DB_TABLE_FILE_PATH=$DB_TABLE_FILE

        # Remove old table sql file inside Docker image
        if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_TABLE_FILE ]; then echo true; else echo false; fi")) == true ]]; then
            new_line
            log "Remove old $DB_TABLE_FILE file."
            new_line

            eval $(printf "$DB_CMD_COMMAND_WRAPPER" "rm $DB_TABLE_FILE")
        fi

        # Copy SQL file to Docker container
        new_line
        log "Copy $DB_TABLE_FILE to $DB_CMD_CONTAINER container"
        new_line

        $DB_CMD_DOCKER_CMD cp $DB_CMD_TABLE_SQL_PATH $DB_CMD_CONTAINER:/

        if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_TABLE_FILE ]; then echo true; else echo false; fi")) == false ]]; then
            new_line
            log "Failed to copy $DB_TABLE_FILE file."
            new_line

            exit 1
        fi
    fi

    new_line
    log "Replace OWNER $DB_CMD_STAGING_OKAPI_USERNAME to $DB_CMD_USERNAME in $DB_TABLE_FILE_PATH file."
    new_line

    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "sed -i 's/Owner: $DB_CMD_STAGING_OKAPI_USERNAME/Owner: $DB_CMD_USERNAME/g' $DB_TABLE_FILE_PATH")
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "sed -i 's/OWNER TO $DB_CMD_STAGING_OKAPI_USERNAME/OWNER TO $DB_CMD_USERNAME/g' $DB_TABLE_FILE_PATH")

    new_line
    log "Import $DB_TABLE_FILE_PATH table into $DB_CMD_DATABASE.$DB_SCHEMA database schema"
    new_line

    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -f $DB_TABLE_FILE_PATH")

    # Remove new table sql file inside Docker image
    if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_CMD_DATABASE_SQL_FILE ]; then echo true; else echo false; fi")) == true ]]; then
        new_line
        log "Remove new $DB_TABLE_FILE_PATH file."
        new_line

        eval $(printf "$DB_CMD_COMMAND_WRAPPER" "rm $DB_TABLE_FILE_PATH")
    fi
}

import_remote_schema() {
    new_line
    log_stars_title "Import remote schema $REMOTE_SCHEMA"
    new_line

    new_line
    log_stars_title "Step #1 - dump $REMOTE_SCHEMA"
    dump_remote_schema $REMOTE_SCHEMA

    new_line
    log_stars_title "Step #2 - import $REMOTE_SCHEMA"
    import_schema $REMOTE_SCHEMA $DB_CMD_REMOTE_FILE $DB_CMD_REMOTE_DIR_RELATIVE_PATH_FILE
}

import_remote_table() {
    new_line
    log_stars_title "Import remote table $REMOTE_TABLE in schema $REMOTE_SCHEMA"
    new_line

    new_line
    log_stars_title "Step #1 - dump $REMOTE_TABLE table from $REMOTE_SCHEMA schema"
    dump_remote_table $REMOTE_SCHEMA $REMOTE_TABLE

    new_line
    log_stars_title "Step #2 - import $REMOTE_TABLE table from $REMOTE_SCHEMA schema"
    import_table $REMOTE_TABLE $REMOTE_SCHEMA $DB_CMD_REMOTE_FILE $DB_CMD_REMOTE_DIR_RELATIVE_PATH_FILE
}

dump() {
    new_line
    log_stars_title "Dump database $DB_CMD_DATABASE"
    new_line

    local WITH_SCHEMAS=$1

    mkdir -p $DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DUMPED_DATABASE_DIR_PATH

    if [[ $WITH_SCHEMAS == true ]]; then

        generate_schemas_substring

        local DB_DUMP_COMMAND=`printf "$DB_CMD_COMMAND_WRAPPER" "pg_dump -b -v -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE $SCHEMAS_PATTERN > $DB_CMD_DUMPED_DATABASE_SQL_FILE"`
        if [[ $DB_CMD_HAS_PRINT_ARG == true ]]; then
            log $DB_DUMP_COMMAND

            exit 0
        fi

        new_line
        log "Dump Database $DB_CMD_DATABASE to $DB_CMD_DUMPED_DATABASE_SQL_FILE"
        new_line

        eval $DB_DUMP_COMMAND

        if echo "$DB_CMD_COMMAND_WRAPPER" | grep -q "docker"; then
            eval $DB_CMD_DOCKER_CP_COMMAND

            new_line
            log "Move Database $DB_CMD_DUMPED_DATABASE_SQL_FILE to $DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DUMPED_DATABASE_DIR_PATH/${DB_CMD_DUMPED_DATABASE_SQL_FILE_PREFIX}_$(date +%d_%m_%Y-%H_%M_%S).sql"
            new_line

            mv $DB_CMD_CP_DUMP_DB_DESTINATION$DB_CMD_DUMPED_DATABASE_SQL_FILE $DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DUMPED_DATABASE_DIR_PATH/${DB_CMD_DUMPED_DATABASE_SQL_FILE_PREFIX}_$(date +%d_%m_%Y-%H_%M_%S).sql

            return
        fi

        new_line
        log "Move Database $DB_CMD_DUMPED_DATABASE_SQL_FILE to $DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DUMPED_DATABASE_DIR_PATH/${DB_CMD_DUMPED_DATABASE_SQL_FILE_PREFIX}_$(date +%d_%m_%Y-%H_%M_%S).sql"
        new_line

        mv $DB_CMD_DUMPED_DATABASE_SQL_FILE $DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DUMPED_DATABASE_DIR_PATH/${DB_CMD_DUMPED_DATABASE_SQL_FILE_PREFIX}_$(date +%d_%m_%Y-%H_%M_%S).sql

        return
    fi

    local DB_DUMP_COMMAND=`printf "$DB_CMD_COMMAND_WRAPPER" "pg_dump -b -v -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE > $DB_CMD_DUMPED_DATABASE_SQL_FILE"`
    if [[ $DB_CMD_HAS_PRINT_ARG == true ]]; then
        new_line
        log $DB_DUMP_COMMAND
        new_line
    fi

    new_line
    log "Dump Database $DB_CMD_DATABASE to $DB_CMD_DUMPED_DATABASE_SQL_FILE"
    new_line

    eval $DB_DUMP_COMMAND

    if echo "$DB_CMD_COMMAND_WRAPPER" | grep -q "docker"; then
        eval $DB_CMD_DOCKER_CP_COMMAND

        new_line
        log "Move Database $DB_CMD_DUMPED_DATABASE_SQL_FILE to $DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DUMPED_DATABASE_DIR_PATH/${DB_CMD_DUMPED_DATABASE_SQL_FILE_PREFIX}_$(date +%d_%m_%Y-%H_%M_%S).sql"
        new_line

        mv $DB_CMD_CP_DUMP_DB_DESTINATION$DB_CMD_DUMPED_DATABASE_SQL_FILE $DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DUMPED_DATABASE_DIR_PATH/${DB_CMD_DUMPED_DATABASE_SQL_FILE_PREFIX}_$(date +%d_%m_%Y-%H_%M_%S).sql

        return
    fi

    new_line
    log "Move Database $DB_CMD_DUMPED_DATABASE_SQL_FILE to $DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DUMPED_DATABASE_DIR_PATH/${DB_CMD_DUMPED_DATABASE_SQL_FILE_PREFIX}_$(date +%d_%m_%Y-%H_%M_%S).sql"
    new_line

    mv $DB_CMD_DUMPED_DATABASE_SQL_FILE $DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DUMPED_DATABASE_DIR_PATH/${DB_CMD_DUMPED_DATABASE_SQL_FILE_PREFIX}_$(date +%d_%m_%Y-%H_%M_%S).sql

    return
}

dump_schema() {
    local DB_SCHEMA=$1
    DB_CMD_FILE=${DB_SCHEMA}_$(date +%d_%m_%Y-%H_%M_%S).sql
    DB_CMD_DIR_RELATIVE_PATH_FILE=$DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DUMPED_DATABASE_DIR_PATH/$DB_CMD_FILE

    new_line
    log_stars_title "Dump schema $REMOTE_SCHEMA into $DB_CMD_DIR_RELATIVE_PATH_FILE"
    new_line

    mkdir -p $DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DUMPED_DATABASE_DIR_PATH

    eval $(printf "$DB_CMD_COMMAND_WRAPPER_ALT_INTERACTIVE" "pg_dump -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -n $DB_SCHEMA -v > $DB_CMD_DIR_RELATIVE_PATH_FILE")
}

dump_table() {
    local DB_SCHEMA=$1
    local DB_TABLE=$2
    DB_CMD_FILE=$DB_SCHEMA-${DB_TABLE}_$(date +%d_%m_%Y-%H_%M_%S).sql
    DB_CMD_DIR_RELATIVE_PATH_FILE=$DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DUMPED_DATABASE_DIR_PATH/$DB_CMD_FILE

    new_line
    log_stars_title "Dump table $DB_TABLE in schema $DB_SCHEMA into $DB_CMD_DIR_RELATIVE_PATH_FILE"
    new_line

    mkdir -p $DB_CMD_DATABASE_SQL_DIR_PATH/$DB_CMD_DUMPED_DATABASE_DIR_PATH

    eval $(printf "$DB_CMD_COMMAND_WRAPPER_ALT_INTERACTIVE" "pg_dump -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -t ${DB_SCHEMA}.${DB_TABLE} -v > $DB_CMD_DIR_RELATIVE_PATH_FILE")
}

dump_remote_schema() {
    local REMOTE_SCHEMA=$1
    DB_CMD_REMOTE_FILE=${REMOTE_SCHEMA}_$(date +%d_%m_%Y-%H_%M_%S).sql
    DB_CMD_REMOTE_DIR_RELATIVE_PATH_FILE=$DB_CMD_REMOTE_DIR_RELATIVE_PATH/$DB_CMD_REMOTE_FILE

    new_line
    log_stars_title "Dump remote schema $REMOTE_SCHEMA into $DB_CMD_REMOTE_DIR_RELATIVE_PATH_FILE"
    new_line

    mkdir -p $DB_CMD_REMOTE_DIR_RELATIVE_PATH

    export PG_DUMP_CMD=$(printf "$DB_CMD_COMMAND_WRAPPER_ALT_INTERACTIVE" "pg_dump -h $DB_CMD_REMOTE_HOST -U $DB_CMD_REMOTE_USERNAME -d $DB_CMD_REMOTE_DATABASE -n $REMOTE_SCHEMA -v > $DB_CMD_REMOTE_DIR_RELATIVE_PATH_FILE")

    remote_auto_authenticate "$PG_DUMP_CMD" "Password*" $DB_CMD_REMOTE_PASSWORD

    unset PG_DUMP_CMD
}

dump_remote_table() {
    local REMOTE_SCHEMA=$1
    local REMOTE_TABLE=$2
    DB_CMD_REMOTE_FILE=$REMOTE_SCHEMA-${REMOTE_TABLE}_$(date +%d_%m_%Y-%H_%M_%S).sql
    DB_CMD_REMOTE_DIR_RELATIVE_PATH_FILE=$DB_CMD_REMOTE_DIR_RELATIVE_PATH/$DB_CMD_REMOTE_FILE

    new_line
    log_stars_title "Dump remote table $REMOTE_TABLE in schema $REMOTE_SCHEMA into $DB_CMD_REMOTE_DIR_RELATIVE_PATH_FILE"
    new_line

    mkdir -p $DB_CMD_REMOTE_DIR_RELATIVE_PATH

    export PG_DUMP_CMD=$(printf "$DB_CMD_COMMAND_WRAPPER_ALT_INTERACTIVE" "pg_dump -h $DB_CMD_REMOTE_HOST -U $DB_CMD_REMOTE_USERNAME -d $DB_CMD_REMOTE_DATABASE -t ${REMOTE_SCHEMA}.${REMOTE_TABLE} -v > $DB_CMD_REMOTE_DIR_RELATIVE_PATH_FILE")

    remote_auto_authenticate "$PG_DUMP_CMD" "Password*" $DB_CMD_REMOTE_PASSWORD

    unset PG_DUMP_CMD
}

remote_auto_authenticate() {
    export COMMAND=$1
    export EXPECT_REGEX=$2
    export REMOTE_PASSWORD=$3

    # Create the expect script
    cat << 'EOF' > automation.exp
#!/usr/bin/expect -f

set COMMAND $env(COMMAND)
set EXPECT_REGEX $env(EXPECT_REGEX)
set REMOTE_PASSWORD $env(REMOTE_PASSWORD)

set timeout -1

spawn sh -c "$COMMAND"

expect -re "$EXPECT_REGEX" { send -- "$REMOTE_PASSWORD\r" }

expect eof
EOF

    # Make the expect script executable
    chmod +x automation.exp

    # Run the expect script
    ./automation.exp

    # Clean up
    rm automation.exp

    unset COMMAND
    unset EXPECT_REGEX
    unset REMOTE_PASSWORD
}

db_run_query() {
    local QUERY=$1

    db_cmd_defaults

    new_line
    log_stars_title "Run query: $QUERY"
    new_line

    if [[ $DB_CMD_HAS_STAGING_ARG == true ]]; then
        DB_CMD_DATABASE="$DB_CMD_DATABASE_STAGING"
    fi
    
    eval $(printf "$DB_CMD_COMMAND_WRAPPER_ALT" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -c \"$QUERY\"")
}

db_pre_process() {
    db_cmd_defaults

    handle_arguments
}

db_process() {
    if [[ $DB_CMD_HAS_IMPORT_ARG == true ]]; then
        import

        return
    fi

    if [[ $DB_CMD_HAS_IMPORT_SCHEMA_ARG == true ]]; then
        DB_SCHEMA_FILE="$DB_SCHEMA.sql"
        DB_CMD_DATABASE_SQL_DIR_PATH_FILE="$DB_CMD_DATABASE_SQL_DIR_PATH/$DB_SCHEMA_FILE"

        import_schema $DB_SCHEMA $DB_SCHEMA_FILE $DB_CMD_DATABASE_SQL_DIR_PATH_FILE

        return
    fi

    if [[ $DB_CMD_HAS_IMPORT_TABLE_ARG == true ]]; then
        DB_TABLE_FILE="$DB_SCHEMA-$DB_TABLE.sql"
        DB_CMD_DATABASE_SQL_DIR_PATH_FILE="$DB_CMD_DATABASE_SQL_DIR_PATH/$DB_TABLE_FILE"

        import_table $DB_TABLE $DB_SCHEMA $DB_TABLE_FILE $DB_CMD_DATABASE_SQL_DIR_PATH_FILE

        return
    fi

    if [[ $DB_CMD_HAS_IMPORT_REMOTE_SCHEMA_ARG == true ]]; then
        import_remote_schema $REMOTE_SCHEMA

        return
    fi

    if [[ $DB_CMD_HAS_IMPORT_REMOTE_TABLE_ARG == true ]]; then
        import_remote_table $REMOTE_SCHEMA $REMOTE_TABLE

        return
    fi

    if [[ $DB_CMD_HAS_DUMP_ARG == true ]]; then
        dump

        return
    fi

    if [[ $DB_CMD_HAS_DUMP_INCLUDE_SCHEMAS_ARG == true ]] || [[ $DB_CMD_HAS_DUMP_EXCLUDE_SCHEMAS_ARG == true ]]; then
        dump true

        return
    fi

    if [[ $DB_CMD_HAS_DUMP_SCHEMA_ARG == true ]]; then
        dump_schema $DB_SCHEMA

        return
    fi

    if [[ $DB_CMD_HAS_DUMP_TABLE_ARG == true ]]; then
        dump_table $DB_SCHEMA $DB_TABLE

        return
    fi

    if [[ $DB_CMD_HAS_DUMP_REMOTE_SCHEMA_ARG == true ]]; then
        dump_remote_schema $REMOTE_SCHEMA

        return
    fi

    if [[ $DB_CMD_HAS_DUMP_REMOTE_TABLE_ARG == true ]]; then
        dump_remote_table $REMOTE_SCHEMA $REMOTE_TABLE

        return
    fi

    if [[ $DB_CMD_HAS_LIST_SCHEMAS_ARG == true ]]; then
        list_schemas

        return
    fi

    if [[ $DB_CMD_HAS_LIST_REMOTE_SCHEMAS_ARG == true ]]; then
        list_remote_schemas

        return
    fi

    log -e "\e[1;31mERROR: No arguments passed. \033[0m"

    exit 1
}
