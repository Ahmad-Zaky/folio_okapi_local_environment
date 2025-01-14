<a id="readme-top"></a>

<!-- PROJECT SHIELDS -->
<!--
*** I'm using markdown "reference style" links for readability.
*** Reference links are enclosed in brackets [ ] instead of parentheses ( ).
*** See the bottom of this document for the declaration of the reference variables
*** for contributors-url, forks-url, etc. This is an optional, concise syntax you may use.
*** https://www.markdownguide.org/basic-syntax/#reference-style-links
-->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![Unlicense License][license-shield]][license-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

# FOLIO Local Environment

<!-- TABLE OF CONTENTS -->
  ## Table of Contents
  <ol>
    <li><a href="#about-the-project">About The Project</a></li>
    <li><a href="#youtube-playlist">Youtube Playlist</a></li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li>
        <a href="#guide">Guide</a>
        <ul>
            <li><a href="#general-practicing-notes">General Practicing Notes</a></li>
            <li>
                <a href="#file-structure">File Structure</a>
                <ul>
                    <li><a href="#base-repo-structure">Base Repo Structure</a></li>
                    <li><a href="#script-files-structure">Script Files Structure</a></li>
                    <li><a href="#untracked-files">Untracked files</a></li>
                </ul>
            </li>
            <li>
                <a href="#module-components">Module Components</a>
                <ul>
                    <li><a href="#base-component">Base component</a></li>
                    <li><a href="#env-component">Environment component</a></li>
                    <li><a href="#okapi-component">Okapi component</a></li>
                    <li><a href="#postman-component">Postman component</a></li>
                    <li><a href="#install-params-component">Install (enable) params component</a></li>
                </ul>
            </li>
            <li>
                <a href="#configuration-components">Configuration Components</a>
                <ul>
                    <li><a href="#database-configuration">Database Configuration</a></li>
                    <li><a href="#database-operations-configuration">Database Operations Configuration</a></li>
                    <li><a href="#kafka-configuration">Kafka Configuration</a></li>
                    <li><a href="#elastic-configuration">Elastic Configuration</a></li>
                    <li><a href="#okapi-configuration">Okapi Configuration</a></li>
                    <li><a href="#modules-configuration">Modules Configuration</a></li>
                    <li><a href="#tenant-configuration">Tenant Configuration</a></li>
                    <li><a href="#user-configuration">User Configuration</a></li>
                    <li><a href="#docker-configuration">Docker Configuration</a></li>
                    <li><a href="#postman-configuration">Postman Configuration</a></li>
                </ul>
            </li>
      </ul>
    </li>
    <li>
        <a href="#usage">Usage</a>
        <ul>
            <li>
                <a href="#folio-commands">Folio Commands</a>
                <ul>
                    <li><a href="#group-1---helpers">Group #1 - helpers</a></li>
                    <li><a href="#group-2---starters">Group #2 - starters</a></li>
                    <li><a href="#group-3---stoppers">Group #3 - stoppers</a></li>
                    <li><a href="#group-4---db">Group #4 - db</a></li>
                </ul>
            </li>
            <li><a href="#folio-examples">Folio Examples</a></li>
            <li><a href="#module-dependencies-examples">Module dependencies examples</a></li>
        </ul>
    </li>
    <li><a href="#todos">TODOs</a></li>
    <li><a href="#contributing">Contributing</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>

<!-- ABOUT THE PROJECT -->
## About The Project  

This project is an advanced automated script designed to spin up a `FOLIO` microservice project in your local environment.  

The FOLIO project includes an `API Gateway` called `Okapi`. The main goal of this script is to automate the process of setting up a local `Okapi` instance and running the necessary modules under this instance. For more details, [click here][1].  

The script originates from `Adam Dickmeiss` ([`adamdickmeiss`][3]) and his [GitHub repository][2], which was initially developed to assist developers in setting up the FOLIO environment locally in an automated manner.  

Currently, the script is in its `Alpha` stage and contains many TODOs. With community contributions, we hope to advance the script further, enabling the broader FOLIO community to use it more effectively and making it easier for developers to set up their local environments quickly and smoothly.

The script is implemented in `bash` which works on `Linux`, and `macOS`, but not on `Windows`, you have some not tested workarounds like [`git bash`][4], [`Cygwin`][5], or [`Windows Subsystem for Linux (WSL)`][6].

Key features:

- Complete automation running okapi and folio modules locally (clone -> build -> register -> deploy -> enable)
- You can clone from different repositories for each module.
- You can perform database operations like dumping and importing databases and schemas and much more.
- Integration wity postman, so you can sync your user_id, token, and much more with your postman environments.
- You have the ability to debug any folio module by running it separately in your IDE like Intilij, more on how to do it in the examples section.
- You can attach your local folio module to run with no local okapi instance like your staging environment, more on how to do it in the examples section.
- you have complete control on each module separately in `modules.json`
- You will preserve the database state on each new run.
- You can tailor the build command for each module separately.
- You can set environment variables for each module separately.
- You have the ability to run the modules in docker containers
- You have the ability to run with or without authentication.
- In case your module has swagger openapi configuration you can import it to `postman` as a Collection.
- ...

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Module Sample from `modules.json`
```json
[
    ...
    {
        "id": "mod-users",
        "tag": "v19.4.4",
        "step": "install",
        "build": "mvn clean install -DskipTests -Dcheckstyle.skip",
        "rebuild": "false",
        "env": [
            {
                "name": "DB_HOST",
                "value": "localhost"
            }
            ...
        ],
        "okapi": {
            "url": "https://folio-snapshot-okapi.dev.folio.org",
            "tenant": "diku",
            "credentials": {
                "username": "diku_admin",
                "password": "admin"
            },
            "enabled": "true"
        },
        "postman": {
            "file": "path/to/swagger.api/users.yaml",
            "api_key": "PMAK-xxxxxxxxxxxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxx",
            "enabled": "true"
        },
        "enabled": "true"
    }
    ...
]
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Youtube Playlist

This playlist is a brief explanation for our repository README.md documenation.

[![Folio Local Environment Playlist][folio_local_environment_yt_img]][folio_local_environment_yt]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

<!-- GETTING STARTED -->
## Getting Started

Here we will focus on cloning the repo, preparing the environment, and staring `Okapi` with at least one folio module.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Prerequisites

The script is utilizing some linux tools, which should be installed before running the script.

* `git` should be locally installed. [click here](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* `java` should be installed locally with `jdk v17`. [click here](https://www.freecodecamp.org/news/how-to-install-java-in-ubuntu/)
* `jq` linux tool to process json files. [click here](https://jqlang.github.io/jq/download/)
* `yq` linux tool to process yml files. [click here](https://github.com/mikefarah/yq)
* `xmllint` linux tool to process xml files. [click here](https://github.com/AtomLinter/linter-xmllint?tab=readme-ov-file#linter-installation)
* `lsof` linux tool to find process by port number. [click here](https://ioflood.com/blog/install-lsof-command-linux/)
* `docker` docker tool to run modules in containers instead of running it on the local host machine. [click here](https://docs.docker.com/engine/install/)
* `netstat` its a linux tool used for displaying network connections, routing tables, interface statistics, masquerade connections, and multicast memberships. However, starting from `Ubuntu 20.04`, netstat is considered **`deprecated`** in favor of the ss command [click here](https://www.tecmint.com/install-netstat-in-linux/).
* `expect` linux tool used to automate control of interactive applications such as Telnet, SSH, and others [click here](https://www.geeksforgeeks.org/expect-command-in-linux-with-examples).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Installation

1. Clone the repository from github.

    ```bash
    git clone https://github.com/Ahmad-Zaky/folio_okapi_local_environment.git folio
    ```

2. Move to the repository directory.

    ```bash
    cd folio
    ```

3. run the `install.sh` command and skip steps 4, 5, and 6.
    - in step #5, `aliases.txt` has `</path/to/repo>` for `cdfolio` alias.
    - the script will auto replace `</path/to/repo>` with your current directory.
    - current directory for `cdfolio` alias is logical correct as you run the `install.sh` from the folio directory.
    - in step #8 the install.sh script will run docker compose services needed for sample modules
        ```bash
        folioup postgres kafka zookeeper
        ```
    - you can add `with-start` argument to continue until last step #9. 
    ```bash
    bash install.sh # skip steps 4, 5, 6
    ```
    
    Or

    ```bash
    bash install.sh with-start # skip all upcoming steps from 4 -> 9
    ```

4. rename *_template.json files:
    - rename `.env.example`, `modules_template.json`, and `configuration_template.json`.
        ```bash
        cp .env.example .env
        cp modules/modules_template.json modules/modules.json
        cp modules/configuration_template.json modules/configuration.json
        ```
    - modules versions in `modules.json` are set to [`ramsons`][15] release.

5. Add your aliases commands which eases running the script:
    - open `./scripts/aliases.txt` file and replace `</path/to/repo>` with your `folio` root path.
    - import aliases to your home `.bash_aliases` file or `.bashrc` file if `.bash_aliases` does not exists, and its recommended to add your aliases in its dedicated file `.bash_aliases`. 
    - run this command to import folio aliases, be aware that you should in the `folio` directory
        ```bash
        ./run.sh import-aliases
        ```
    - Avoid running the command more than once to prevent redundancy.

    ```bash
    # folio
    alias cdfolio='cd </path/to/repo>'
    alias folio='cdfolio && bash run.sh'
    alias folioup='cdfolio && docker compose up -d' # add sudo if your docker does need sudo

    # okapi
    alias cdokapi='cdfolio && cd modules/okapi'
    alias okapilog='cdokapi && tail -f nohup.out'
    ```

6. refresh your bash config file to be able to use folio aliases right away.

    ```bash
    source ~/.bashrc
    ```

7. after renaming *_template, and *.example files review them and replace the values with your own configuration if necessary.

8. Folio depends on some services and tools which are combined in one `docker-compose.yml` file.
    - right now we have these 8 services:
        * **[okapi][7]:** runs okapi instance in docker container, helpful when you run your modules in docker.
        * **[postgres][8]:** database used in folio.
        * **[pgadmin][9]** postgres dashboard tool.
        * **[kafka][10]:** distributed event streaming tool, used in folio modules like `mod-users-bl`
        * **[zookeeper][11]:** distributed coordination service used with okapi to store kafka topics meta data and much more.
        * **[elasticsearch][12]:**  RESTful search and analytics engine used in folio modules like `mod-search`.
        * **[kibana][13]:** elasticsearch monitoring and observability tool.
        * **[minio][14]:** S3 compatible storage service used in modules like `mod-data-import`.
    - basic service you need to start **`postgres`**
        ```bash
        docker compose up --build -d postgres
        ```
        or
        ```bash
        folioup postgres # utilize alias folioup
        ```
    - basic services for modules uses `kafka` like `mod-users-bl` (**`postgres`**, **`kafka`**, **`zookeeper`**)
        ```bash
        docker compose up --build -d postgres kafka zookeeper
        ```
        or
        ```bash
        folioup postgres kafka zookeeper # utilize alias folioup
        ```
    - basic services for modules uses `elasticsearch` like `mod-search` (**`postgres`**, **`elasticsearch`**)
        ```bash
        docker compose up --build -d postgres elasticsearch
        ```
        or
        ```bash
        folioup postgres elasticsearch # utilize alias folioup
        ```
    - basic services for modules uses `minio` like `mod-data-import` (**`postgres`**, **`minio`**)
        ```bash
        docker compose up --build -d postgres minio 
        ```
        or
        ```bash
        folioup postgres minio # utilize alias folioup
        ```
    - in general use only services you need to not bloat your memory.
    - run all services with this command, you only need the `--build` option at the first time.
        ```bash
        docker compose up --build -d
        ```
        of
        ```bash
        folioup # utilize alias folioup
        ```

9. After running your needed services, now you can run the script on the sample modules found in `modules.json`.

    ```bash
    folio start
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Guide

### General Practicing Notes

* Be aware that the script based on `EMPTY_REQUIRES_ARRAY_IN_MODULE_DESCRIPTOR` configuration, if true the `required` array will be cleaned to be empty from the `ModuleDescriptor.json` inside the target directory, so that  `register` and `enable` modules on the local okapi instance succeed.
* All curl requests output are logged in a non tracked file named `output.txt` so if anything goes wrong while running the script you can check the error message in that file.
* Inside `modules.json` order is important, so the modules should be sorted in a way that each dependency module is installed firstly then the modules which depends upon that module.
* While running the script you may encounter messages like this `WARNING: HTTP request failed! (Status Code: xxx)` this is not always a problem, and does not means that the script has failed.
* in case your tag in `modules.json` object is different than what apears in the module `pom.xml` version or `azure-pipelines.yml` tag, script will rebuild the modules.
* in case your tag in `modules.json` object is different than current module branch, the script will rebuild the module.
* To run modules within `docker` container you should change `RUN_WITH_DOCKER` configuration value to `true` and change these configuration keys to values like the following to be able to communicate within `docker` network:
    * `DB_HOST` from `localhost` to `postgres`
    * `KAFKA_HOST` from `localhost` to `kafka`
    * `ELASTICSEARCH_URL` from `http://localhost:9200` to `http://elasticsearch:9200`
    * `ELASTICSEARCH_HOST` from `localhost` to `elasticsearch`
* in case you use your own services instead of our `docker-compose.yml` services then you may have a problem as they will not share the same network any more, so then you need to add host `host.docker.internal` 
    * `DB_HOST` from `localhost` to `host.docker.internal`
    * `KAFKA_HOST` from `localhost` to `host.docker.internal`
    * `ELASTICSEARCH_URL` from `http://localhost:9200` to `http://host.docker.internal:9200`
    * `ELASTICSEARCH_HOST` from `localhost` to `host.docker.internal`
* In some rare cases while running the script, you will have some user permissions issue related to listing users permission `users.collection.get` in that case you should check that database permissions table directly and if you find `dummy` key with value equal to `true` please change it manually to false, and edit user permissions again through api call by adding this `users.collection.get` permission.

* You have a `permissions.json` file located in `resources` directory so if you run modules that require specific permissions for the user to have add them there, and the script will attach them to the user permissions.
* A useful tip in case some modules fail while running the script, you can navigate to that module and manually pull from remote repo the latest changes and rebuild the module and try running the script again.
* before starting okapi the allocated ports will be freed from the host machine for example if the allocated ports START_PORT=9131 to END_PORT=9199 the script will free all these ports before start processing modules, and you can control this action by `ENABLE_FREE_ALLOCATED_PORTS_FOR_OKAPI_MODULES` configuration, if set to `false` the script will skip this action and start processing modules directly, but you should be aware that if there is a port within the range is used by another process the script will fail at the module in turn.
* There is a specific case when you change db configs for `mod-users` while you using `mod-authtoken` there will be an issue as the login attempt will fails, so modules like `mod-authtoken`, `mod-login`, and `mod-users` should share the same db configs here I mean the same database name.
* if you look at the script you may see some unused methods most of them are in `helpers.sh` they were used in earlier scripts, and not removed.
* if you start import a schema or a database locally through the folio script, be sure that the imported schemas are already enabled before through the `modules.json` as there may be missing roles, casts and/or extensions that will eventually prevent the import from succeed, or you can add the missing roles, casts, extensions manually, and then reimport the database/schema sql file again. 
* if your postgres database is running from your own docker service or running directly on your machine, you need to have the db configurations to be changed to match your own db configurations.
* database script works with two databases, your own local and another staging database.
    - the script assumes that they are using the same postgres instance, which means the same connection and database configuration except for the database name.
    - at the beginning both are empty no difference between the two.
    - the purpose of another database with suffix name `_staging`, is to separate between your local data gained while working with your local okapi environment and the data you import from your remote database associated with your development or staging environment.
    - so its good to separate them so if you want to connect to your staging database you can change the connection database name for a specific module to connect to your local staging database.
* in case your `postgres` is running in a docker container you need to review two configurations `DB_CMD_CONTAINER`, and `DB_CMD_PSQL_WITH_DOCKER`
    - `DB_CMD_CONTAINER` should have your container name as a value.
    - `DB_CMD_PSQL_WITH_DOCKER` should be have "true" value.
* running `db` commands with `postgres` not running docker has not been tested, so you may encounter problems, if os create issues on the repo so we can fix it.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### File Structure

#### Base Repo Structure

    .
    ├── db
    │   ├── ...
    │   ├── schemas.txt
    │   └── init.sql
    ├── modules
    │   ├── ...
    │   ├── modules.json
    │   └── configuration.json
    ├── resources
    │   ├── aliases.txt
    │   ├── permissions.json
    │   ├── mod-inventory/.run/Launcher.run.xml
    │   ├── okapi/.run/Launcher.run.xml
    │   └── okapi/deployments.sql
    ├── scripts
    ├── .env
    ├── run.sh
    └── docker-compose.yml

- **db**: its responsible to store all dumped (backup) sql files from our local db, and also used to import (backup) sql files or schema sql files back to our local database.
    - **schemas.txt**: list database postgres schemas to be included/excluded from dumping from our local database.
    - **init.sql**: necessary for `postgres` service located in `docker-compose.yml` to create a new `okapi_modules_staging` database with its extensions.
- **modules**: All modules we work on, are located here, in this directory, starting from first step clone a module until last step install that module.
    - **modules.json**: Its like a manifest for the modules we working on here in our local environment, including okapi.
    - **configuration.json**: All configurable data is configured here through (key -> value) approach starting from database configurations until 3rd party integrations like postman.
- **resources**: All modules we work on, are located here, in this directory, starting from first step clone a module until last step install that module.
    - **aliases.txt**: this is .bashrc/.bash_aliases aliases to help running terminal commands for folio local environment more easy and to feal more like running a tool.
    - **permissions.json**: All user permissions needed to perform your requests and it depends upon which modules you want to run, so you can add your own permissions to the list and it will automatically assign them to the user while running the script.
    - **mod-inventory/.run/Launcher.run.xml**: This is the sample Module `mod-inventory` configuration file, which we did run from the IDE (IntelliJ), so I thought that adding the configuration here for you, will be very helpful to replicate the example with ease.
    - **okapi/.run/Launcher.run.xml**: This is the configuration file for `Okapi`, which we used in our example, when we did run `Okapi` from the IDE (IntelliJ)
    - **okapi/deployments.sql**: This is the deployments added manually to the database, which has been used in the example where we did stop okapi without stopping other modules.
- **scripts**: contains all our bash script files implementation for our `FOLIO` local environment enabler, and also contains the old scripts which we started from at the beginning.
- **.env**: has the env vars for `docker-compose.yml` services.
- **run.sh**: entry point for our folio local environment script, which connects to the script files located in `script` directory.
- **docker-compose.yml**: contains all services needed for folio modules like postgres, kafka, elasticsearch, ... etc.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Script Files Structure
    .
    ├── run.sh
    └── scripts
        ├── preprocess.sh
        ├── process.sh
        ├── postprocess.sh
        ├── validation.sh
        ├── helpers.sh
        ├── database.sh
        └── old
            ├── run.sh
            ├── run_custom_old.sh
            ├── run-mod-settings.sh
            └── run-with-docker.sh

- **run.sh**: our entry point script, which orchestrate the execution flow by sourcing scripts from `scripts` directory.
- **scripts**: contains all all individual scripts for database setup, preprocessing, validation, main processing (clone, build, deploy, etc.), and postprocessing.
    - **preprocess.sh**: handles all pre-process tasks like running okapi, stop old running modules to start clean, and much more.
    - **process.sh**: this is the core script handling `modules.json`, as it loops on each module and apply the steps (clone -> build -> register -> deploy -> enable).
    - **postprocess.sh**: handles all post-process tasks like removing tmp files.
    - **validation.sh**: centralized script to validate the running script from pre-process and process to post-process phases, like validate prerequisite linux tools, validate the `modules.json` list and much more.
    - **helpers.sh**: all reusable scripts are located here, and thats why the file is very big, it includes scripts related to logging, requesting using curl, and much more.
    - **database.sh**: all operations related to the local database like importing/dumping sql files are done here
    - **old**: the old script we did start from and its not used any more.
        - **run.sh**: basic script to run folio local environment, no more used.
        - **run_custom_old.sh**: customized version of `run.sh` and also no more used.
        - **run-mod-settings.sh**: basic script to run mod-settings specific as it requires adding some permissions to the logged in user.
        - **run-with-docker.sh**: basic script to run folio modules like `run.sh` but in docker containers instead of running jar processes.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Untracked Files

    .
    └── modules
        ├── ...
        ├── output.txt
        ├── response.txt
        ├── filtered_modules.json
        └── headers


- **output.txt**: is a place where you find all curl responses and output debug error messages.
- **response.txt**: tmp file catches curl requests response and then read it back into `CURL_RESPONSE` variable.
- **filtered_modules.json**: processing `modules.json` through `process()` has a feature which you can set a list of modules you want to filter out from `modules.json` the result after the filtering process goes to **filtered_modules.json** file and the `process()` reads modules from this file not directly from `modules.json`.
- **headers**: used to catch the curl request headers.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


### Module Components

- We have a json file called `modules.json` where we store metadata about all modules we work with, we will now explain each module metadata key and value with examples.

- Here is a module component contains all possible keys and values, which is not realistic, but we put them all together for the sake of documentation.

    ```json
        {
            "comment": "<some comments ...>",
            "id": "mod-users",
            "repo": "https://github.com/folio-org/mod-users.git",
            "access_token": "<access_token>",
            "tag": "v19.4.2",
            "branch": "main",
            "build": "mvn clean install -DskipTests",
            "rebuild": "false",
            "env": [
                {
                    "name": "DB_HOST",
                    "value": "localhost"
                }
            ],
            "okapi": {
                "url": "https://folio-snapshot-okapi.dev.folio.org",
                "tenant": "diku",
                "credentials": {
                    "username": "diku_admin",
                    "password": "admin"
                },
                "enabled": "true"
            },
            "postman": {
                "file": "path/to/swagger.api/users.yaml",
                "api_key": "PMAK-xxxxxxxxxxxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxx",
                "enabled": "true"
            },
            "install_params": {
                "purge": "false",
                "tenantParameters": {
                    "loadReference": "true",
                    "loadSample": "true"
                },
                "enabled": "true"
            },
            "step": "install",
            "enabled": "true"
        }
    ```

- Lets break this big json object into small components and explain them in details.

- In below declaration, for any key without `default` and has `required` with `NO` value, means that if the key is missing, no default value exists.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Base Component
```json
{
    ...
    "comment": "<some comments ...>",
    "id": "mod-users",
    "repo": "https://github.com/folio-org/mod-users.git",
    "access_token": "<access_token>",
    "tag": "v19.4.2",
    "branch": "main",
    "build": "mvn clean install -DskipTests",
    "rebuild": "false",
    "step": "install",
    "enabled": "true"
    ...
}
```

- **"comment"**   
    - this key does what it says its just a comment like any comment you as a developer add in your code base.
    - it has no affect at all.
    - noteabley any key that is not listed here will act also like `comment` key, so you actually you can add any key you wish and it will not take any affect as long as its not one of the keys listed here in the documentation.
 
    - **example:** `"return develop branch back when you finished"`, I actually use this kind of comments a lot when I work on a feature branch, and I need to revert back after finishing my feature implementation.
    - **required:** **NO**

- **"id"**
    - represents the module name and its used in different places
    - clone a module using default repo value, will take the id as repository name and append it into the clone repo command.
    - each module directory name will be the same `id` value which is obvious as we clone using the `id`.
    - duplicate `id` values in `moduels.json` does not raise any errors, it will be just redundant operation, and you all the steps will not be applied again, so if it was deployed once it will not get deployed again.
    - **example:** `mod-users`
    - **required:** **YES**

- **"repo"**
    - has the repository url could be either https or ssh version.
    - **example:** `https://github.com/folio-org/mod-users.git`
    - **default:** will be declared in `configuration.json` file
    - **required:** **NO**

- **"access_token"**
    - if you decide to use `https` repo clone url version then you may need to add credentials for authentication if its not cached locally, in that case you can just generate an `access_token` from your repo host like `github` and use it here to be able to clone/pull a repo without problems.
    - **required:** **NO**

- **"tag"**
    - specify the tag version when you clone the module at first step, and also validates it with current existing tag, so that if its different the script will auto-checkout to the tag specified here and rebuild the module again.
    - **example:** `v19.4.2`
    - **required:** **NO**

- **"branch"**
    - specify the branch you want to land on while cloning the module at first step, and like `tag` it validates it with current existing branch of the module and if they differ, the script will auto-checkout the specified branch here and rebuild the module.
    - if both `branch` and `tag` were specified in one module metadata, an error will raise up, states that you can not have both `tag` and `branch` in the same module metadata.
    - **example:** `develop`
    - **required:** **NO**

- **"build"**
    - command used to build your module, and this command will overwrite the default build command.
    - **example:** `mvn clean install -DskipTests`
    - **default:** will be declared in `configuration.json` file
    - **required:** **NO**

- **"rebuild"**
    - In case you want to rebuild module on each run, you can add this key with value `true`. 
    - **default:** `false`
    - **example:** `true`
    - **required:** **NO**

- **"step"**
    - each module has 5 steps in order as following.
        1. `clone`: clone the module from your host repository into your local machine.
        2. `build`: build the module to be ready for running.
        3. `register`: register the module in your local okapi instance.
        4. `deploy`: deploy (run) the module in your local okapi instance.
        5. `install (enable)`: install or enable your module to a specific `tenant` also within your local okapi instance.
    - for example, if you put value `deploy` for the key `step` that means, the module will go through all steps until `deploy` step in this order (`clone` -> `build` -> `register` -> `deploy`) and stops there.
    - **example:**  `enable`
    - **default:** if this key is missing the module will pass and be valid for all steps (`clone`, `build`, `register`, `deploy`, `install`)
    - **required:** **NO**

- **"enabled"**
    - it gives you the control where you consider this module while running the script or not, so if you want to skip a specific module you simply add value `false` to that module.
    - **example:** `true`
    - **default:** `true`
    - **required:** **NO**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Env Component
```json
{
    ...
    "env": [
        {
            "name": "DB_HOST",
            "value": "localhost"
        }
    ]
    ...
}
```

- **"env"**
    - here we will have all environment variables you want to export for that module at `deploy` step where you will run the module.
    - **required:** **NO**

- **"env.name"**
    - represent the environment variable name for the module it was declared in.
    - **example:** `DB_HOST`
    - **required:** **YES**

- **"env.value"**
    - represent the environment variable value for the module it was declared in.
    - **example:** `localhost`
    - **required:** **YES**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Okapi Component
```json
{
    ...
    "okapi": {
        "url": "https://folio-snapshot-okapi.dev.folio.org",
        "tenant": "diku",
        "credentials": {
            "username": "diku_admin",
            "password": "admin"
        },
        "enabled": "true"
    }
    ...
}
```

- **"okapi"**
    - some how you have the ability to run your modules not on local okapi instance instead on a remote okapi instance, like if you want to run only one module and debug a specific API without the need to spin up all modules needed for that API request.
    - **required:** **NO**

- **"okapi.url"**
    - here we specify the remote okapi instance url.
    - **example:** `https://folio-snapshot-okapi.dev.folio.org`
    - **required:** **YES**

- **"okapi.tenant"**
    - here we specify the remote okapi instance tenant which will be used in `X-Okapi-Tenant` header.
    - **example:** `diku`
    - **required:** **YES**

- **"okapi.credentials"**
    - for login we should have credentials to authenticate into the remote okapi instance.
    - **required:** **YES**


- **"okapi.credentials.username"**
    - a valid username for the remote okapi instance credentials.
    - **example:** `diku_admin`
    - **required:** **YES**

- **"okapi.credentials.password"**
    - a valid password for the remote okapi instance credentials.
    - **example:** `admin`
    - **required:** **YES**

- **"okapi.enabled"**
    - here you have the ability to enable or disable the `okapi` component.
    - **example:** `true`
    - **default:** `true`
    - **required:** **NO**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Postman Component
```json
{
    ...
    "postman": {
        "file": "path/to/swagger.api/users.yaml",
        "api_key": "PMAK-xxxxxxxxxxxxxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxxxxx",
        "enabled": "true"
    }
    ...
}
```

- **"postman"**
    - you can auto-import your postman collection in case you have it existing in your module directory, and its also valid for swagger open api `.yml` files.
    - you should consider enable this component only at first time, as it does not validate if the collection has been added previously to your workspace or not, it will just duplicate it again.
    - **required:** **NO**

- **"postman.file"**
    - path to your collection or swagger open api file.
    - **example:** `path/to/swagger.api/users.yaml`
    - **required:** **YES**

- **"postman.api_key"**
    - used to authenticate the postman integration API request, so you can import your collection.
    - **required:** **YES**

- **"postman.enabled"**
    - here you have the ability to enable or disable the `postman` component.
    - **example:** `true`
    - **default:** `true`
    - **required:** **YES**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Install Params Component

```json
{
    ...
    "install_params": {
        "purge": "false",
        "tenantParameters": {
            "loadReference": "true",
            "loadSample": "true"
        },
        "enabled": "true"
    }
    ...
}
```

- **"install_params"**
    - this component is more related to `enable` step where it will be transformed into query parameters added to the API request that performs the `enable` action.
    - there are more parameters than what we use here like `preRelease`, and `invoke` parameters.
    - for more details you can check [okapi guide][okapi_guide].
    - **required:** **NO**

- **"install_params.tenantParameters"**
    - A module may, besides doing the fundamental initialization of storage etc. also load sets of reference data. This can be controlled by supplying tenant parameters.
    - for more details [check here][purge_parameter_docs].
    - **required:** **NO**

- **"install_params.purge"**
    - instructs a module to purge (remove) all persistent data. This only has an effect on modules that are also disabled.
    - **example:** `true`
    - **default:** `false`
    - **required:** **NO**

- **"install_params.tenantParameters.loadReference"**
    - `loadReference` with value `true` loads reference data.
    - **example:** `true`
    - **default:** `false`
    - **required:** **NO**

- **"install_params.tenantParameters.loadSample"**
    - `loadSample` with value `true` loads sample data.
    - **example:** `true`
    - **default:** `false`
    - **required:** **NO**

- **"install_params.enabled"**
    - here you have the ability to enable or disable the `install_params` component.
    - **example:** `true`
    - **default:** `true`
    - **required:** **NO**

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Configuration Components

- These configuration are essentially for the script to run peroperly, so you should not remove any of these configurations.
- **default** value means the value it has in the `configuration_template.json` version after cloning.

#### Database Configuration
- here we have all database configuration.

- **"DB_HOST"**
    - **default:** `localhost`

- **"DB_PORT"**
    - **default:** `5432`

- **"DB_DATABASE"**
    - **default:** `okapi_modules`

- **"DB_USERNAME"**
    - **default:** `folio_admin`

- **"DB_PASSWORD"**
    - **default:** `folio_admin`

- **"DB_QUERYTIMEOUT"**
    - **default:** `60000`

- **"DB_MAXPOOLSIZE"**
    - **default:** `5`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Database Operations Configuration
- database operations are a little isolated from the rest of the script in `database.sh` file, so its configurations are separate from script database configurations.
- **"DB_CMD_DOCKER_CMD"**
    - docker command used, you can add `sudo` like this `sudo docker` in case your docker runs in root.
    - **default:** `docker`

- **"DB_CMD_STAGING_OKAPI_USERNAME"**
    - on staging sometimes the username is different than local database username so on importing from staging I replace all staging username occurances in the sql file with the local db username.
    - this configuration sets the staging username value.
    - **default:** `okapi`

- **"DB_CMD_USERNAME"**
    - local database username.
    - **default:** `folio_admin`

- **"DB_CMD_DATABASE_STAGING"**
    - local staging database where I import staging schemas to not interfer with local `okapi_modules` database schemas.
    - **default:** `okapi_modules_staging`

- **"DB_CMD_DATABASE"**
    - local database name.
    - **default:** `okapi_modules`

- **"DB_CMD_REMOTE_HOST"**
    - remote database host may be your development/staging database.
    - you need to change the default value `localhost` to your remote host which is mostly a network IP.
    - **default:** `localhost`

- **"DB_CMD_REMOTE_USERNAME"**
    - remote database username may be your development/staging database.
    - you need to change the default value `folio_admin` to your remote username.
    - **default:** `folio_admin`

- **"DB_CMD_REMOTE_PASSWORD"**
    - remote database password may be your development/staging database.
    - you need to change the default value `folio_admin` to your remote password.
    - **default:** `folio_admin`

- **"DB_CMD_REMOTE_DATABASE"**
    - remote database password may be your development/staging database.
    - you need to change the default value `okapi_modules` to your remote database name.
    - **default:** `okapi_modules`

- **"DB_CMD_REMOTE_DIR_PATH"**
    - this is the sub directory inside `db/` where all remote sql files will be downloaded.
    - **default:** `remote`

- **"DB_CMD_DATABASE_SQL_FILE"**
    - sql file name which will be imported in your local database.
    - **default:** `okapi.sql`

- **"DB_CMD_DUMPED_DATABASE_SQL_FILE"**
    - sql file name of the local dumped databse.
    - **default:** `dumped_okapi.sql`

- **"DB_CMD_DUMPED_DATABASE_SQL_FILE_PREFIX"**
    - sql file name prefix and usually the suffix will be a timestamp for the local dumped databse file name.
    - **default:** `dumped_okapi.sql`

- **"DB_CMD_DUMPED_DATABASE_DIR_PATH"**
    - sql directory name ofor local dumped databses.
    - **default:** `dumped_okapi.sql`

- **"DB_CMD_DATABASE_SQL_DIR_PATH"**
    - path where you should place the staging sql file to be imported.
    - **default:** `../db`

- **"DB_CMD_CONTAINER"**
    - .
    - **default:** `postgres-folio`

- **"DB_CMD_CP_DUMP_DB_DESTINATION"**
    - path where your dumped database file will be copied to.
    - **default:** `../db/`

- **"DB_CMD_SCHEMAS_FILE"**
    - schemas list file in case you want to include/exclude specific schemas while dumping your local database.
    - **default:** `schemas.txt`

- **"DB_CMD_PGDUMP_INCLUDE_SCHEMA_OPTION"**
    - include schema option used with postgres `pgdump` command.
    - **default:** `-n`

- **"DB_CMD_PGDUMP_EXCLUDE_SCHEMA_OPTION"**
    - exclude schema option used with postgres `pgdump` command.
    - **default:** `-N`

- **"DB_CMD_CREATE_MODULE_ROLE"**
    - create role query.
    - **default:** `create user %s superuser createdb;`

- **"DB_CMD_ALTER_MODULE_ROLE"**
    - change user role for a schema query.
    - **default:** `alter user %s set search_path = %s;`

- **"DB_CMD_PSQL_WITH_DOCKER"**
    - running postgres could be through docker image or directly from the host machine.
    - so if your postgres is running from a docker container, please set the value to `true` else set it to `false`.
    - **default:** `true`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### KAFKA Configuration
- here we have all kafka configuration.

- **"KAFKA_PORT"**
    - **default:** `9092`

- **"KAFKA_HOST"**
    - **default:** `localhost`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Elastic Configuration
- here we have all elastic search configuration.

- **"ELASTICSEARCH_URL"**
    - **default:** `http://localhost:9200`

- **"ELASTICSEARCH_HOST"**
    - **default:** `localhost`

- **"ELASTICSEARCH_PORT"**
    - **default:** `9200`

- **"ELASTICSEARCH_USERNAME"**
    - **default:** -

- **"ELASTICSEARCH_PASSWORD"**
    - **default:** -

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Okapi Configuration

- **"OKAPI_PORT"**
    - `okapi` instance will listen on this port.
    - **default`9130`:** 

- **"OKAPI_HOST"**
    - **default`localhost`:** 

- **"END_PORT"**
    - to control the ports available for `okapi` modules we set and end port value.
    - **default:** `9199`

- **"OKAPI_DIR"**
    - path in `modules` directory to reach `okapi` project.
    - **default:** `okapi`

- **"OKAPI_REPO"**
    - `okapi` repository url from which we will clone `okapi` project if not exists locally.
    - **default:** `https://github.com/folio-org/okapi.git`

- **"OKAPI_OPTION_ENABLE_SYSTEM_AUTH"**
    - `okapi` option to enable authentication filter on api requests or not.
    - **default:** `true`

- **"OKAPI_OPTION_ENABLE_VERTX_METRICS"**
    - `okapi` option to enable observe vert.x module metrics using `micrometer`.
    - **default:** `false`

- **"OKAPI_OPTION_STORAGE"**
    - okapi option to establish where the data will be stored there are mainly three values (`inmemory`, `postgres`, `mongo`).
    - **default:** `postgres`

- **"OKAPI_OPTION_TRACE_HEADERS"**
    - `okapi` option to enable adding `X-Okapi-Trace` header which state which modules have been visited during the api request journy.
    - **default:** `true`

- **"OKAPI_OPTION_LOG_LEVEL"**
    - `okapi` option to set the log level of `okapi` instance logs like `info` or `debug`.
    - **default:** `DEBUG`

- **"OKAPI_OPTIONS_EXTENDED"**
    - okapi options extended to be able to add any further options you want.
    - **default:** `-Dvertx.metrics.options.enabled=false -Dtoken_cache_ttl_ms=10`

- **"OKAPI_ARG_DEV"**
    - `okapi` argument `dev` could be used when starting `okapi`, we have mainly six values (`dev`, `cluster`, `initdatabase`, `purgedatabase`, `proxy`, `deployment`).
    - for more information check [okapi guide][okapi_guide_docs]
    - **default:**`dev` 

- **"OKAPI_ARG_INIT"**
    - `okapi` argument `initdatabase` could be used when starting `okapi`, we have mainly six values (`dev`, `cluster`, `initdatabase`, `purgedatabase`, `proxy`, `deployment`).
    - for more information check [okapi guide][okapi_guide_docs]
    - **default:** `initdatabase`

- **"OKAPI_ARG_PURGE"**
    - `okapi` argument `purgedatabase` could be used when starting `okapi`, we have mainly six values (`dev`, `cluster`, `initdatabase`, `purgedatabase`, `proxy`, `deployment`).
    - for more information check [okapi guide][okapi_guide_docs]
    - **default:** `purgedatabase`

- **"OKAPI_DOCKER_IMAGE_TAG"**
    - its the image tag name used in case you run in docker environment.
    - **default:** `okapi`

- **"OKAPI_DOCKER_CONTAINER_NAME"**
    - its the container name used in case you run in docker environment.
    - **default:** `okapi`

- **"OKAPI_CORE_DIR"**
    - path to `okapi-core` directory which is usually used to start `okapi`.
    - **default:** `okapi/okapi-core`

- **"RETURN_FROM_OKAPI_CORE_DIR"**
    - to go back to `modules` directory from `okapi-core` directory.
    - **default:** `../..`

- **"OKAPI_WAIT_UNTIL_FINISH_STARTING"**
    - this is a sleep time waiting for `okapi` to finish starting up, because if you do not wait and just continue the next steps may try to call `okapi` with an api request, and if it did not finish starting the request will fail.
    - the wait time may vary depends on your machine cpu and memory resources.
    - the time unit here is `seconds`.
    - **default:** `10`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Modules Configuration

- **"SHOULD_STOP_RUNNING_MODULES"**
    - its helpful when you rerun the script multiple times, if you want to stop all running modules and start over you can set this configuration to `true`.
    - **default:** `true`

- **"EMPTY_REQUIRES_ARRAY_IN_MODULE_DESCRIPTOR"**
    - to prevent dependency validation on registering modules into `okapi` you can set this configuration to `true`.
    - **default:** `true`

- **"REMOVE_AUTHTOKEN_IF_ENABLED_PREVIOUSLY"**
    - `mod-authtoken` if enabled in a previous run, it causes problems when you want to start over as it wants you to be authenticated while the module mod-authtoken is not up and running yet so here if you want to remove the module from the tenant to prevent these issues you can set this configuration to `true`.
    - **default:** `true`

- **"DEFAULT_MODULE_BASE_REPO"**
    - if one of modules in `modules.json` does not have key `repo` then the script will clone the module from `org-folio` repo on github directly using this configuration value.
    - **default:** `https://github.com/folio-org`

- **"DEFAULT_MODULE_BUILD_CMD"**
    - if one of the modules in `modules.json` does not have key `build` then the default build command used will be this configuration.
    - **default:** `mvn -DskipTests -Dmaven.test.skip=true package`

- **"UPDATE_INSTALLED_MODULE_STATUS_QUERY"**
    - change module status query directly to disable for example `mod-authtoken` and `mod-permissions` at start running the script to prevent `okapi` from sending api calls to them where they are not deployed yet.
    - **default:** `UPDATE tenants SET tenantjson = jsonb_set(tenantjson::jsonb, '{enabled}', (tenantjson->'enabled')::jsonb || '{%s: %s}'::jsonb) WHERE tenantjson->'descriptor'->>'id' = '%s';`

- **"DELETE_INSTALLED_MODULE_QUERY"**
    - remove a module from a tenant enabled json list for example removing `mod-authtoken` and `mod-permissions` at start running the script to prevent `okapi` from sending api calls to them where they are not deployed yet.
    - **default:** `UPDATE tenants SET tenantjson = jsonb_set(tenantjson::jsonb, '{enabled}', (tenantjson->'enabled') - '%s') WHERE tenantjson->'descriptor'->>'id' = '%s';`

- **"ENABLE_FREE_ALLOCATED_PORTS_FOR_OKAPI_MODULES"**
    - at starting of the script there is a range or ports allocated to `okapi` from for example `9131` to `9199` excluding `9130` as `okapi` it self listen on this port, and to start working with modules the script frees these ports if any of them are used by other porcesses.
    - if you want to disable this feature, because some ports within the range are running on other critical programs, then you can set the value to `false` or simply reduce the range of allocated ports to `okapi`.
    - **default:** `true`

- **"ENABLE_LOGIN_WITH_EXPIRY"**
    - this configuration enables login with the new RTR (Refresh Token Rotation) approach through `/authn/login-with-expiry` api request.
    - **default:** `true`

- **"ACCESS_TOKEN_COOKIE_KEY"**
    - when using login with expiry the token will be in the cookies within a key called `folioAccessToken` which is the default value right now.
    - **default:** `folioAccessToken`

- **"REFRESH_TOKEN_COOKIE_KEY"**
    - when using login with expiry the refresh token will be held in the cookies within a key called `folioRefreshToken` which is the default value right now.
    - **default:** `folioRefreshToken`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Tenant Configuration

- the script will automatically creates a tenant for the modules to work with.
- **"TENANT"**
    - specifies the tenant id value.
    - **default:** `test`

- **"TENANT_NAME"**
    - specifies the tenant name value.
    - **default:** `Test`

- **"TENANT_DESCRIPTION"**
    - specifies the tenant description value.
    - **default:** `Test Library`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### User Configuration
- the script will automatically creates a user for the modules to use it in authentication within system.
- **"USERNAME"**
    - set the username value.
    - **default:** `ui_admin`

- **"PASSWORD"**
    - set the user password value.
    - **default:** `admin`

- **"USER_ACTIVE"**
    - set the user active status.
    - **default:** `true`

- **"USER_BARCODE"**
    - set the user barcode value.
    - **default:** `123456789`

- **"USER_PERSONAL_FIRSTNAME"**
    - set the user personal information first name.
    - **default:** `John`

- **"USER_PERSONAL_LASTNAME"**
    - set the user personal information last name.
    - **default:** `Doe`

- **"USER_PERSONAL_MIDDLENAME"**
    - set the user personal information middle name.
    - **default:** `Richard`

- **"USER_PERSONAL_PREFERRED_FIRST_NAME"**
    - set the user personal information preferred first name.
    - **default:** `John`

- **"USER_PERSONAL_PHONE"**
    - set the user personal information phone number.
    - **default:** `7777777`

- **"USER_PERSONAL_MOBILE_PHONE"**
    - set the user personal information mobile phone number.
    - **default:** `7777777`

- **"USER_PERSONAL_PREFERRED_CONTACT_TYPE_ID"**
    - set the user personal information contact type id.
    - not sure if this information is important.
    - **default:** `002`

- **"USER_PERSONAL_EMAIL"**
    - set the user email.
    - **default:** `john@email.com`

- **"USER_PROXY_FOR"**
    - set user proxy for list.
    - not sure if this information is important.
    - **default:** `[]`

- **"USER_DEPARTMENTS"**
    - set user departments list.
    - is empty right now as departments table is empty but if you are sure that the database has not empty departments table, then you can pick some `UUIDS` from the table and put them here.
    - **default:** `[]`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Docker Configuration

- **"RUN_WITH_DOCKER"**
    - a flag states whether the script will run on local machine as jar processes or in docker containers enivonment.
    - if true then all modules including okapi will run in docker containers.
    - **default:** `false`

- **"DOCKER_CMD"**
    - the docker command used.
    - you can add sudo before `docker` value to be like this `sudo docker` in case your docker can only run in the root.
    - **default:** `docker`

- **"DOCKER_NETWORK"**
    - specify the docker network name so all modules share it and can communitcate with each others through it.
    - **default:** `folio`

- **"DOCKER_ADDED_HOST"**
    - add host to make modules be able to communitcate with `postgres`, `kafka`, `elasticsearch` services which does not share the same docker network.
    - **default:** `host.docker.internal:host-gateway`

- **"DOCKER_MODULE_DEFAULT_PORT"**
    - each module internally will operate on one port which the default value is `8081`.
    - **default:** `8081`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Postman Configuration
- here are the configuration to be able to talk to postman API and update your environment variables.
- **"POSTMAN_API_KEY"**
    - you can set your postman API Key here.
    - **default:** -

- **"POSTMAN_URL"**
    - you can set the api url for postman here.
    - **default:** `https://api.getpostman.com`

- **"POSTMAN_IMPORT_OPENAPI_PATH"**
    - path for the postman api to import swagger openapi yml files as collections.
    - **default:** `/import/openapi`

- **"POSTMAN_ENVIRONMENT_PATH"**
    - path for postman api to update your postman environments.
    - **default:** `/environments`

- **"POSTMAN_ENV_LOCAL_WITH_OKAPI_UUID"**
    - the id (`UUID`) of specific postman environment you want to update its variables like `token`, `user_id`.
    - **default:** -

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

### Folio Commands

- folio commands are command line aliases with arguments passed through after the alias to achieve a specific goal from the script.
- the commands can be grouped to make easy to understand them.

#### Group #1 - helpers

```bash
folio import-aliases                    
folioup                                 
cdfolio
okapilog
```

- **folio import-aliases**:
    - import aliases from scripts/aliases.txt into ~/.bashrc or ~/.bash_aliases file 
    - for the first time you cannot use the `folio` command right a way, instead you run this one `./run.sh import-aliases`.
    - next you need to run `source ~/.bashrc` so the imported aliases could be used right a way in your existing terminal instead of opening a new terminal.
    - use it once to not import the aliases multiple times.
    - **use cases:** at the beginning after cloning the repo you need to import aliases.

- **folioup**:
    - will run all your docker compose services.
    - you can explicitly choose which services you want to run by adding them right after the command.
    - for example: `folioup postgres kafka zookeeper`, and this one is the most I use personally while working locally.
    - **use cases:** before working with the script you need some of the docker compose services to be up and running like `postgres` at least.

- **cdfolio**:
    - move you to folio directory working space.
    - **use cases:** in case you want to quickly move there.

- **okapilog**:
    - output okapi logs into your current terminal.
    - **use cases:** if you run okapi through the script you need to see the okapi logs for debugging purposes, in that case you can open a new terminal or a new tab and run `okapilog` command to see the logs in realtime.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Group #2 - starters
```bash
folio
folio without-okapi
folio start
folio restart
folio init
folio purge
```

- **folio**:
    - all modules will be stopped first.
    - then it will just walk through the modules and run them again one after the other and skip starting okapi step.
    - **use cases:** sometimes you want to debug okapi it self and for that you decided to run okapi in your IDE like `IntelliJ`, so you do not need to run okapi through the script.
    
- **folio without-okapi**:
    - this command seams like the previous one, but they are not the same.
    - this one does not run okapi like the previous command.
    - but it also does not run modules on the local okapi instance.
    - it simply cut of the relation between modules in local okapi instance at all.
    - this means that modules while running this command will not get into these steps (`register`, `deploy`, `install`)
    - **use cases:** its only helpful if you want to do one of these operations
        1. run modules on remote okapi instance.
        2. do `clone` or/and `build` steps only on some modules without running them.

- **folio start**:
    - all modules will be stopped first.
    - then it will run the local okapi insance with modules specified in `modules.json`.
    - if okapi is already running the script will stop `okapi` and restart it again.
    - **use cases:** if you want to start okapi and run your modules within it.

- **folio restart**:
    - there is actually no difference between this command and the previous one.
    - `folio start` and `folio restart` are the same.
    - **use cases:** same like previous command `folio start`

- **folio init**:
    - runs okapi with argument `initdatabase`.
    - removes existing tables and data if available and creates the necessa
    ry stuff (reinitialize), and exits Okapi.
    - reinitialize means creating needed database tables for okapi to operate like (`env`, `deployments`, `tenants`, `timers`, `modules`).
    - it affects only the database configured while running okapi, so in case you used `okapi_modules` database, then `okapi_modules_staging` database will remain untouched.
    - will not run okapi instance or run any other modules.
    - it will just stop after finishing the operation
    - **use cases:** in case you want to start over and clean your database and reinitialize.

- **folio purge**:
    - runs okapi with argument `purgedatabase`.
    - removes existing tables and data only, does not reinitialize.
    - it affects only the database configured while running okapi, so in case you used `okapi_modules` database, then `okapi_modules_staging` database will remain untouched.
    - will not run okapi instance or run any other modules.
    - it will just stop after finishing the operation
    - **use cases:** in case you want to start over with clean database without any reinitialization.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Group #3 - stoppers
```bash
folio stop
folio stop <port>
folio stop okapi
folio stop modules
```

- **folio stop**:
    - will stop running okapi instance with its running modules all together.
    - **use cases:** if you finished working and want to stop them to free memeory and cpu.

- **folio stop <port>**:
    - will stop only one module runs on that port.
    - it can be generally used to stop any process runs on the given port.
    - **use cases:** if you want to stop a specific module and run it within your IDE instead for debugging purposes.

- **folio stop okapi**:
    - will stop okapi only and the rest modules will remain up and running.
    - **use cases:** if you want to stop only okapi because you want for example to run your okapi in your IDE for debugging purposes.

- **folio stop modules**:
    - stops only modules except okapi.
    - needs okapi to be up and running as it stops deployed modules on okapi based on an API request call to okapi which retrieves all current deployed modules and loop on them to stop the modules one by one.
    - **use cases:** N/A

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Group #4 - db

- Here is a recorded video to see a real example how to work with the db operations.

[![Folio Database Operations Playlist][folio_db_operations_yt_img]][folio_db_operations_yt]


```bash
# drop your local or staging local database and import complete new database or local staging database
folio db import
folio db staging import

# import specific schema into your local database or local staging database
folio db import-schema <schema_name>
folio db staging import-schema <schema_name>

# import specific schema table into your local database or local staging database
folio db import-table <schema_name> <table_name>
folio db staging import-table <schema_name> <table_name>

# import specific remote schema into your local database or local staging database
folio db import-remote-schema <schema_name>
folio db staging import-remote-schema <schema_name>

# import specific remote table into your local database schema or local staging database schema
folio db import-remote-table <schema_name> <table_name>
folio db staging import-remote-table <schema_name> <table_name>

# dump local database or local staging database completely
folio db dump
folio db staging dump

# dump local database or local staging database completely with print option to show the query
folio db print dump
folio db print staging dump

# dump local database or local staging database and only include schemas from schemas.txt
folio db dump-include-schemas
folio db staging dump-include-schemas

# dump local database or local staging database and exclude schemas from schemas.txt
folio db dump-exclude-schemas
folio db staging dump-exclude-schemas

# dump database or staging database schema to your machine
folio db dump-schema <schema_name>
folio db staging dump-schema <schema_name>

# dump local database or staging database schema table to your machine
folio db dump-table <schema_name> <table_name>
folio db staging dump-table <schema_name> <table_name>

# dump remote database schema to your machine
folio db dump-remote-schema <schema_name>

# dump remote database schema table to your machine
folio db dump-remote-table <schema_name> <table_name>

# list schemas for local database or local staging database
folio db list-schemas
folio db staging list-schemas

# list schemas for a remote database
folio db list-remote-schemas
```

- **folio db import**:
    - import new database sql file after dropping the old one.
    - in `db` directory the sql file should be there with the configured name, default name is `okapi.sql`
    - if the file is missing in the directory `db` the import commmand fails.
    - `db` directory is also a default configurable value of key `DB_CMD_DATABASE_SQL_DIR_PATH`.
    - **use cases:** in case you want restore a backup version of your local database.

- **folio db staging import**:
    - import new staging database sql file after dropping the old one.
    - in `db` directory the sql file should be there with the configured name, default name is `okapi.sql`
    - if the file is missing in the directory `db` the import commmand fails.
    - `db` directory is also a default configurable value of key `DB_CMD_DATABASE_SQL_DIR_PATH`.
    - **use cases:** in case you want to restore or add an updated version of your staging database.

- **folio db import-schema**:
    - import a new database schema sql file after dropping the old schema.
    - in `db` directory the sql file should be there with the configured name, default name is `<schema_name>.sql`
    - if the file is missing in the directory `db` the import commmand fails.
    - `db` directory is also a default configurable value of key `DB_CMD_DATABASE_SQL_DIR_PATH`.
    - example command `folio db import-schema test_mod_users`.
    - **use cases:** in case you want to restore an old schema backup.

- **folio db staging import-schema**:
    - import a new staging database schema sql file after dropping the old one.
    - in `db` directory the sql file should be there with the configured name, default name is `<schema_name>.sql`
    - if the file is missing in the directory `db` the import commmand fails.
    - `db` directory is also a default configurable value of key `DB_CMD_DATABASE_SQL_DIR_PATH`.
    - example command `folio db staging import-schema test_mod_users users`.
    - **use cases:** in case you want to restore or update an old schema version in your staging database.

- **folio db import-table**:
    - import a new schema table sql file after dropping the old table.
    - in `db` directory the sql file should be there with the configured name, default name is `<schema_name>-<table_name>.sql`
    - if the file is missing in the directory `db` the import commmand fails.
    - `db` directory is also a default configurable value of key `DB_CMD_DATABASE_SQL_DIR_PATH`.
    - example command `folio db import-table test_mod_users users users`.
    - **use cases:** in case you want to restore an old table backup.

- **folio db staging import-table**:
    - import a new staging database table sql file after dropping the old one.
    - example command `folio db staging import-table test_mod_users users`.
    - **use cases:** in case you want to restore or update an old table version in your staging database.

- **folio db import-remote-schema**:
    - import a remote database schema by dumping it first from remote, and then import it to local database after dropping the old schema.
    - example command `folio db import-remote-schema test_mod_users`.
    - **use cases:** in case you want to import remote schema to your local database.

- **folio db staging import-remote-schema**:
    - import a remote database schema by dumping it first from remote, and then import it to local staging database after dropping the old schema.
    - example command `folio db staging import-remote-schema test_mod_users`.
    - **use cases:** in case you want to import remote schema to your local staging database.

- **folio db import-remote-table**:
    - import a remote database table by dumping it first from remote, and then import it to local database after dropping the old table.
    - example command `folio db import-remote-table test_mod_users users`.
    - **use cases:** in case you want to import remote table to your local database.

- **folio db staging import-remote-table**:
    - import a remote database table by dumping it first from remote, and then import it to local staging database after dropping the old table.
    - example command `folio db staging import-remote-table test_mod_users users`.
    - **use cases:** in case you want to import remote table to your local staging database.

- **folio db dump**:
    - dump database with all schemas to an sql file.
    - **use cases:** more like backup purpose.

- **folio db staging dump**:
    - dump database with all schemas to an sql file from your local staging database.
    - **use cases:** more like backup purpose. 

- **folio db print dump**:
    - will print the query runs with `folio db dump` command only and the query it self will not run.
    - **use cases:** the new option is more for debugging purposes. 

- **folio db print staging dump**:
    - will print the query runs with `folio db dump` command only and the query it self will not run.
    - **use cases:** the new option is more for debugging purposes. 

- **folio db dump-include-schemas**:
    - dump database with included schemas found in schemas.txt file to an sql file.
    - **use cases:** more like backup purpose.

- **folio db staging dump-include-schemas**:
    - dump database with included schemas found in schemas.txt file to an sql file from your local staging database.
    - **use cases:** more like backup purpose.

- **folio db dump-exclude-schemas**:
    - dump database by excluding schemas found in schemas.txt file to an sql file.
    - **use cases:** more like backup purpose.

- **folio db staging dump-exclude-schemas**:
    - dump database by excluding schemas found in schemas.txt file to an sql file from staging database.
    - **use cases:** more like backup purpose.

- **folio db dump-schema**:
    - dump local database schema to an sql file.
    - example command `folio db dump-schema test_mod_users`.
    - **use cases:** more like backup purpose.

- **folio db staging dump-schema**:
    - dump local staging database schema to an sql file.
    - example command `folio db staging dump-schema test_mod_users users`.
    - **use cases:** more like backup purpose.

- **folio db dump-table**:
    - dump local database table to an sql file.
    - example command `folio db dump-table test_mod_users users`.
    - **use cases:** more like backup purpose.

- **folio db staging dump-table**:
    - dump local staging database table to an sql file.
    - example command `folio db staging dump-table test_mod_users users`.
    - **use cases:** more like backup purpose.

- **folio db dump-remote-schema**:
    - dump remote database schema to an sql file.
    - example command `folio db dump-remote-schema test_mod_users`.
    - **use cases:** more like backup purpose for remote database.

- **folio db dump-remote-table**:
    - dump remote database table to an sql file.
    - example command `folio db dump-remote-table test_mod_users users`.
    - **use cases:** more like backup purpose for remote database.

- **folio db list-schemas**:
    - list your local database schemas.
    - **use cases:** to show current schemas to help you pick what you want to dump.

- **folio db staging list-schemas**:
    - list database schemas from your local staging database.
    - **use cases:** to show current schemas to help you pick what you want to dump.

- **folio db list-remote-schemas**:
    - list your remote database schemas.
    - **use cases:** to show current remote database schemas to help you pick what you want to dump.

<p align="right">(<a href="#readme-top">back to top</a>)</p>


### Folio Examples

- I did record a series of videos uploaded on youtube so anyone can see it and grouped the series in [Folio Local Environment Examples][folio_examples_yt] playlist.     

[![Folio Local Environment Examples Playlist][folio_examples_yt_img]][folio_examples_yt]


- The playlist shows actual examples how to use the script in different scenarios.

- Here are the examples recorded in the playlist:
    1. **Run okapi from IDE with one module from IDE**: 
        - here we will not use the automation script.
        - we will run `okapi` from the IDE (IntelliJ), and use postman to attach a module (mod-users) to it.
        - we go through the `okapi` 3 steps to add a module (Register, Deploy, Install (Enable)).
        - each step will be handled through postman api request.
        - the reason we did this example is to show to you how slow the process is to to do it manually, and also a way to explain how to do it from the first place.
    2. **Run okapi with sample modules**: 
        - here we will start run the automation script.
        - we will navigate to the installation process in the docs and start walking through the steps step by step.
        - we will utilize the `install.sh` step to skip all following steps and run the script using the sample modules.
    3. **Run okapi from IDE with sample modules**: 
        - its the same like the previous example except we will run `okapi` from IDE (IntelliJ) instead of running it in a background process.
        - you will see how we can configure `okapi` to run it from our own IDE (IntelliJ) directly.
        - I may need to run `okapi` in the IDE for debugging purposes, or for adding env vars as right now the script cannot export env vars while running `okapi`.
    4. **Run okapi with sample modules and stop/restart a module or more from IDE**: 
        - here we will see how to stop one or more already running modules and run them again from our IDE mostly for debugging purposes.
    5. **Run remote okapi with one or more modules**: 
        - here you can run a module without running local `okapi`, instead you will connect the module directly to a remote (cloud) `okapi` instance, like `folio-snapshot`.
    - **Rerun okapi from IDE without dropping attached modules**: 
        - if you want to stop and rerun okapi many times from your IDE for debugging purposes you can achieve this.
        - you need to stop the `okapi` process it self first.
        - then persist deployment information of all your current modules manually into `okapi` database.
        - after that you are free to rerun your `okapi` from IDE again and all attached moduels will be up and running as well. 
    6. **Run okapi with sample modules and skip authentication filter**: 
        - the straight forward way is to reconfigure the script and disable okapi authentication filter and disable `mod-authtoken` from the `modules.json` list and rerun the script.
        - or there is a nother way where you can utilize the previous example, to achieve the same result.
        - if you can stop and rerun your `okapi` instance from your IDE, then you can simply set the `-Denable_system_auth=false` to false, and simply rerun okapi.
        - even if `mod-authtoken` is up and running you can still work with your modules without the need to authenticate.
        - but you cannot use `mod-authtoken` in this case, for example you cannot hit the login `/authn/login` endpoint.
    7. **Run okapi with sample modules in docker containers**: 
        - this one will take you to a next level where you can run your environment in Docker Containers.
        - there is a way to run `okapi` directly throug the script or you can run the `okapi` like a service from `docker-compose.yml` file, but this option has not been mentioned in the video. 
    8. **Just clone and build mdoules using `without-okapi` argument**: 
        - here you can use the script for just `clone` or/and `build` modules.
    9. **Run a module from IDE with a remote okapi**:
        - here we will not use the automation script.
        - run module `mod-inventory` from our IDE, and use the remote `okapi` instance from `folio-snapshot`.
        - The use case for this example is to run one module only, without the need to run local `okapi` instance.
    10. **Run a module from `Docker` manually with a remote okapi**:
        - here we will not use the automation script.
        - run module `mod-inventory` Docker container, and use the remote `okapi` instance from `folio-snapshot`.
        - The use case for this example is to test running the Docker image to debug any problems could happens while deploying the module.
    11. **Run a module from IDE and manually examine an asynchronous communication using `KAFKA`**:
        - we will use the script to run all sample modules plus `mod-search`
        - we added `mod-search` to examine the asynchronouse communication through `KAFKA`.
        - when we create/update/delete an instance for example from `mod-inventory-storage` the `mod-search` elasticsearch index should be synced.
        - the way `mod-inventory-storage` and `mod-search` communicate is through `KAFKA` published event messages.
        - so in case you want to debug a specific module and there is an asynchrous communication you can learn from this example how to achieve this.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Module dependencies examples

- while working locally we cannot run the complete environment, so we only run modules related to what we need to debug locally.
- so here we will give examples based on my own work, which will state dependent modules needed for a module api call to work properly.
- we will also list the services needed to run from `docker-compose.yml` to run the environment.
- some modules are only needed for authentication to work properly and some modules are not that essential for the api call to work, but they have been added because the have been called along the api call journy inside the system.
- here we could benefit from the help of others who has experience with working in a local okapi environment, so be free to add more examples in this section, to help others.
- working with other api requests than provided here may work properly without problems, so the api calls listed here its just related to our experience, if you want to work with other api requests you can start right a way, and only add a new module to the list if the api request fails because of a missing module.

- **Example #1**:
    - **module**: mod-circulation
    - **api-requests**:
        - `/circulation/check-in-by-barcode`
        - `/circulation/check-out-by-barcode`
    - **dependencies**
        - mod-permissions
        - mod-inventory-storage
        - mod-users
        - mod-configuration
        - mod-login
        - mod-password-validator
        - mod-authtoken
        - mod-pubsub
        - mod-users-bl
        - mod-settings
        - mod-circulation-storage
        - mod-feesfines
        - mod-calendar
    - **servies**
        - postgres
        - kafka
        - zookeeper

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## TODOs

- [ ] folio command line arguments are not that professional made, if its possible to make parameters more professional with `--help` command to describe all working parameters.
- [ ] if this script gets attention from the commmunity, you may turn it to somehow like release versioning using tags to mark each new updates.
- [ ] work on a feature to list for each modules all its nested dependencies, here are some ways to achieve that:
    - for example look at each ModuleDescriptor.json in github.
    - try to use the `okapi-install.json` from [`platform-complete`][platform-complete] repo which is populated on each release.
    - you can also benefit from [`okapi-console`][okapi-console] in settings app, from any folio instance up running like [`folio-snapshot`][folio-snapshot].
- [ ] Currently if you set `EMPTY_REQUIRES_ARRAY_IN_MODULE_DESCRIPTOR` config value to true it will apply on all modules you work on while running the script, it could be better if we can apply this configuration on module level instead of applying it on all modules.
- [ ] we need a way to pass environment variables to okapi while start/restart in both ways running in the host machine or in a docker container, and these env vars could be added in `okapi` object in `modules.json` like other modules. [read more](https://medium.com/@manishbansal8843/environment-variables-vs-system-properties-or-vm-arguments-vs-program-arguments-or-command-line-1aefce7e722c)

- [ ] if your start is on clean `mod-users` schema you cannot add a new user with information like `patron group`, and `address type`, so if we want this information to added to the user the script need to add a group in `groups` table first and use the id in the user creation, the same applies to `address_type`.
- [ ] right now ports allocated are coming directly from `okapi` it self, not what the script allocates so if the script skips a port because its already used, the okapi does not make this check and skip it will allocate this already used port to the module and the module deployment will fail at the end, is there a solution to this case.
- [ ] do not free all ports at once at the beginning instead free it before each use
- [ ] in `database.sh` file we can enhance logging as it uses primitive echo "..." approach.
- [ ] in folio script we need a db command to create a database by name and user.
- [ ] validate `modules.json` object values is not robust, we need to validate value of each key in `modules.json` for empty values.
- [ ] we have `helper.sh` which is now a very big file over `1000` lines of code we need to refactor the file and divide it into smaller files.
- [ ] it will be very helpful to test running the script on each update, so we may add a pipeline that runs the script after each push/merge to main branch to ensure that the script works just fine and did not break after the new shipped script.
- [ ] right now if you pull new changes from remote and `pom.xml` version has changed, the script will not automatically rebuild the project you need to rebuild the module yourself, we need to refactor the script to make the check and if the pom.xml version differs from `ModuleDescriptor.json` version if yes the script will rebuild the module.
- [ ] running in docker environment has an issue, when you run the container the env vars will be added, we have two sources okapi genearal env vars and modules individual env vars they may have duplicates, we need that module specific env vars to overwrite any duplicates found in okapi general env vars.
- [ ] right now, `database.sh` is implemeneted considering `postgres` works from a docker container not directly installed on the host machine, we need to refactor the `database.sh` implementation to work with both. 
- [ ] currently the login operation goes through `mod-login`, in future we want to have the option to use `mod-users-bl` for login as well.
- [ ] currently we have the option to authenticate using the new RTR (Refresh Token Rotation) approach, but the curl requests still add the token in the old `X-Okapi-Token` header instead of the `Cookie` header, like it should be.
- [ ] currently if you run in docker environment, you may face some problems with modules which have Dockerfile that exposes a port not equal to the `8081` standard port configured in `configuration.json` file, with `DOCKER_MODULE_DEFAULT_PORT` key, what we want to a complish is to set the module default port in `modules.json` for each module separately, instead of this general default port.
- [ ] check the script it self you may find `# TODO ...` comments.
- [ ] run module with remote okapi I want to have the option to export module environments for the deployed module.
- [ ] this is one is for me, I want to create a playlist showing how to work with database operations commands.
- [ ] add the option to update user permissions after each new enabled module instead of adding it only once after enable `mod-authtoken`, `mod-users-bl`, and `mod-users`.

See the [open issues](https://github.com/Ahmad-Zaky/folio_okapi_local_environment/issues) for a full list of proposed features (and known issues).

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Contributing

Contributions are what make the open source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".
Don't forget to give the project a star! Thanks again!

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Thanks to all the people who have contributed

<a href="https://github.com/Ahmad-Zaky/folio_okapi_local_environment/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Ahmad-Zaky/folio_okapi_local_environment" />
</a>

Made with [contrib.rocks](https://contrib.rocks).

## License

Distributed under the MIT License. See `LICENSE.txt` for more information.

## Contact

Ahmed Zaky - [Linked In][linkedin-url] - ahmed6mohamed6@gmail.com

<p align="right">(<a href="#readme-top">back to top</a>)</p>



<!-- References -->

<!-- MARKDOWN LINKS & IMAGES -->
<!-- https://www.markdownguide.org/basic-syntax/#reference-style-links -->
[contributors-shield]: https://img.shields.io/github/contributors/Ahmad-Zaky/folio_okapi_local_environment.svg?style=for-the-badge
[contributors-url]: https://github.com/Ahmad-Zaky/folio_okapi_local_environment/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/Ahmad-Zaky/folio_okapi_local_environment.svg?style=for-the-badge
[forks-url]: https://github.com/Ahmad-Zaky/folio_okapi_local_environment/network/members
[stars-shield]: https://img.shields.io/github/stars/Ahmad-Zaky/folio_okapi_local_environment.svg?style=for-the-badge
[stars-url]: https://github.com/Ahmad-Zaky/folio_okapi_local_environment/stargazers
[issues-shield]: https://img.shields.io/github/issues/Ahmad-Zaky/folio_okapi_local_environment.svg?style=for-the-badge
[issues-url]: https://github.com/Ahmad-Zaky/folio_okapi_local_environment/issues
[license-shield]: https://img.shields.io/github/license/Ahmad-Zaky/folio_okapi_local_environment.svg?style=for-the-badge
[license-url]: https://github.com/Ahmad-Zaky/folio_okapi_local_environment/blob/main/LICENSE.txt
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://www.linkedin.com/in/ahmed-zaky-0a7692132/

[1]: https://github.com/folio-org/okapi/blob/master/doc/guide.md
[2]: https://github.com/adamdickmeiss/folio-local-run
[3]: https://github.com/adamdickmeiss
[4]: https://www.atlassian.com/git/tutorials/git-bash
[5]: https://www.cygwin.com
[6]: https://learn.microsoft.com/en-us/windows/wsl/install
[7]: https://github.com/folio-org/okapi
[8]: https://www.postgresql.org
[9]: https://www.pgadmin.org
[10]: https://kafka.apache.org
[11]: https://zookeeper.apache.org
[12]: https://www.elastic.co/elasticsearch
[13]: https://www.elastic.co/kibana
[14]: https://min.io
[15]: https://github.com/folio-org/platform-complete/blob/R2-2024/okapi-install.json

[okapi_guide_docs]: https://github.com/folio-org/okapi/blob/master/doc/guide.md
[okapi_guide]: https://github.com/folio-org/okapi/blob/master/doc/guide.md#install-parameter-tenantparameters
[purge_parameter_docs]: https://github.com/folio-org/okapi/blob/master/doc/guide.md#purge
[tenant_parameters_docs]: https://github.com/folio-org/okapi/blob/master/doc/guide.md#tenant-parameters
[platform-complete]: https://github.com/folio-org/platform-complete
[okapi-console]: https://folio-snapshot.dev.folio.org/settings/developer/okapi-console
[folio-snapshot]: https://folio-snapshot.dev.folio.org
[folio_examples_yt]: https://www.youtube.com/playlist?list=PLPLXtkKpB3YzfJUkLb8id7STbp0Qwjo5a
[folio_examples_yt_img]: https://i.ytimg.com/vi/RXDNS78KO6E/maxresdefault.jpg
[folio_local_environment_yt]: https://www.youtube.com/playlist?list=PLPLXtkKpB3Yz145fYtelvuWOtmBMEFsbc
[folio_local_environment_yt_img]: https://i.ytimg.com/vi/vgyT2qlow6g/maxresdefault.jpg 
[folio_db_operations_yt]: https://www.youtube.com/playlist?list=PLPLXtkKpB3Yz96uVdUxlSNV129fWBntSO
[folio_db_operations_yt_img]: https://i.ytimg.com/vi/xg0UP3M-GbU/maxresdefault.jpg
