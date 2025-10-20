.PHONY: help build up down logs logs-cron logs-tail exec run-now restart status clean

# Load environment variables from .env file if it exists
-include .env
export

help:
	@echo "Nightscout Autotune - Docker Management"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  build      - Build the Docker image"
	@echo "  up         - Start the container in background"
	@echo "  down       - Stop and remove the container"
	@echo "  logs       - Show container logs"
	@echo "  logs-cron  - Show cron execution logs"
	@echo "  logs-tail  - Follow container logs in real-time"
	@echo "  exec       - Execute a shell in the running container"
	@echo "  run-now    - Manually trigger autotune run"
	@echo "  restart    - Restart the container"
	@echo "  status     - Show container status"
	@echo "  clean      - Remove container and clean up data"

build:
	@echo "Building Docker image..."
	docker-compose build

up:
	@echo "Starting nightscout-autotune..."
	docker-compose up -d
	@echo ""
	@echo "Container started. Use 'make logs' to view logs."

down:
	@echo "Stopping nightscout-autotune..."
	docker-compose down

logs:
	docker-compose logs

logs-cron:
	@echo "Showing cron execution logs..."
	docker-compose exec nightscout-autotune tail -100 /var/log/autotune-cron.log

logs-tail:
	docker-compose logs -f

exec:
	docker-compose exec nightscout-autotune /bin/sh

run-now:
	@echo "Triggering immediate autotune run..."
	docker-compose exec nightscout-autotune /app/run-autotune.sh

restart:
	@echo "Restarting container..."
	docker-compose restart

status:
	@echo "Container status:"
	docker-compose ps
	@echo ""
	@echo "Cron schedule:"
	@docker-compose exec nightscout-autotune cat /etc/crontabs/root 2>/dev/null || echo "Container not running"

clean:
	@echo "This will remove the container and all data volumes."
	@read -p "Are you sure? [y/N] " -n 1 -r; \
	echo; \
	if [[ $$REPLY =~ ^[Yy]$$ ]]; then \
		docker-compose down -v; \
		rm -rf autotune-data logs; \
		echo "Cleaned up."; \
	fi
