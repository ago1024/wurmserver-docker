.PHONY: wurmbase server crative adventure push

TAG=public

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


push:
	for name in wurmunlimited wurmunlimited-creative wurmunlimited-adventure; do \
		docker inspect ago1024/$$name:$(TAG) | jq -r '.[0].RepoTags[]' | while read tag; do \
			set -x; \
			docker push $$tag; \
		done; \
	done;
