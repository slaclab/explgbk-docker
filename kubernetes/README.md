To deploy a new stack on kubernetes:

    bash deploy ENVIRONMENT
    
where `ENVIRONMENT` is a bash file of key value pairs which should be modified to suit ones needs.

Specifically, one should define the `namespace` and the certificates and keytabs associated with the service.

Once executed, you should be able to show the deployments using

    kubectl get all -n cryoem-logbook-dev -o wide
    
(or whatever your namespace is you've defined in the ENVIRONMENT file)

The chances are the `explgbk` will be in a crash loop as it tries to access the database, but fails.

Therefore, you will now need to populate the mongo database from possibly another database using

    mongodump --archive=/path/to/cryoem-logbook-dev.mongodump
    
then get a shell onto your new mongo instance using

    kubectl -n cryoem-logbook-dev exec -it mongo-0 mongo
    
and execute

    mongorestore --archive=/path/to/cryoem-logbook-dev.mongodump
    
    
