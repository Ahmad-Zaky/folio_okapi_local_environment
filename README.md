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

> `folio` commands with arguments

```
folio init
folio purge
folio restart
folio without-okapi
```