#!/bin/bash

# enable aliases to work in bash script
shopt -s expand_aliases

if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

if [ -f ~/.bash_aliases ]; then
    source ~/.bash_aliases
fi

install() {
    local FOLIO_DIR=$1
    local ALIASES_FILE_PATH=$2
    local ARGUMENT=$3

    # copy template and example files and remove the suffixes
    echo -e
    echo -e "Make config files ready by removing suffixes like '_template', or '.example'"
    echo -e

    cp .env.example .env
    cp modules/modules_template.json modules/modules.json
    cp modules/configuration_template.json modules/configuration.json

    # Replace </path/to/repo> with the current working directory
    echo -e
    echo -e "Replace </path/to/repo> with your FOLIO directory $FOLIO_DIR"
    echo -e

    sed -i "s|</path/to/repo>|$CURRENT_DIR|g" "$ALIASES_FILE_PATH"

    # import the aliases
    echo -e
    echo -e "Import aliases to .bashrc/.bash_aliases"
    echo -e

    ./run.sh import-aliases

    # refresh the bashrc source
    echo -e
    echo -e "Refresh your terminal bash source to work with aliases right a way"
    echo -e

    if [ -f ~/.bashrc ]; then
        source ~/.bashrc
    fi

    if [ -f ~/.bash_aliases ]; then
        source ~/.bash_aliases
    fi

    if [[ $ARGUMENT != "with-start" ]]; then
        return
    fi

    # start docker compose basic services needed for sample modules (postgres, kafka, zookeeper)
    echo -e
    echo -e "Start services needed for the sample modules (postgres, kafka, zookeeper)"
    echo -e

    folioup postgres kafka zookeeper

    # start running folio with sample modules
    echo -e
    echo -e "Start running folio with sample modules"
    echo -e

    folio start
}

CURRENT_DIR=$(pwd)
install "$CURRENT_DIR" "resources/aliases.txt" $1