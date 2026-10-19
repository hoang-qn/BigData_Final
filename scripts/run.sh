#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA_FILE="${ROOT_DIR}/data/hotel_bookings_synthetic_200MB.csv"
CONTAINER_DATA_FILE="/input/hotel_bookings_synthetic_200MB.csv"
HDFS_DIR="/data/hotel_bookings/input"
HDFS_FILE="${HDFS_DIR}/hotel_bookings_synthetic_200MB.csv"

cd "${ROOT_DIR}"

if [[ ! -f "${DATA_FILE}" ]]; then
  cat >&2 <<'EOF'
Dataset file not found.
Put your local copy here:
  data/hotel_bookings_synthetic_200MB.csv
Then run this script again.
EOF
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "Docker was not found. Install/start Docker Desktop, then retry." >&2
  exit 1
fi

docker compose up -d

echo "Waiting for the NameNode and all three DataNodes..."
ready=false
for attempt in {1..90}; do
  report="$(docker compose exec -T namenode hdfs dfsadmin -report 2>/dev/null || true)"
  if printf '%s\n' "${report}" | grep -q 'Live datanodes (3):'; then
    ready=true
    break
  fi
  sleep 2
done

if [[ "${ready}" != true ]]; then
  echo "HDFS did not become ready. Recent container logs:" >&2
  docker compose logs --tail=80 namenode datanode1 datanode2 datanode3 >&2 || true
  exit 1
fi

docker compose exec -T namenode hdfs dfs -mkdir -p "${HDFS_DIR}"

if docker compose exec -T namenode hdfs dfs -test -e "${HDFS_FILE}"; then
  echo "File already exists in HDFS; leaving it unchanged: ${HDFS_FILE}"
else
  docker compose exec -T namenode hdfs dfs -put "${CONTAINER_DATA_FILE}" "${HDFS_DIR}/"
fi

docker compose exec -T namenode hdfs dfs -setrep -w 3 "${HDFS_FILE}"

echo "HDFS input directory:"
docker compose exec -T namenode hdfs dfs -ls -h "${HDFS_DIR}"
