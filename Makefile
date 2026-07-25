.DEFAULT_GOAL := help

IMAGE_NAME ?= docker-avorion

.PHONY: build down help logs run start stop

help:
	@echo "Avorion dedicated server"
	@echo
	@echo "Targets:"
	@echo "  build  Build the local image"
	@echo "  run    Build and start the server"
	@echo "  logs   Follow server logs"
	@echo "  start  Start the existing server"
	@echo "  stop   Stop the server gracefully"
	@echo "  down   Remove the container and network (preserves data)"

build:
	docker build --tag "$(IMAGE_NAME):latest" .

run:
	docker compose up --detach --build

logs:
	docker compose logs --follow avorion

start:
	docker compose start avorion

stop:
	docker compose stop avorion

down:
	docker compose down
