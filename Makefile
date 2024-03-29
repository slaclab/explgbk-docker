VERSION ?= latest
DOCKER ?= docker

init:
	git submodule update --recursive --init

update:
	git submodule foreach git pull origin master

logbook:
	$(DOCKER) build . -t slaclab/explgbk-docker:${VERSION}
	$(DOCKER) push slaclab/explgbk-docker:${VERSION}

all: update logbook

collab-listener:
	$(DOCKER) build . -f Dockerfile.collab-listener -t slaclab/explgbk-collab-listener:${VERSION}
	$(DOCKER) push slaclab/explgbk-collab-listener:${VERSION}

