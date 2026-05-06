# SmartCare HMS — Helwan University Team 2

## Overview
SmartCare is a full Hospital Management System built for Helwan University Team 2. Three roles: Admin, Doctor, Patient.

## Architecture

### Frontend (`artifacts/smartcare`)
- React + Vite, TypeScript, Tailwind CSS v4
- React Router via `wouter`
- React Query (`@tanstack/react-query`) for data fetching
- Shadcn/ui components (Card, Button, Dialog, Select, Table, etc.)
- Recharts for analytics charts
- Medical teal/blue color theme, light + dark mode

**Pages:**
- `/login` — JWT authentication with admin default credentials
- `/dashboard` — Stats cards, appointment trends chart, revenue chart, doctor performance table
- `/patients` — Patient list, create patient (creates user + profile)
- `/doctors` — Doctor cards, create doctor (creates user + profile)
- `/clinics` — Clinic rooms and doctor weekly schedules
- `/appointments` — Book/confirm/complete/cancel appointments
- `/medical-records` — Patient medical history per visit
- `/prescriptions` — Drug prescriptions linked to records
- `/billing` — Invoice list with payment processing
- `/notifications` — System notifications with mark-read

### Backend (`artifacts/api-server`)
- Java Spring Boot 3.1.5, Maven
- Spring Security + JWT (JJWT)
- Spring Data JPA + Hibernate (DDL auto-update)
- PostgreSQL (individual PG env vars: PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE)
- Runs at `/api` context path

**Entities:** AppUser, Patient, Doctor, Clinic, ClinicReservation, Appointment, MedicalRecord, Prescription, Drug, Invoice, Payment, Notification

**Seeded admin:** `admin@smartcare.com` / `admin123`

### API Contract (`lib/api-spec`)
- OpenAPI 3.0 spec at `lib/api-spec/openapi.yaml`
- Generated React Query hooks: `lib/api-client-react/src/generated/api.ts`
- Run codegen: `pnpm --filter @workspace/api-spec run codegen`

## Key Environment Variables
- `PGHOST`, `PGPORT`, `PGDATABASE`, `PGUSER`, `PGPASSWORD` — PostgreSQL connection
- `JWT_SECRET` — optional, falls back to hardcoded dev secret
- `PORT` — assigned by Replit per artifact

## Running
- Backend: Maven Spring Boot via workflow `artifacts/api-server: API Server`
- Frontend: Vite dev server via workflow `artifacts/smartcare: web`

## Docker (Self-Hosted)
Run the full stack with a single command:
```bash
docker compose up -d
```
- Frontend → http://localhost (port 80)
- Backend API → http://localhost:8080/api
- pgAdmin → http://localhost:5050

Copy `.env.example` to `.env` to override defaults. All env vars have sensible defaults so `.env` is optional.

After first startup, optionally load dummy data:
```bash
docker exec -i smartcare_db psql -U smartcare -d smartcare < smartcare_dummy_data.sql
```

**Docker files:**
- `artifacts/api-server/Dockerfile` — Java 21 multi-stage build (Maven → JRE alpine)
- `artifacts/smartcare/Dockerfile` — pnpm build → nginx static serve
- `artifacts/smartcare/nginx.conf` — serves React SPA + proxies `/api` → backend
- `.dockerignore` — excludes node_modules, dist, target, etc.

## Notes
- JDBC URL is constructed from individual PG vars (`jdbc:postgresql://$PGHOST:$PGPORT/$PGDATABASE`), NOT from `DATABASE_URL` which uses an incompatible format
- All JPA enums use `@Enumerated(EnumType.STRING)`
- Drug ingredients use `@ElementCollection` (no JSONB)
- JWT secret falls back to hardcoded string if env var not set
