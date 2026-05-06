# SmartCare Hospital Management System

A full-stack Hospital Management System built with React + Java Spring Boot.

---

## Prerequisites

Install the following before you begin:

| Tool | Version | Download |
|------|---------|----------|
| Java JDK | 21 | https://adoptium.net |
| Apache Maven | 3.6+ | https://maven.apache.org/download.cgi |
| Node.js | 20+ | https://nodejs.org |
| pnpm | latest | run: `npm install -g pnpm` |
| PostgreSQL | 14+ | https://www.postgresql.org/download |
| pgAdmin 4 | latest | comes bundled with PostgreSQL installer |

After installing, verify everything works by opening PowerShell and running:

```powershell
java -version
mvn -version
node -version
pnpm -version
```

---

## Step 1 — Clone the repository

```powershell
git clone https://github.com/kindahard/smartcare-hospital.git
cd smartcare-hospital
git checkout replit
```

---

## Step 2 — Fix the Java version (only if you have Java 21)

Open `artifacts/api-server/pom.xml` in any text editor and change line 20:

```xml
<!-- Change this -->
<java.version>19</java.version>

<!-- To this -->
<java.version>21</java.version>
```

If you have Java 19, skip this step.

---

## Step 3 — Remove the Linux-only preinstall script

Open `package.json` in the project root and remove the `preinstall` line.

Before:
```json
"scripts": {
  "preinstall": "sh -c 'rm -f package-lock.json ...'",
  "build": "..."
}
```

After:
```json
"scripts": {
  "build": "pnpm run typecheck && pnpm -r --if-present run build",
  "typecheck:libs": "tsc --build",
  "typecheck": "pnpm run typecheck:libs && pnpm -r --filter \"./artifacts/**\" --filter \"./scripts\" --if-present run typecheck"
}
```

---

## Step 4 — Create the .npmrc file for Windows binaries

In the project root, create a file named `.npmrc` with this content:

```
supportedArchitectures[os][]=win32
supportedArchitectures[cpu][]=x64
```

Do this in PowerShell:

```powershell
@"
supportedArchitectures[os][]=win32
supportedArchitectures[cpu][]=x64
"@ | Out-File -FilePath .npmrc -Encoding utf8
```

---

## Step 5 — Install Node dependencies

```powershell
pnpm install
```

Then install the Windows-specific native binaries:

```powershell
pnpm add lightningcss-win32-x64-msvc @tailwindcss/oxide-win32-x64-msvc @rollup/rollup-win32-x64-msvc -w
```

---

## Step 6 — Create the database

Open pgAdmin (http://localhost:5050 or search for it in Start Menu) and:

1. Connect to your PostgreSQL server
2. Right-click **Databases** → **Create** → **Database**
3. Set **Name** to `smartcare`
4. Set **Owner** to your PostgreSQL user (e.g. `smartcare_user` or `postgres`)
5. Click **Save**

---

## Step 7 — Start the backend

Open a PowerShell terminal and run (replace values with your actual PostgreSQL credentials):

```powershell
$env:PGHOST="localhost"
$env:PGPORT="5432"
$env:PGDATABASE="smartcare"
$env:PGUSER="your_pg_username"
$env:PGPASSWORD="your_pg_password"
$env:PORT="8080"

mvn --file artifacts/api-server/pom.xml spring-boot:run
```

Wait until you see:
```
Started SmartCareApplication in X seconds
Default admin created: admin@smartcare.com / admin123
```

The terminal will appear frozen — that is normal. The server is running and listening for requests. **Leave this terminal open.**

The first run takes longer (Maven downloads all Java dependencies). Subsequent runs are fast.

---

## Step 8 — Start the frontend

Open a **second** PowerShell terminal in the same project folder:

```powershell
cd D:\path\to\smartcare-hospital

$env:PORT="3000"
$env:BASE_PATH="/"

pnpm --filter @workspace/smartcare run dev
```

---

## Step 9 — Open the app

Open your browser and go to: **http://localhost:3000**

Login with the default admin account:

| Field | Value |
|-------|-------|
| Email | `admin@smartcare.com` |
| Password | `admin123` |

---

## Important Notes

- **Never run `Database/DDL.sql`** against your database. Spring Boot (Hibernate) creates and manages all tables automatically on first startup.
- The backend must be running before the frontend can load data.
- Both terminals must stay open while using the app.
- To stop either server, press `Ctrl+C` in its terminal.

---

## Troubleshooting

### `psql is not recognized`
Add PostgreSQL's bin folder to your PATH:
```powershell
$env:PATH += ";C:\Program Files\PostgreSQL\17\bin"
```
Replace `17` with your PostgreSQL version.

### `password authentication failed`
You used the wrong password. Open pgAdmin and reset the password for your user, or create a new one.

### `database "smartcare" does not exist`
You need to create the database first. Follow Step 6 above.

### `Cannot find module @rollup/rollup-win32-x64-msvc` or `lightningcss.win32-x64-msvc`
Run:
```powershell
pnpm add lightningcss-win32-x64-msvc @tailwindcss/oxide-win32-x64-msvc @rollup/rollup-win32-x64-msvc -w
```

### Frontend shows blank page or API errors
Make sure the backend is running on port 8080 before starting the frontend.
