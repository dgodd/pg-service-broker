# PostgreSQL Service Broker

After pushing this app to Cloud Foundry, it will create and return databases (on a host pg instance) upon reqest

## Broker Setup

* Copy settings.json.sample to settings.json and edit it.
* Edit manifest.yml, and then:

```
cf push
cf create-service-broker whale-postgres admin password http://[ABOVE HOST] --space-scoped
```

## App Setup
```
cf create-service whale-postgres public myPostgres
```
