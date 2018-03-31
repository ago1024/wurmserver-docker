.PHONY: wurmbase server crative adventure push

TAG=beta

all: server creative adventure

server:
	docker build -t ago1024/wurmunlimited:$(TAG) .
	bash tag-image ago1024/wurmunlimited:$(TAG)
creative: server
	docker build -t ago1024/wurmunlimited-creative:$(TAG) --target creative .
	bash tag-image ago1024/wurmunlimited-creative:$(TAG)
adventure: server
	docker build -t ago1024/wurmunlimited-adventure:$(TAG) --target adventure .
	bash tag-image ago1024/wurmunlimited-adventure:$(TAG)
