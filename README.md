# explgbk-docker
docker container and compose for explgbk

# Install

Clone this repo and submodules:

    git clone --recursive git@github.com:slaclab/explgbk-docker.git
    
# Build and Run

    cd explgbk-docker
    docker build -t slaclab/explgbk-docker .
    docker run -p 8000:8000 slaclab/explgbk-docker
    
    
# Develop

As we track [explgbk|https://github.com/slaclab/explgbk] as a submodule, changes to explgbk need to be pulled in via:

    git submodule init
    git submodule update --remote
    
And then committed back via

    git commit -m 'track explgbk'
    git push
    
