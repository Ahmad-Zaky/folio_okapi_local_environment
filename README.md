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