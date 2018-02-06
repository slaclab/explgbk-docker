# explgbk-docker

docker container and compose for explgbk

# Install

Clone this repo and submodules:

    git clone --recursive git@github.com:slaclab/explgbk-docker.git
  
Install some dependencies

    git clone git@github.com:slaclab/mongo.git
    git clone git@github.com:slaclab/explgbk-auth.git  

I couldn't get bind mounting to work with the official mongo package, so i removed the VOLUME definition. `explgbk-auth` provides a separate authentication layer.

## Build

Build the dependencies:

    cd mongo/3.7/
    docker build -t slaclab/mongo:3.7 .

    cd explgbk-auth/
    docker build -t slaclab/explgbk-auth .

Then build the logbook:

    cd explgbk-docker/
    docker build -t slaclab/explgbk-docker .

Run docker compose to bring up entire environment

    docker-compose -f docker-compose.yaml up

## Customize

You will probably want to change `explgbk-auth`s `FAKE_USER` - see `docker-compose.yaml`.

The mongo database is initially populated from the scripts within `mongodb-init.d`.


# Develop

As we track [explgbk|https://github.com/slaclab/explgbk] as a submodule, changes to explgbk need to be pulled in via:

    git submodule init
    git submodule update --remote

And then committed back via

    git commit -m 'track explgbk'
    git push
  
