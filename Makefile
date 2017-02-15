.PHONY: steamcmd server crative adventure

all: steamcmd server creative adventure

steamcmd:
	docker build -t ago1024/steamcmd steamcmd
server: steamcmd
	docker build -t ago1024/wurmunlimited:public server
creative: server
	docker build -t ago1024/wurmunlimited-creative:public creative
adventure: server
	docker build -t ago1024/wurmunlimited-adventure:public adventure 
