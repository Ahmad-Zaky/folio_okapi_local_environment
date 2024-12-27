#!/bin/bash

# copy template and example files and remove the suffixes
cp .env.example .env
cp modules/modules_template.json modules/modules.json
cp modules/configuration_template.json modules/configuration.json

# import the aliases
./run.sh import-aliases

# refresh the bashrc source
source ~/.bashrc