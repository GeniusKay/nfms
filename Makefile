.PHONY: up down build logs migrate seed shell test check backup admin

up:
	docker compose up -d --build

down:
	docker compose down

build:
	docker compose build

logs:
	docker compose logs -f backend worker nginx

migrate:
	docker compose exec backend python manage.py migrate

seed:
	docker compose exec backend python manage.py seed_nfms

shell:
	docker compose exec backend python manage.py shell

test:
	docker compose exec backend python manage.py test

check:
	docker compose exec backend python manage.py check

backup:
	./scripts/backup.sh

admin:
	docker compose --profile admin up -d
