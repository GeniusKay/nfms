# NFMS-FIP — National Forest Monitoring System / Forest Information Platform

A Dockerised, full-stack reference implementation for the Kenya National Forest Monitoring System (NFMS-FIP). The public presentation layer preserves the approved NFMS-FIP interface with the Kenya / KFS branding, green navigation, forest hero image, landing-page information architecture, featured forest information, partners, news/events and footer/contact areas.

The backend adds real authentication, role-based access, dataset submission, metadata capture, automated validation hooks, technical review, approval, publication, catalogue search and dataset download. The stack also includes PostgreSQL/PostGIS, GeoServer, MinIO object storage, Redis/Celery background jobs and NGINX reverse proxy.

## Architecture

```text
                           NGINX / HTTPS
                                 |
                    +------------+------------+
                    |                         |
              Public NFMS-FIP           Authenticated
              interface / API             workspace
                    |                         |
                    +------------+------------+
                                 |
                            Django + DRF
                                 |
             +-------------------+-------------------+
             |                   |                   |
          PostGIS              MinIO              Redis
             |                   |                   |
             +-------------------+--------------+----+
                                                 |
                                               Celery
                                                 |
                                             QA / GDAL

                 GeoServer <-------- PostGIS
                    |
                  WMS/WFS/REST
                    |
             NFMS-FIP map clients
```

## Core workflow

```text
Upload -> Validate -> Review -> Approve -> Publish -> Display on NFMS
```

Authorised user path:

```text
Login -> Add Dataset -> Upload -> Metadata -> Submit for Review
      -> Technical Validation -> Review -> Approve -> Publish
```

## Roles

| Role | Main permissions |
|---|---|
| Public user | View maps, search datasets, download approved public data, view dashboards, read publications |
| Data Provider | Upload data, enter metadata, update institutional submissions, submit for review |
| Technical Reviewer / NTC | Review submissions, check metadata, spatial quality and completeness, approve/reject/request changes |
| KFS NFMS Super User | Publish approved datasets, manage users, categories, permissions and catalogue |

The application enforces the provider organisation boundary: non-superuser providers can only submit for their verified organisation.

## Services

| Service | Default access | Purpose |
|---|---:|---|
| `nginx` | `http://localhost` | Front door, static/media proxy and GeoServer proxy |
| `backend` | internal | Django application + REST API |
| `db` | internal | PostgreSQL 17 + PostGIS 3.5 |
| `geoserver` | `http://localhost:8600/geoserver` | GIS publishing and OGC services |
| `minio` | internal / console `http://localhost:9001` | Object storage for uploaded datasets |
| `redis` | internal | Celery broker/result backend |
| `worker` | internal | Async dataset validation/processing |
| `pgadmin` | optional profile | Database administration |
| `flower` | optional profile | Celery monitoring |

PostGIS uses the maintained `postgis/postgis:17-3.5` image. GeoServer uses the tagged `kartoza/geoserver:3.0.1` image. Tagged GeoServer images are recommended for stability rather than floating tags. See the project documentation for image updates. citeturn769374search0turn166933view0

## Quick start — Windows

1. Install Docker Desktop.
2. Extract this repository.
3. Open PowerShell in the repository root.
4. Copy `.env.example` to `.env`.
5. Change the secret/password values in `.env`.
6. Run:

```powershell
docker compose up -d --build
```

7. Open:

```text
http://localhost/
```

8. Check:

```text
http://localhost/healthz/
http://localhost/api/health/
http://localhost:8600/geoserver/
```

9. For optional administration tools:

```powershell
docker compose --profile admin up -d
```

Then:

```text
http://localhost:5050   # pgAdmin
http://localhost:5555   # Celery Flower
```

## Demo users

The first startup runs `seed_nfms`. Demo accounts are created automatically:

| Username | Role | Organisation |
|---|---|---|
| `provider.demo` | Data Provider | KEFRI |
| `reviewer.demo` | Technical Reviewer / NTC | KFS |
| `superuser.demo` | KFS NFMS Super User | KFS |

The default development password is the value of `DEMO_PASSWORD` in `.env.example` (`ChangeMe123!`). **Change this immediately outside development.**

## Management commands

Open a shell in the backend:

```powershell
docker compose exec backend sh
```

Then:

```sh
python manage.py migrate
python manage.py createsuperuser
python manage.py seed_nfms
python manage.py collectstatic --noinput
python manage.py check
```

## Important URLs

```text
/                         Public NFMS-FIP interface
/workspace/               Authenticated data-management workspace
/admin/                   Django administration
/api/catalogue/           Published public catalogue
/api/submissions/         Authenticated submission list / queue
/api/auth/session/        Current session
/api/auth/login/          Session login
/api/auth/logout/         Session logout
/api/datasets/{uuid}/     Dataset metadata
/api/datasets/{uuid}/download/  Published dataset download
/geoserver/               GeoServer proxy
/healthz/                 Application health
```

## Data lifecycle implementation

### 1. Upload

The provider submits a multipart upload. The backend records:

- title and abstract
- organisation
- category
- keywords
- spatial reference
- licence
- temporal extent
- lineage / processing history
- access level
- original filename
- byte size
- SHA-256 checksum
- storage key

### 2. Validate

A Celery task runs the validation service. It checks file size, extension and required metadata and, where GDAL/OGR is available, performs a deep read check for supported raster/vector formats.

The validation report is saved as JSON and visible to reviewers.

### 3. Review

Reviewers can:

- re-run technical validation
- approve
- reject
- request changes

Every decision records the user, timestamp, submission and comment.

### 4. Approve

Approval moves the submission and dataset into an approved state. Only approved submissions are eligible for publication.

### 5. Publish

A KFS NFMS Super User can publish an approved submission. Publication creates the public catalogue state and makes the associated public file downloadable.

### 6. Display on NFMS

The public catalogue API provides approved public datasets for the interface, dashboards and future map clients. GeoServer is included for OGC services and spatial publication.

## GeoServer / PostGIS direction

GeoServer is intentionally included as a separate GIS service. The application stores spatial metadata and can keep geometry in PostGIS. For production, extend the publishing adapter for your approved ingest standards, for example:

- GeoPackage vector -> PostGIS -> GeoServer layer
- GeoTIFF -> GeoServer coverage store
- GeoJSON -> PostGIS -> GeoServer layer
- pre-approved external services -> catalogue-only registration

Do not automatically publish arbitrary uploaded files without the KFS technical review gate.

## Object storage

MinIO is used as an S3-compatible storage layer. The Django storage service supports multipart upload and can stream published files for download. For production, use a private bucket policy and move credentials to a secrets manager or protected runtime configuration.

## Security baseline

Before production:

- replace every default password and `DJANGO_SECRET_KEY`
- set `DJANGO_DEBUG=0`
- set a correct `DJANGO_ALLOWED_HOSTS`
- set `CSRF_TRUSTED_ORIGINS` to HTTPS origins only
- enable secure session and CSRF cookies
- terminate TLS at a trusted reverse proxy / load balancer
- restrict GeoServer, MinIO and pgAdmin from public exposure
- use firewall rules / private networks for database and Redis
- configure regular Postgres and object-store backups
- review file-extension/MIME policies for KFS-approved formats
- add malware scanning when required by institutional security policy
- add SSO/identity provider integration if available
- add rate limiting and WAF controls at the edge
- review data classification and publication rules before opening restricted/internal datasets

## Backups

A simple database backup script is included:

```powershell
./scripts/backup.ps1
```

For Linux:

```sh
./scripts/backup.sh
```

Backups should be copied to storage outside the Docker host and tested through a restore drill.

## Development

The frontend is intentionally plain HTML/CSS/JavaScript rather than a bundled SPA. This keeps the approved interface transparent and easy to maintain while the backend remains a conventional Django/DRF service.

The design uses the supplied Kenya crest, KFS logo and forest hero image in `backend/static/nfms/img/`. The paths are Django static paths, not GitHub Pages relative asset paths, so assets remain inside the application build and are collected into `/static/`.

## Production domain

For the eventual `nfms-fip.kenyaforestservice.org` domain:

1. point DNS to the production reverse proxy/load balancer;
2. configure the host in `DJANGO_ALLOWED_HOSTS`;
3. configure the HTTPS origin in `CSRF_TRUSTED_ORIGINS`;
4. terminate TLS at the edge and forward `X-Forwarded-Proto: https`;
5. keep PostGIS, Redis, MinIO and GeoServer on private networks;
6. expose only NGINX and explicitly approved services.

## GitHub

This repository can be kept in GitHub as the source of truth, but GitHub Pages is not used for the operational NFMS-FIP application. Build/deploy this project to a Docker-capable server or VM.

## Current scope and extension points

This repository is a substantial operational starter and reference architecture. It is deliberately designed so KFS technical requirements can be added without changing the public information architecture. The main extension points are:

- institutional SSO / identity provider
- richer ISO 19115 metadata editor
- formal NTC review checklists
- spatial topology / CRS / geometry validation rules
- automatic PostGIS/GeoServer publication adapters
- tiled map client and layer catalogue
- dashboard integration
- data-sharing agreements and access approvals
- notification email/SMS integration
- immutable audit export and reporting
- antivirus scanning and quarantine
- external backup/object-lock strategy
