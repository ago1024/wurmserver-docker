.PHONY: wurmbase server crative adventure

all: wurmbase server creative adventure

wurmbase:
	docker build -t ago1024/wurmbase wurmbase
server: wurmbase
	docker build -t ago1024/wurmunlimited:public server
creative: server
	docker build -t ago1024/wurmunlimited-creative:public creative
adventure: server
	docker build -t ago1024/wurmunlimited-adventure:public adventure 
