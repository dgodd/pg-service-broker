# PostgreSQL Service Broker

After pushing this app to Cloud Foundry, it will create and return databases (on a host pg instance) upon reqest

## Broker Setup

* Review catalog.json
* Set environment variables in manifest.yml, then:

```
cf push
cf create-service-broker whale-db admin password https://[ABOVE HOST] --space-scoped
```

## App Setup
```
cf create-service WhaleDB public myPostgres
```
