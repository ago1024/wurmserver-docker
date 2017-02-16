.PHONY: steamcmd server crative adventure

all: steamcmd server creative adventure

steamcmd:
	docker build -t ago1024/steamcmd steamcmd
server: steamcmd
	docker build -t ago1024/wurmunlimited:alpha server
creative: server
	docker build -t ago1024/wurmunlimited-creative:alpha creative
adventure: server
	docker build -t ago1024/wurmunlimited-adventure:alpha adventure 
