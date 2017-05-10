.PHONY: wurmbase server crative adventure push

all: wurmbase server creative adventure

wurmbase:
	docker build -t ago1024/wurmbase wurmbase
server: wurmbase
	docker build -t ago1024/wurmunlimited:public server
	bash tag-image ago1024/wurmunlimited:public
creative: server
	docker build -t ago1024/wurmunlimited-creative:public creative
	bash tag-image ago1024/wurmunlimited-creative:public
adventure: server
	docker build -t ago1024/wurmunlimited-adventure:public adventure
	bash tag-image ago1024/wurmunlimited-adventure:public
