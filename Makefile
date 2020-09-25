.DEFAULT_GOAL := help
PACKAGE_NAME ?= avorion_docker
ADMIN := "0"
GALAXY_NAME := "galaxy"

help:
	@echo "This Makefile will create an Avorion dedicated server"
	@echo ""
	@echo "Targets:"
	@echo "  build    Builds the docker container"
	@echo "  run      Builds and runs the docker container"
	@echo "  rm       Removes the container"
	@echo "  start    Starts the server"
	@echo "  stop     Stops the server"
	@echo ""

build:
	@docker build . -t avorion_docker:latest

rm:
	@docker rm avorion_docker

run: build
	docker run -it -d --restart always --name "avorion_docker" \
		-e SERVER_ADMIN=$(ADMIN) \
		-e GALAXY_NAME=$(GALAXY_NAME) \
		-v $(CURDIR)/data:/data \
		-p 27000:27000 \
		-p 27000:27000/udp \
		-p 27003:27003 \
		-p 27003:27003/udp \
		-p 27020:27020 \
		-p 27020:27020/udp \
		-p 27021:27021 \
		-p 27021:27021/udp \
		avorion_docker:latest

start:
	@docker start avorion_docker

stop:
	@docker stop avorion_docker
