# PostgreSQL Service Broker

After pushing this app to Cloud Foundry, it will create and return databases (on a host pg instance) upon reqest

## Broker Setup

* Review catalog.json
* Set environment variables in manifest.yml, then:

```
cf push
cf create-service-broker WhaleDB admin password https://[ABOVE HOST] --space-scoped
```

## App Setup
```
cf create-service WhaleDB public myPostgres
```

## Delete Service

Sometimes it is hard to delete a service since others are using it, to force delete:

```
cf purge-service-offering WhaleDB
cf delete-service-broker WhaleDB
```
