.PHONY: setup test test-file lint lint-fix scan migrate seed db-reset generate console routes up down build restart logs

# Setup (create DBs, migrate, seed)
setup:
	docker compose exec web bin/rails db:create db:migrate db:seed
	docker compose exec -e RAILS_ENV=test web bin/rails db:test:prepare

# Testing
test:
	docker compose exec -e RAILS_ENV=test web bin/rails db:test:prepare
	docker compose exec -e RAILS_ENV=test web bundle exec rspec --format documentation

test-file:
	docker compose exec -e RAILS_ENV=test web bin/rails db:test:prepare
	docker compose exec -e RAILS_ENV=test web bundle exec rspec $(FILE) --format documentation

# Linting
lint:
	docker compose exec web bundle exec rubocop

lint-fix:
	docker compose exec web bundle exec rubocop -A

# Security
scan:
	docker compose exec web bundle exec brakeman --no-pager

# Database
migrate:
	docker compose exec web bin/rails db:migrate

seed:
	docker compose exec web bin/rails db:seed

db-reset:
	docker compose exec web bin/rails db:reset

# Generators
generate:
	docker compose exec web bin/rails generate $(ARGS)

# Rails
console:
	docker compose exec web bin/rails console

routes:
	docker compose exec web bin/rails routes

# Docker
up:
	docker compose up

down:
	docker compose down

build:
	docker compose build

restart:
	docker compose restart

logs:
	docker compose logs -f web
