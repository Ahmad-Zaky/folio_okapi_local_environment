# FOLIO Okapi Local Environment
FOLIO Okapi Local Environment

This repository is based on another repository which started to help developers to run the FOLIO environment locally in an automated manner. [click here](https://github.com/adamdickmeiss/folio-local-run)

Here you can find documentation for running a local FOLIO system. [click here](https://dev.folio.org/guides/run-local-folio)

> Prerequisites

* `git` should be locally installed. [click here](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
* `git bash terminal` for **WINDOWS** users, you need to work inside a linux shell like this terminal (Git Bash) [click here](https://git-scm.com/download/win)
* `java` should be installed locally with jdk v17. [click here](https://www.freecodecamp.org/news/how-to-install-java-in-ubuntu/)
* `jq` linux tool to process json files. [click here](https://jqlang.github.io/jq/download/)
* `yq` linux tool to process yml files. [click here](https://github.com/mikefarah/yq)
* `xmllint` linux tool to process xml files. [click here](https://github.com/AtomLinter/linter-xmllint?tab=readme-ov-file#linter-installation)
* `lsof` linux tool to check process by port number. [click here](https://ioflood.com/blog/install-lsof-command-linux/)
* `docker` docker tool to run modules instead of running it within a process on the host machine. [click here](https://docs.docker.com/engine/install/)
* `netstat` its a linux tool used for displaying network connections, routing tables, interface statistics, masquerade connections, and multicast memberships. However, starting from Ubuntu 20.04, netstat is considered deprecated in favor of the ss command [Click here](https://www.tecmint.com/install-netstat-in-linux/).

> First you need to run this command `sudo docker compose up --build -d` to build and run the containers inside `docker-compose.yml` file which has these services, be aware that you may not need all services located in the `docker-compose.yml` file, the basic services you need are (`postgres`, `kafka`, `zookeeper`).

* postgres
* pgadmin
* zookeeper
* kafka
* elasticsearch
* kibana

> for linux .bash_aliases saved aliases, you can import the aliases automatically by typing `./run.sh import-aliases`.

```
alias folio='cd <path/to/script> && bash run.sh'
alias folioup='cd <path/to/script> && sudo docker compose up -d'
alias okapiup='cd <path/to/script> && sudo docker compose up okapi -d'
alias okapistop='cd <path/to/script> && sudo docker compose stop okapi'
alias foliotest='cd <path/to/script> && bash test.sh'
alias cdfolio='cd <path/to/script>'
alias foliooutputlog='cdfolio && tail -f modules/output.txt'
alias okapi='cd <path/to/okapi> && java -Dport_end=9200 -Dstorage=postgres -jar okapi-core/target/okapi-core-fat.jar dev'
alias okapi_initdb='cd <path/to/okapi> && java -Dport_end=9200 -Dstorage=postgres -jar okapi-core/target/okapi-core-fat.jar initdatabase'
alias okapi_purgedb='cd <path/to/okapi> && java -Dport_end=9200 -Dstorage=postgres -jar okapi-core/target/okapi-core-fat.jar purgedatabase'
alias iokapi='okapi_initdb && okapi'
alias okapilog='cdfolio && tail -f modules/okapi/nohup.out'
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
