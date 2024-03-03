#!/bin/bash

# Specify the database name
ILS_OKAPI_USERNAME="okapi"
USERNAME="folio_admin"
DATABASE="okapi_modules_ils"
DATABASE_SQL_FILE="okapi.sql"                                           # sql file name located inside the DATABASE_SQL_PATH directory declared below.
DATABASE_SQL_PATH="modules/db/$DATABASE_SQL_FILE"                       # sql file relative path to this script's directory.
CONTAINER="postgres-folio"                                              # service container name found in the `docker-compose.yml` file
COMMAND_WRAPPER="sudo docker exec $CONTAINER /bin/bash -c \"%s\" \n"    # if you use postgres on your local machine directly, replace this with "%s"

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
