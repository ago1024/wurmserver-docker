.PHONY: wurmbase server crative adventure push

all: wurmbase server creative adventure

wurmbase:
	docker build -t ago1024/wurmbase wurmbase
server: wurmbase
	docker build -t ago1024/wurmunlimited:beta server
	bash tag-image ago1024/wurmunlimited:beta
creative: server
	docker build -t ago1024/wurmunlimited-creative:beta creative
	bash tag-image ago1024/wurmunlimited-creative:beta
adventure: server
	docker build -t ago1024/wurmunlimited-adventure:beta adventure
	bash tag-image ago1024/wurmunlimited-adventure:beta
