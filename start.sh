#!/bin/bash

# Start the Spring Boot backend in background
echo "Starting SmartCare backend..."
java -jar artifacts/api-server/target/smartcare-api-1.0.0.jar \
  --server.port=8080 \
  --spring.datasource.url="jdbc:postgresql://${PGHOST}:${PGPORT}/${PGDATABASE}" \
  --spring.datasource.username="${PGUSER}" \
  --spring.datasource.password="${PGPASSWORD}" \
  --jwt.secret="${JWT_SECRET}" \
  &

BACKEND_PID=$!
echo "Backend started with PID $BACKEND_PID"

# Wait for backend to be ready
echo "Waiting for backend to start..."
for i in $(seq 1 30); do
  if curl -sf http://localhost:8080/api/healthz > /dev/null 2>&1; then
    echo "Backend is ready!"
    break
  fi
  echo "Waiting... ($i/30)"
  sleep 3
done

# Start the Vite frontend
echo "Starting SmartCare frontend..."
cd artifacts/smartcare && PORT=5000 BASE_PATH=/ pnpm run dev
