VERSION=20200501.0


update:
	git submodule foreach git pull origin master

logbook:
	sudo docker build . -t slaclab/explgbk-docker:${VERSION}
	sudo docker push slaclab/explgbk-docker:${VERSION}

all: update logbook

collab-listener:
	sudo docker build . -f Dockerfile.collab-listener -t slaclab/explgbk-collab-listener:${VERSION}
	sudo docker push slaclab/explgbk-collab-listener:${VERSION}

