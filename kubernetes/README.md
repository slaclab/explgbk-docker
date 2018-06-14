# Deploy


To deploy a new stack on kubernetes:

    bash deploy ENVIRONMENT
    
where `ENVIRONMENT` is a bash file of key value pairs which should be modified to suit ones needs. One may have different files for production, dev etc.

Specifically, one should define the `namespace` and the certificates and keytabs associated with the service.

Once executed, you should be able to show the deployments using

    kubectl get all -n <namespace defined in ENVIRONMENT> -o wide

The chances are the `explgbk` will be in a crash loop as it tries to access the database, but fails.

Therefore, you will now need to populate the mongo database from possibly another database using

    mongodump --archive=/path/to/mydata.mongodump
    
then get a shell onto your new mongo instance using

    kubectl -n cryoem-logbook-dev exec -it mongo-0 mongo
    
and execute

    mongorestore --archive=/path/to/mydata.mongodump
    
Note that due to the limited bind mounts on the mongo containers, you may need to move the dump files to somewhere reachable (eg /data/db/)
    

# Update

To update the containers to a specific tag, one should edit the ENVIRONMENT file with the relevant dockerhub tag. Then,

    bash deploy ENVIRONMENT --update


