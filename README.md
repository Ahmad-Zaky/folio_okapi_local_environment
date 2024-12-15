# FOLIO Local Environment

<!-- TABLE OF CONTENTS -->
  <summary>Table of Contents</summary>
  <ol>
    <li><a href="#about-the-project">About The Project</a></li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
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
            "url": "https://folio-snapshot.dev.folio.org",
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

> NOTICES:

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
* TODO: we need to handle a case when module version of mod-authtoken has changed when I try to validate authtoken enabled within function `remove_authtoken_and_permissions_if_enabled_previously()`, and same applies for `mod_permissions`.
* A useful tip in case some modules fail, you can navigate to that module and manually pull from remote repo the latest changes and rebuild the module.
* before starting okapi the allocated ports will be freed from the host machine for example if the allocated ports START_PORT=9031 to END_PORT=9199
* There is a specific case when you change db configs for mod-users while you using mod-authtoken there will be an issue as the login attempt will fails, so modules like mod-authtoken, mod-login, and mod-users should share the same db configs.
* TODO: we need to validate input arguments stop with error if not recognized argument has been provided.
* TODO: try to make parameters more professional with --help command to describe all working parameters.
* TODO: in database `db_cmd_defaults()` method we want to offload some of the env vars to be configured from `configuration.json` file.
* TODO: in update installed module status, we want to opt out the query to be configured from configuration.json
* TODO: while starting we start stopping all ports with a specific range starts from `9130` we may make the stop optional either stop or fail.
* TODO: we need to emphasize that removing mod-authtoken, and `mod-permissions` are now implemented directly with Database query because any new version comes prevents from removing the old enabled version and if there are new ways to do it.
* TODO: explain all unused methods as most of them were functioning in the past.
* TODO: update folio aliases and add dump from remote db as command option.
* TODO: update aliases for folio bash commands with new existing aliases.
* TODO: list some sample of group of modules work together ex fot work with mod-circulation you need to some other modules to be enabled as well.
* TODO: explain how to use empty required array in ModuleDescriptor.json file.
* TODO: try to use tags as versioning for your repo in the future if it gains attention
* TODO: try to add feature to get all module dependencies (other modules) try to use the okapi.json which is populated with each release.
* TODO: the configuration `EMPTY_REQUIRES_ARRAY_IN_MODULE_DESCRIPTOR` could be applied on each module independently instead of a general configuration on all modules.
* TODO: if I run folio without `start` or `restart` command and the okapi instance is already up and running the problem with old enabled `mod-authtoken` and `mod-permissions` will not be solved as the cache prevents reading the new db updates so you need to invalidate the cache or restarting okapi forcefully.
* TODO: we need a way to pass environment variables to okapi while start/restart in both ways running in the host machine or in a docker container. [read more](https://medium.com/@manishbansal8843/environment-variables-vs-system-properties-or-vm-arguments-vs-program-arguments-or-command-line-1aefce7e722c)
* TODO: some new user creation information like `patron group`, and `address type`.
* TODO: if pom.xml version is different from `target/ModuleDescriptor.json` we should rebuild the project.
* TODO: Review all configuration keys and explain them if they are not.
* TODO: do not free all ports at once at the beginning instead free it before each use
* TODO: in `database.sh` file we can enhance logging as it uses primitive echo "..." approach.
* TODO: in `database.sh` file if we run `folio db staging import` or without staging the sql file may contain casts that are not present in the local db so you need to add them manually.
* TODO: in `modules.json` in the `okapi` object we need a key to add custom java options.
* TODO: in `modules.json` in the `okapi` object we want the env key value option like in the other modules.
* TOOD: we need to only import schemas option so we do not need to drop the whole db and recreate it again.
* TODO: user permissions should be handled properly as new modules have new permissions, these new permissions should be granted to the logged in user.
* TODO: while creating new db on importing a db sql file consider crate Database Objects as it should be like casts and extensions like (btree_gin, pg_trgm, pgcrypto, unaccent, uuid-ossp)
* TODO: in env json array objects its better to use `key` value as the key of environment variable instead of `name`.
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
* TODO: for the README.md file could we show it in a github pages site.
* TODO: we want a command to init the script to run like import aliases and rename _template files.
* TODO: configure wait time after running okapi before continue the script in `start_okapi()` method
* TODO: add create db command for folio db commands.
* TODO: consider add this manual creation script for `okapi_modules` database to the docs
    ```sql
    CREATE USER folio_admin  WITH PASSWORD 'folio_admin';
    CREATE DATABASE okapi_modules OWNER folio_admin;
    GRANT ALL PRIVILEGES ON DATABASE okapi_modules TO folio_admin;
    ```
* TODO: default github repo move to configuration.
* TODO: default build command move to configuration.
* TODO: move to login with expiry approach
* TODO: add install.sh to auto configure the starting steps.
* TODO: write notice for postgres docker compose service that if the user already has the service on his machine, that he should has the databases okapi_modules and okapi_modules_staging created.

> Modules json keys explained:

> The only required unique key is `id` any other keys are optional and may be conditional required

> Example of a module in modules.json contains all possible keys

```
    {
        "comment": "<some comments ...>",
        "id": "mod-mylibrary",
        "repo": "git@github.com:Ahmad-Zaky/mod-mylibrary.git",
        "branch": "main",
        "build": "mvn clean install -DskipTests",
        "rebuild": "false"
        "access_token": "<access_token>",
        "env": [
            {
                "name": "MY_LIBRARY_ENV",
                "value": "123"
            }
        ],
        "okapi": {
            "url": "https://folio-orchid-okapi.dev.folio.org",
            "tenant": "diku",
            "credentials": {
                "username": "diku_admin",
                "password": "admin"
            }
        },
        "postman": {
            "file": "src/main/resources/swagger.api/mod-mylibrary.yaml",
            "api_key": "<api_key>",
            "enabled": "true"
        },
        "install_params": {
            "tenantParameters": {
                "loadReference": "true",
                "loadSample": "true"
            }
        },
        "step": "install",
        "enabled": "true"
    }
```

| Key | Value | example |
| :---------------- | :------ | :------: |
| id | has repository module name. | `mod-users` |
| repo | has the repo link could be ssh or https. | `git@github.com:Ahmad-Zaky/mod-mylibrary.git` |
| tag | while cloning a repo and its used for cloning specific version after `-b` option.  | `git clone git@github.com:Ahmad-Zaky/mod-mylibrary.git -b v1.0.0`
| build | The command to build the module which replace the default build command. | `mvn clean install -DskipTests` |
| rebuild | Has value true/false which leads to rebuild the already built module   | `true` or `false` |
| enabled | As value true/false which leads to skip/not skip the module on running   | `true` or `false` |
| env | exports env variables while running the module, the env variable has an array of objects each object has `key` and `value`   | `{"name": "MY_LIBRARY_ENV","value": "123"}` |
| comment |  Has no effect its just a comment for the developer to see   | - |
| step |  Running a module has several steps I can stop a module to a specific step   | `clone`, `build`, `register`, `deploy`, `install` |
| access_token | Its a repository access token for `cloning`/`pulling` the module when you use `https` not `ssh`    | - |
| okapi | Its responsible for running module on a cloud okapi instane, the reason for not running the module on local instance is that some modules its hard to run it with local okapi instance as it requires too many modules and there is a list of nested dependencies which means the module requires a module and that module requires othe modules and so on | - |
| okapi -> url | Has the value of cloud okapi instance url | `https://folio-orchid-okapi.dev.folio.org` |
| okapi -> tenant | Has the value of cloud okapi tenant name | `diku` |
| okapi -> credentials | Has the value of cloud okapi credentials which has `username`, and `password` | `{"username": "diku_admin", "password": "admin"}` |
| postman | If I have openapi file in my module I can import it in my postman as a collection using an API | - |
| postman -> file | Has the path to the openapi `.yml` file | `"file": "src/main/resources/swagger.api/mod-mylibrary.yaml",` |
| postman -> api_key | Has the api key of my postman account | `"api_key": "<api_key>",` |
| postman -> enabled | Control if we want to import the `.yml` file or not | `true` or `false` |
| install_params | This key value will be used in register (enable) step, A module may, besides doing the fundamental initialization of storage etc. also load sets of reference data. This can be controlled by supplying tenant parameters. These are properties (key-value pairs) that are passed to the module when enabled or upgraded. Passing those are only performed when tenantParameters is specified for install and when the tenant interface is version 1.2 and later. | - |
| install_params -> tenantParameters -> loadReference | with value true loads reference data | `true` or `false` |
| install_params -> tenantParameters -> loadSample | with value true loads sample data. | `true` or `false` |



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
