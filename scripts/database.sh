#!/bin/bash

defaults() {
    # Specify the database name
    ILS_OKAPI_USERNAME="okapi"
    USERNAME="folio_admin"
    DATABASE_STAGING="okapi_modules_ils"
    DATABASE="okapi_modules"
    DATABASE_SQL_FILE="okapi.sql"                                           # sql file name located inside the DATABASE_SQL_PATH directory declared below.
    DUMPED_DATABASE_SQL_FILE="dumped_okapi.sql"                             # dumped sql file name.
    DATABASE_SQL_PATH="modules/db/$DATABASE_SQL_FILE"                       # sql file relative path to this script's directory.
    CONTAINER="postgres-folio"                                              # service container name found in the `docker-compose.yml` file
    COMMAND_WRAPPER="sudo docker exec $CONTAINER /bin/bash -c \"%s\" \n"    # if you use postgres on your local machine directly, replace this with "%s"
    CP_DUMP_DB_SOURCE="/$DUMPED_DATABASE_SQL_FILE"
    CP_DUMP_DB_DESTINATION="."
    DOCKER_CP_COMMAND="sudo docker cp $CONTAINER:$CP_DUMP_DB_SOURCE $CP_DUMP_DB_DESTINATION"
	SCHEMAS_PATH="scripts/schemas.txt"
    PGDUMP_INCLUDE_SCHEMA_OPTION="-n"
    PGDUMP_EXCLUDE_SCHEMA_OPTION="-N"
    PGDUMP_SCHEMA_OPTION="$PGDUMP_INCLUDE_SCHEMA_OPTION"
}

trim() {
    TO_BE_TRIMMED=$1

    # Trim leading spaces
    TRIMMED="${TO_BE_TRIMMED#"${TO_BE_TRIMMED%%[![:space:]]*}"}"

    # Trim trailing spaces
    TRIMMED="${TRIMMED%"${TRIMMED##*[![:space:]]}"}"
}

has_arg() {
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

    ARGS=""
    for ARG in "$@"; do
        if [[ "$ARG" == "$TO_BE_FOUND_ARG" ]]; then
            continue
        fi

        ARGS="$ARGS $ARG"
    done
}

generate_schemas_substring() {
    SCHEMAS_PATTERN=""

    # Check if the file exists
    if ! [ -e "$SCHEMAS_PATH" ]; then
        echo -e "\e[1;31mERROR: File $SCHEMAS_PATH not found. \033[0m"

        exit 1
    fi

    IFS=$'\n'
    for LINE in $(cat $SCHEMAS_PATH); do
        SCHEMAS_PATTERN="$SCHEMAS_PATTERN $PGDUMP_SCHEMA_OPTION $LINE"
    done

    trim $SCHEMAS_PATTERN
    SCHEMAS_PATTERN="$TRIMMED"
}

list_schemas() {
    eval $(printf "$COMMAND_WRAPPER" "psql -U $USERNAME -d $DATABASE -c \\\"\\dn\\\"")
}

handle_arguments() {    
    has_arg "staging" $ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        HAS_STAGING_ARG=true
        DATABASE="$DATABASE_STAGING"
        remove_one_from_arguments "staging" $ARGS
	fi

    has_arg "print" $ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        HAS_PRINT_ARG=true
        remove_one_from_arguments "print" $ARGS
	fi

    has_arg "import" $ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        HAS_IMPORT_ARG=true
	fi

    has_arg "dump" $ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        HAS_DUMP_ARG=true
	fi

    has_arg "dump-include-schemas" $ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        HAS_DUMP_INCLUDE_SCHEMAS_ARG=true
	fi

    has_arg "dump-exclude-schemas" $ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        PGDUMP_SCHEMA_OPTION="$PGDUMP_EXCLUDE_SCHEMA_OPTION"
        HAS_DUMP_EXCLUDE_SCHEMAS_ARG=true
	fi

    has_arg "list-schemas" $ARGS
	FOUND=$?
	if [[ "$FOUND" -eq 1 ]]; then
        HAS_LIST_SCHEMAS_ARG=true
	fi
}

import() {
    # Check if the database already exists
    if eval $(printf "$COMMAND_WRAPPER" "psql -U $USERNAME -lqt | cut -d \| -f 1 | grep -qw $DATABASE"); then
        echo "Database $DATABASE already exists. Dropping it."

        eval $(printf "$COMMAND_WRAPPER" "dropdb -U $USERNAME --if-exists $DATABASE")
    fi

    if eval $(printf "$COMMAND_WRAPPER" "psql -U $USERNAME -lqt | cut -d \| -f 1 | grep -qw $DATABASE"); then
        echo "Failed Dropping Database $DATABASE"

        exit 1
    fi

    # Create the database
    eval $(printf "$COMMAND_WRAPPER" "createdb -U $USERNAME $DATABASE")
    echo "Database $DATABASE created successfully."

    if [[ $(eval $(printf "$COMMAND_WRAPPER" "if [ -f $DATABASE_SQL_FILE ]; then echo true; else echo false; fi")) == true ]]; then
        echo "Remove old $DATABASE_SQL_FILE file."
        eval $(printf "$COMMAND_WRAPPER" "rm $DATABASE_SQL_FILE")
    fi

    # Copy SQL file to Docker container
    echo "Copy $DATABASE_SQL_FILE to $CONTAINER container"
    sudo docker cp $DATABASE_SQL_PATH $CONTAINER:/

    if [[ $(eval $(printf "$COMMAND_WRAPPER" "if [ -f $DATABASE_SQL_FILE ]; then echo true; else echo false; fi")) == false ]]; then
        echo "Failed to copy $DATABASE_SQL_FILE file."

        exit 1
    fi

    # NOTE: we will not use this snippet and we will replace the role name used inside the sql file with existing role instead
    # # Create new role
    # if ! [[ $(eval $(printf "$COMMAND_WRAPPER" "psql -U $USERNAME -d $DATABASE -tAc \\\"SELECT 1 FROM pg_roles WHERE rolname='$ILS_OKAPI_USERNAME'\\\"")) == 1 ]]; then
    #     eval $(printf "$COMMAND_WRAPPER" "psql -U $USERNAME -d $DATABASE -c "CREATE ROLE $ILS_OKAPI_USERNAME WITH LOGIN; GRANT $USERNAME TO $ILS_OKAPI_USERNAME;")
    # fi

    echo "Replace OWNER $ILS_OKAPI_USERNAME to $USERNAME in $DATABASE_SQL_FILE file."
    eval $(printf "$COMMAND_WRAPPER" "sed -i 's/Owner: $ILS_OKAPI_USERNAME/Owner: $USERNAME/g' $DATABASE_SQL_FILE")
    eval $(printf "$COMMAND_WRAPPER" "sed -i 's/OWNER TO $ILS_OKAPI_USERNAME/OWNER TO $USERNAME/g' $DATABASE_SQL_FILE")

    echo "Dump $DATABASE_SQL_FILE into $DATABASE database"
    eval $(printf "$COMMAND_WRAPPER" "psql -U $USERNAME -d $DATABASE -f $DATABASE_SQL_FILE")
}

dump_db() {
    local WITH_SCHEMAS=$1

    if [[ $WITH_SCHEMAS == true ]]; then

        generate_schemas_substring

        local DB_DUMP_COMMAND=`printf "$COMMAND_WRAPPER" "pg_dump -b -v -U $USERNAME -d $DATABASE $SCHEMAS_PATTERN > $DUMPED_DATABASE_SQL_FILE"`
        if [[ $HAS_PRINT_ARG == true ]]; then
            echo $DB_DUMP_COMMAND

            exit 0
        fi

        echo "Dump Database $DATABASE to $DUMPED_DATABASE_SQL_FILE"
        eval $($DB_DUMP_COMMAND)

        if echo "$COMMAND_WRAPPER" | grep -q "docker"; then
            eval $DOCKER_CP_COMMAND
        fi

        return
    fi

    local DB_DUMP_COMMAND=`printf "$COMMAND_WRAPPER" "pg_dump -b -v -U $USERNAME -d $DATABASE > $DUMPED_DATABASE_SQL_FILE"`
    if [[ $HAS_PRINT_ARG == true ]]; then
        echo $DB_DUMP_COMMAND

        exit 0
    fi

    echo "Dump Database $DATABASE to $DUMPED_DATABASE_SQL_FILE"
    eval $DB_DUMP_COMMAND

    if echo "$COMMAND_WRAPPER" | grep -q "docker"; then
        eval $DOCKER_CP_COMMAND
    fi
}

pre_process() {
    defaults

    handle_arguments
}

process() {
    if [[ $HAS_IMPORT_ARG == true ]]; then
        import

        return
    fi

    if [[ $HAS_DUMP_ARG == true ]]; then
        dump_db

        return
    fi

    if [[ $HAS_DUMP_ARG == true ]]; then
        dump_db

        return
    fi

    if [[ $HAS_DUMP_INCLUDE_SCHEMAS_ARG == true ]] || [[ $HAS_DUMP_EXCLUDE_SCHEMAS_ARG == true ]]; then
        dump_db true

        return
    fi

    if [[ $HAS_LIST_SCHEMAS_ARG == true ]]; then
        list_schemas

        return
    fi

    echo -e "\e[1;31mERROR: No arguments passed. \033[0m"

    exit 1
}

ARGS=$*
pre_process

process
