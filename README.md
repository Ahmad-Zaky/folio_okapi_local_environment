# FOLIO Okapi Local Environment
FOLIO Okapi Local Environment


> for linux .bash_aliases saved aliases

```
alias folio='bash run.sh'
alias foliostop='bash stop_modules.sh'
alias okapi='java -Dport_end=9200 -Dstorage=postgres -jar okapi-core/target/okapi-core-fat.jar dev'
alias okapi_initdb='java -Dport_end=9200 -Dstorage=postgres -jar okapi-core/target/okapi-core-fat.jar initdatabase'
alias okapi_purgedb='java -Dport_end=9200 -Dstorage=postgres -jar okapi-core/target/okapi-core-fat.jar purgedatabase'
alias iokapi='okapi_initdb && okapi'
```

> `folio` commands with arguments, note that they are not  some how steps, instead they are variations on how to run/stop folio modules

```
folio init          # removes existing tables and data if available and creates the necessary stuff, and exits Okapi.
folio purge         # removes existing tables and data only, does not reinitialize.
folio restart       # stop all running mocules and restart over with okapi
folio without-okapi # running modules without okapi, its helpful when you run a module placed in modules.json directly with an already running okapi on the cloud
foliostop           # stop all running folio modules
foliostop 9131      # stop one running module by port
okapi               # run okapi with development mode
okapi_initdb        # run okapi with initdatabase mode, which removes existing tables and data if available and creates the necessary stuff, and exits Okapi.
okapi_purgedb       # run okapi with purgedatabase mode, removes existing tables and data only, does not reinitialize.
```

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
