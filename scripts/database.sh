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

db_cmd_defaults() {
    # Specify the database name
    DB_CMD_DOCKER_CMD="sudo docker"
    DB_CMD_ILS_OKAPI_DB_CMD_USERNAME="okapi"
    DB_CMD_USERNAME="folio_admin"
    DB_CMD_DATABASE_STAGING="okapi_modules_ils"
    DB_CMD_DATABASE="okapi_modules"
    DB_CMD_DATABASE_SQL_FILE="okapi.sql"                            # sql file name located inside the DB_CMD_DATABASE_SQL_PATH directory declared below.
    DB_CMD_DUMPED_DATABASE_SQL_FILE="dumped_okapi.sql"              # dumped sql file name.
    DB_CMD_DATABASE_SQL_PATH="modules/db/$DB_CMD_DATABASE_SQL_FILE" # sql file relative path to this script's directory.
    DB_CMD_CONTAINER="postgres-folio"                               # service container name found in the `docker-compose.yml` file
    DB_CMD_COMMAND_WRAPPER="$DB_CMD_DOCKER_CMD exec $DB_CMD_CONTAINER /bin/bash -c \"%s\" \n"    # if you use postgres on your local machine directly, replace this with "%s"
    DB_CMD_CP_DUMP_DB_SOURCE="/$DB_CMD_DUMPED_DATABASE_SQL_FILE"
    DB_CMD_CP_DUMP_DB_DESTINATION="."
    DB_CMD_DOCKER_CP_COMMAND="$DB_CMD_DOCKER_CMD cp $DB_CMD_CONTAINER:$DB_CMD_CP_DUMP_DB_SOURCE $DB_CMD_CP_DUMP_DB_DESTINATION"
	DB_CMD_SCHEMAS_PATH="scripts/schemas.txt"
    DB_CMD_PGDUMP_INCLUDE_SCHEMA_OPTION="-n"
    DB_CMD_PGDUMP_EXCLUDE_SCHEMA_OPTION="-N"
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

    if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_CMD_DATABASE_SQL_FILE ]; then echo true; else echo false; fi")) == true ]]; then
        echo "Remove old $DB_CMD_DATABASE_SQL_FILE file."
        eval $(printf "$DB_CMD_COMMAND_WRAPPER" "rm $DB_CMD_DATABASE_SQL_FILE")
    fi

    # Copy SQL file to Docker container
    echo "Copy $DB_CMD_DATABASE_SQL_FILE to $DB_CMD_CONTAINER container"
    sudo docker cp $DB_CMD_DATABASE_SQL_PATH $DB_CMD_CONTAINER:/

    if [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "if [ -f $DB_CMD_DATABASE_SQL_FILE ]; then echo true; else echo false; fi")) == false ]]; then
        echo "Failed to copy $DB_CMD_DATABASE_SQL_FILE file."

        exit 1
    fi

    # NOTE: we will not use this snippet and we will replace the role name used inside the sql file with existing role instead
    # # Create new role
    # if ! [[ $(eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -tAc \\\"SELECT 1 FROM pg_roles WHERE rolname='$DB_CMD_ILS_OKAPI_DB_CMD_USERNAME'\\\"")) == 1 ]]; then
    #     eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -c "CREATE ROLE $DB_CMD_ILS_OKAPI_DB_CMD_USERNAME WITH LOGIN; GRANT $DB_CMD_USERNAME TO $DB_CMD_ILS_OKAPI_DB_CMD_USERNAME;")
    # fi

    echo "Replace OWNER $DB_CMD_ILS_OKAPI_DB_CMD_USERNAME to $DB_CMD_USERNAME in $DB_CMD_DATABASE_SQL_FILE file."
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "sed -i 's/Owner: $DB_CMD_ILS_OKAPI_DB_CMD_USERNAME/Owner: $DB_CMD_USERNAME/g' $DB_CMD_DATABASE_SQL_FILE")
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "sed -i 's/OWNER TO $DB_CMD_ILS_OKAPI_DB_CMD_USERNAME/OWNER TO $DB_CMD_USERNAME/g' $DB_CMD_DATABASE_SQL_FILE")

    echo "Dump $DB_CMD_DATABASE_SQL_FILE into $DB_CMD_DATABASE database"
    eval $(printf "$DB_CMD_COMMAND_WRAPPER" "psql -U $DB_CMD_USERNAME -d $DB_CMD_DATABASE -f $DB_CMD_DATABASE_SQL_FILE")
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

db_process() {
    if [[ $DB_CMD_HAS_IMPORT_ARG == true ]]; then
        import

        return
    fi

    if [[ $DB_CMD_HAS_DUMP_ARG == true ]]; then
        dump_db

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
