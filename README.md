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
            <li><a href="#general-practicing-notes">General Practicing Notes</a></li>
      </ul>
    </li>
    <li>
        <a href="#usage">Usage</a>
        <ul>
            <li><a href="#folio-commands">Folio Commands</a></li>
            <li><a href="#folio-examples">Folio Examples</a></li>
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
* `netstat` its a linux tool used for displaying network connections, routing tables, interface statistics, masquerade connections, and multicast memberships. However, starting from `Ubuntu 20.04`, netstat is considered **`deprecated`** in favor of the ss command [Click here](https://www.tecmint.com/install-netstat-in-linux/).

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

3. rename *_template.json files:
    - rename `.env.example`, `modules_template.json`, and `configuration_template.json`.
        ```bash
        cp .env.example .env
        cp modules/modules_template.json modules/modules.json
        cp modules/configuration_template.json modules/configuration.json
        ```
    - modules versions in `modules.json` are set to [`ramsons`][15] release.

4. after renaming *_template, and *.example files review them and replace the values with your own configuration if necessary.

5. Add your aliases commands which eases running the script:
    - open `./scripts/aliases.txt` file and replace `</path/to_repo>` with your `folio` root path.
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

6. Folio depends on some services and tools which are combined in one `docker-compose.yml` file.
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
7. After running your needed services, now you can run the script.

    ```bash
    folio start
    ```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Guide

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
    │   └── permissions.json
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
                "tenantParameters": {
                    "purge": "true",
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
        "tenantParameters": {
            "purge": "true",
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

- **"install_params.tenantParameters.purge"**
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

- **"DB_CMD_DATABASE_SQL_FILE"**
    - sql file name which will be imported in your local database.
    - **default:** `okapi.sql`

- **"DB_CMD_DUMPED_DATABASE_SQL_FILE"**
    - sql file name of the local dumped databse.
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

- **"DB_CMD_SCHEMAS_PATH"**
    - schemas list path in case you want to include/exclude specific schemas while dumping your local database.
    - **default:** `db/schemas.txt`

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
    - okapi instance will listen on this port.
    - **default`9130`:** 

- **"OKAPI_HOST"**
    - **default`localhost`:** 

- **"END_PORT"**
    - to control the ports available for okapi modules we set and end port value.
    - **default:** `9199`

- **"OKAPI_DIR"**
    - path in `modules` directory to reach `okapi` project.
    - **default:** `okapi`

- **"OKAPI_REPO"**
    - okapi repository url from which we will clone okapi project if not exists locally.
    - **default:** `https://github.com/folio-org/okapi.git`

- **"OKAPI_OPTION_ENABLE_SYSTEM_AUTH"**
    - okapi option to enable authentication filter on api requests or not.
    - **default:** `true`

- **"OKAPI_OPTION_ENABLE_VERTX_METRICS"**
    - okapi option to enable observe vert.x module metrics using `micrometer`.
    - **default:** `false`

- **"OKAPI_OPTION_STORAGE"**
    - okapi option to establish where the data will be stored there are mainly three values (`inmemory`, `postgres`, `mongo`).
    - **default:** `postgres`

- **"OKAPI_OPTION_TRACE_HEADERS"**
    - okapi option to enable adding `X-Okapi-Trace` header which state which modules have been visited during the api request journy.
    - **default:** `true`

- **"OKAPI_OPTION_LOG_LEVEL"**
    - okapi option to set the log level of okapi instance logs like `info` or `debug`.
    - **default:** `DEBUG`

- **"OKAPI_OPTIONS_EXTENDED"**
    - okapi options extended to be able to add any further options you want.
    - **default:** `-Dvertx.metrics.options.enabled=false -Dtoken_cache_ttl_ms=10`

- **"OKAPI_ARG_DEV"**
    - okapi argument `dev` could be used when starting okapi, we have mainly six values (`dev`, `cluster`, `initdatabase`, `purgedatabase`, `proxy`, `deployment`).
    - for more information check [okapi guide][okapi_guide_docs]
    - **default:**`dev` 

- **"OKAPI_ARG_INIT"**
    - okapi argument `initdatabase` could be used when starting okapi, we have mainly six values (`dev`, `cluster`, `initdatabase`, `purgedatabase`, `proxy`, `deployment`).
    - for more information check [okapi guide][okapi_guide_docs]
    - **default:** `initdatabase`

- **"OKAPI_ARG_PURGE"**
    - okapi argument `purgedatabase` could be used when starting okapi, we have mainly six values (`dev`, `cluster`, `initdatabase`, `purgedatabase`, `proxy`, `deployment`).
    - for more information check [okapi guide][okapi_guide_docs]
    - **default:** `purgedatabase`

- **"OKAPI_DOCKER_IMAGE_TAG"**
    - its the image tag name used in case you run in docker environment.
    - **default:** `okapi`

- **"OKAPI_DOCKER_CONTAINER_NAME"**
    - its the container name used in case you run in docker environment.
    - **default:** `okapi`

- **"OKAPI_CORE_DIR"**
    - path to `okapi-core` directory which is usually used to start okapi.
    - **default:** `okapi/okapi-core`

- **"RETURN_FROM_OKAPI_CORE_DIR"**
    - to go back to `modules` directory from `okapi-core` directory.
    - **default:** `../..`

- **"OKAPI_WAIT_UNTIL_FINISH_STARTING"**
    - this is a sleep time waiting for okapi to finish starting up, because if you do not wait and just continue the next steps may try to call okapi with an api request, and if it did not finish starting the request will fail.
    - the wait time may vary depends on your machine cpu and memory resources.
    - the time unit here is `seconds`.
    - **default:** `10`

<p align="right">(<a href="#readme-top">back to top</a>)</p>

#### Modules Configuration

- **"SHOULD_STOP_RUNNING_MODULES"**
    - its helpful when you rerun the script multiple times, if you want to stop all running modules and start over you can set this configuration to `true`.
    - **default:** `true`

- **"EMPTY_REQUIRES_ARRAY_IN_MODULE_DESCRIPTOR"**
    - to prevent dependency validation on registering modules into okapi you can set this configuration to `true`.
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

### General Practicing Notes

* both `modules_template.json` and `configuration_template.json` files should be renamed and removed `_template` part from it names to be able to run the script, so the new file names will be turned to `modules.json`, and `configuration.json`.
* When you need to run some okapi modules locally you will need to remove from the `ModuleDescriptor.json` inside the target directory after the build all not used modules that exists in the requires array, to be able to enable that module on the local okapi instance.    
* All curl requests output are logged in a non tracked file named `output.txt`.
* Inside `modules.json` the modules should be sorted in a way that each dependency module is installed firstly then the modules which depends upon that module.
* While running the script you may encounter messages like this `WARNING: HTTP request failed! (Status Code: xxx)` this is not always a problem, and does not means that the script has failed.
* There are some options  that can be passed while running okapi instance like `OKAPI_OPTION_ENABLE_SYSTEM_AUTH`, `OKAPI_OPTION_STORAGE`, `OKAPI_OPTION_TRACE_HEADERS`.
    * `OKAPI_OPTION_ENABLE_SYSTEM_AUTH` has boolean value `true` or `false`, if true it means the filter auth phase will be triggered with installed `mod-authtoken`, so if you run the script without authentication this config key value should be false, else it should be true.
    * `OKAPI_OPTION_STORAGE` has multiple values like `postgres` which means that okapi will store its info within a postgres database which needs connection env variables to be provided, if not set, then it works with in-memory storage, which will be cleared on each okapi instance rerun.
    * `OKAPI_OPTION_TRACE_HEADERS` has boolean values, if true it will return a response header of `X-Okapi-Trace`, which has the name of invoked modules through the request trip. 
* tag version change, will cause a rebuild process to be  triggered.
* branch name change, will cause a rebuild process to be  triggered.
* changing tag/branch will may invoke reinstalling the module, if previously `mod-authtoken` has been installed on the same tenant it will be removed from the tenant to be able to continue the script flow.
* If you normally use `docker` without `sudo` then you do not need to add `sudo` before your `docker` commands, and you can configure the `docker` command used in the script within `configuration.json` file by adjusting the `DOCKER_CMD` key value by default it has `sudo docker` you can change it to just `docker`.
* To run modules within `docker` container you should change `RUN_WITH_DOCKER` configuration value to `true` and change these configuration keys to values like the following to be able to communicate within `docker` network:
    * `DB_HOST` from `localhost` to `postgres`
    * `KAFKA_HOST` from `localhost` to `kafka`
    * `ELASTICSEARCH_URL` from `http://localhost:9200` to `http://elasticsearch:9200`
    * `ELASTICSEARCH_HOST` from `localhost` to `elasticsearch`
* In some cases while you running the script, you will have user permissions issue related to listing users with this permission `users.collection.get` in that case firstly this permission may be added to `permissions` table with `dummy` value equal to `true` you will need to change it manually to false, and edit user permissions by adding this `users.collection.get` permission.
* Related to module permissions, when you add new modules sometimes you need to manually to add these new module permissions to the user.

* A useful tip in case some modules fail, you can navigate to that module and manually pull from remote repo the latest changes and rebuild the module.
* before starting okapi the allocated ports will be freed from the host machine for example if the allocated ports START_PORT=9031 to END_PORT=9199
* There is a specific case when you change db configs for mod-users while you using mod-authtoken there will be an issue as the login attempt will fails, so modules like mod-authtoken, mod-login, and mod-users should share the same db configs.

<p align="right">(<a href="#readme-top">back to top</a>)</p>

## Usage

<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Folio Commands


> `folio` commands with arguments, note that they are not  some how steps, instead they are variations on how to run/stop folio modules

```
folio init                              # removes existing tables and data if available and creates the necessary stuff, and exits Okapi.
folio purge                             # removes existing tables and data only, does not reinitialize.
folio start                             # stop all running modules first and then start over with okapi
folio restart                           # stop all running modules first and then restart over with okapi
folio stop                              # stop all running modules.
folio stop <port>                       # stop one module by port number.
folio stop okapi                        # stop running okapi instance.
folio stop modules                      # stop okapi running modules.
folio without-okapi                     # running modules without okapi, its helpful when you run a module placed in modules.json directly with an already running okapi on the cloud
folio import-aliases                    # import aliases from scripts/aliases.txt into ~/.bashrc or ~/.bash_aliases file but for the first time you cannot use the folio command right a way, instead you run this one ./run.sh import-aliases.
folioup                                 # docker compose up for our docker-compose.yml services
foliotest                               # run a test.sh script
folio db import                         # import the db from an exported file.
folio db staging import                 # import the db from an exported file to staging database.
folio db import-schema                  # import the db schema from an exported file.
folio db staging import-schema          # import the db schema from an exported file to staging database.
folio db dump                           # dump database with all schemas to an sql file.
folio db staging dump                   # dump database with all schemas to an sql file to staging database.
folio db dump-include-schemas           # dump database with included schemas found in schemas.txt file to an sql file.
folio db staging dump-include-schemas   # dump database with included schemas found in schemas.txt file to an sql file from staging database.
folio db dump-exclude-schemas           # dump database with excluding schemas found in schemas.txt file to an sql file.
folio db staging dump-exclude-schemas   # dump database with excluding schemas found in schemas.txt file to an sql file from staging database.
folio db list-schemas                   # list database schemas.
folio db staging list-schemas           # list database schemas from staging database.
cdfolio                                 # move to folio working directory inside the terminal.
foliooutputlog                          # shows the log for curl output of the running folio script.
okapi                                   # run okapi with development mode
okapi_initdb                            # run okapi with initdatabase mode, which removes existing tables and data if available and creates the necessary stuff, and exits Okapi.
okapi_purgedb                           # run okapi with purgedatabase mode, removes existing tables and data only, does not reinitialize.
iokapi                                  # init okapi first and then run it with dev mode.
okapilog                                # shows the log for running okapi instance interactively.
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>


### Folio Examples






<p align="right">(<a href="#readme-top">back to top</a>)</p>


## TODOs

- [ ] we need to handle a case when module version of mod-authtoken has changed when I try to validate authtoken enabled within function `remove_authtoken_and_permissions_if_enabled_previously()`, and same applies for `mod_permissions`.
- [ ] we need to validate input arguments stop with error if not recognized argument has been provided.
- [ ] try to make parameters more professional with --help command to describe all working parameters.
- [ ] in database `db_cmd_defaults()` method we want to offload some of the env vars to be configured from `configuration.json` file.
- [ ] in update installed module status, we want to opt out the query to be configured from configuration.json
- [ ] while starting we start stopping all ports with a specific range starts from `9130` we may make the stop optional either stop or fail.
- [ ] we need to emphasize that removing mod-authtoken, and `mod-permissions` are now implemented directly with Database query because any new version comes prevents from removing the old enabled version and if there are new ways to do it.
- [ ] explain all unused methods as most of them were functioning in the past.
- [ ] update folio aliases and add dump from remote db as command option.
- [ ] update aliases for folio bash commands with new existing aliases.
- [ ] list some sample of group of modules work together ex fot work with mod-circulation you need to some other modules to be enabled as well.
- [ ] explain how to use empty required array in ModuleDescriptor.json file.
- [ ] try to use tags as versioning for your repo in the future if it gains attention
- [ ] try to add feature to get all module dependencies (other modules) try to use the okapi.json which is populated with each release.
- [ ] the configuration `EMPTY_REQUIRES_ARRAY_IN_MODULE_DESCRIPTOR` could be applied on each module independently instead of a general configuration on all modules.
- [ ] if I run folio without `start` or `restart` command and the okapi instance is already up and running the problem with old enabled `mod-authtoken` and `mod-permissions` will not be solved as the cache prevents reading the new db updates so you need to invalidate the cache or restarting okapi forcefully.
- [ ] we need a way to pass environment variables to okapi while start/restart in both ways running in the host machine or in a docker container. [read more](https://medium.com/@manishbansal8843/environment-variables-vs-system-properties-or-vm-arguments-vs-program-arguments-or-command-line-1aefce7e722c)
- [ ] some new user creation information like `patron group`, and `address type`.
- [ ] if pom.xml version is different from `target/ModuleDescriptor.json` we should rebuild the project.
- [ ] Review all configuration keys and explain them if they are not.
- [ ] do not free all ports at once at the beginning instead free it before each use
- [ ] in `database.sh` file we can enhance logging as it uses primitive echo "..." approach.
- [ ] in `database.sh` file if we run `folio db staging import` or without staging the sql file may contain casts that are not present in the local db so you need to add them manually.
- [ ] in `modules.json` in the `okapi` object we need a key to add custom java options.
- [ ] in `modules.json` in the `okapi` object we want the env key value option like in the other modules.
- [ ] we need to only import schemas option so we do not need to drop the whole db and recreate it again.
- [ ] user permissions should be handled properly as new modules have new permissions, these new permissions should be granted to the logged in user.
- [ ] while creating new db on importing a db sql file consider crate Database Objects as it should be like casts and extensions like (btree_gin, pg_trgm, pgcrypto, unaccent, uuid-ossp)
- [ ] in env json array objects its better to use `key` value as the key of environment variable instead of `name`.
    - From    
    ```json
    {
        "name": "OTEL_SERVICE_NAME",
        "value": "mod-authtoken-ot"
    }
    ```

    - To    
    ```json
    {
        "key": "OTEL_SERVICE_NAME",
        "value": "mod-authtoken-ot"
    }
    ```
- [ ] for the README.md file could we show it in a github pages site.
- [ ] we want a command to init the script to run like import aliases and rename _template files.
- [ ] configure wait time after running okapi before continue the script in `start_okapi()` method
- [ ] add create db command for folio db commands.
- [ ] consider add this manual creation script for `okapi_modules` database to the docs
    ```sql
    CREATE USER folio_admin  WITH PASSWORD 'folio_admin';
    CREATE DATABASE okapi_modules OWNER folio_admin;
    GRANT ALL PRIVILEGES ON DATABASE okapi_modules TO folio_admin;
    ```
- [ ] default github repo move to configuration.
- [ ] default build command move to configuration.
- [ ] move to login with expiry approach
- [ ] add install.sh to auto configure the starting steps.
- [ ] write notice for postgres docker compose service that if the user already has the service on his machine, that he should has the databases okapi_modules and okapi_modules_staging created.
- [ ] each key in `modules.json` should be validated for empty values.
- [ ] `helper.sh` should be divided into smaller files.
- [ ] add pipeline that runs the script after each push/merge to main to ensure that the script works just fine and did not break after the new shipped script.

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