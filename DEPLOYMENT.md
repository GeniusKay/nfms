# NFMS-FIP Deployment Guide

## A. Local Windows deployment (recommended first test)

### 1. Install Docker Desktop

Install Docker Desktop and make sure `docker compose version` works in PowerShell.

### 2. Extract the repository

Place the folder somewhere simple, for example:

```text
C:\nfms-fip
```

### 3. Create environment file

```powershell
Copy-Item .env.example .env
```

Open `.env` and change the secret/password values.

### 4. Start the full stack

```powershell
docker compose up -d --build
```

### 5. Watch startup

```powershell
docker compose ps
docker compose logs -f backend worker nginx
```

### 6. Open the portal

```text
http://localhost/
```

### 7. Open the GIS administration page

```text
http://localhost:8600/geoserver/
```

### 8. Optional administration tools

```powershell
docker compose --profile admin up -d
```

Then open pgAdmin at `http://localhost:5050` and Flower at `http://localhost:5555`.

## B. First login

Use the seeded demo accounts from `README.md` for functional testing. After confirming the workflow, create actual KFS/institutional users and change/remove demo credentials.

## C. Test the data submission flow

1. Sign in as `provider.demo`.
2. Open **Add Dataset**.
3. Select a category and the KEFRI organisation.
4. Upload a test GeoJSON/GeoPackage/GeoTIFF/CSV file.
5. Submit.
6. Wait for Celery validation.
7. Sign out.
8. Sign in as `reviewer.demo`.
9. Open the review queue.
10. Inspect the validation report.
11. Approve or request changes.
12. Sign out.
13. Sign in as `superuser.demo`.
14. Publish an approved submission.
15. Open the public catalogue and download the published file.

## D. Production Linux server

A typical target is an Ubuntu/Debian VM with Docker Engine and Compose plugin installed. Put this repository on the server, create `.env`, replace default secrets, and run:

```sh
docker compose up -d --build
```

Place a TLS-terminating reverse proxy or load balancer in front of NGINX. Only expose the public HTTP/HTTPS ports. Keep PostGIS, Redis, MinIO and GeoServer administration private.

## E. DNS

Point the production DNS A/AAAA record for:

```text
nfms-fip.kenyaforestservice.org
```

to the production edge/load balancer. Add the hostname to `DJANGO_ALLOWED_HOSTS` and the HTTPS origin to `CSRF_TRUSTED_ORIGINS`.

## F. TLS

Use an institutional certificate or a trusted ACME client at the edge. When TLS is terminated upstream, preserve:

```text
X-Forwarded-Proto: https
```

The Django application is already configured to understand that proxy header.

## G. Backups

Run:

```sh
./scripts/backup.sh
```

The database backup should be copied off the Docker host. Object storage needs its own backup/replication policy. Test restoration regularly.

## H. Updates

Pull the Git source, review changes, then rebuild:

```sh
git pull
docker compose build
docker compose up -d
```

Do not use floating image tags as the long-term production policy. Pin reviewed versions after the KFS infrastructure team approves each upgrade.

## I. Pre-production checklist

- [ ] Production secrets changed
- [ ] HTTPS configured
- [ ] Firewall rules applied
- [ ] PostGIS private
- [ ] Redis private
- [ ] MinIO console private
- [ ] GeoServer admin private
- [ ] pgAdmin disabled or private
- [ ] Flower disabled or private
- [ ] SSO / institutional authentication configured
- [ ] Data classification policy configured
- [ ] Approved formats and size limits agreed
- [ ] NTC review checklist agreed
- [ ] Backup / restore tested
- [ ] Disaster recovery target agreed
- [ ] Audit retention policy agreed
