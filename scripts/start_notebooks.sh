#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "${ROOT_DIR}"

SPARK_MODE="${1:-distributed}"
if [[ "${SPARK_MODE}" != "distributed" && "${SPARK_MODE}" != "local" ]]; then
  echo "Cách dùng: ./scripts/start_notebooks.sh [distributed|local]" >&2
  exit 2
fi

mkdir -p reports

# Start HDFS and upload the local CSV only if it is not already present.
./scripts/run.sh

case "${SPARK_MODE}" in
  distributed)
    export SPARK_MASTER="spark://spark-master:7077"
    docker compose --profile audit --profile spark-cluster up -d --build \
      audit spark-master spark-worker-1 spark-worker-2 spark-worker-3
    ;;
  local)
    export SPARK_MASTER='local[*]'
    running_spark="$(docker compose --profile spark-cluster ps -q \
      spark-master spark-worker-1 spark-worker-2 spark-worker-3)"
    if [[ -n "${running_spark}" ]]; then
      docker compose --profile spark-cluster stop \
        spark-master spark-worker-1 spark-worker-2 spark-worker-3
    fi
    docker compose --profile audit up -d --build audit
    ;;
esac

printf '\nJupyterLab đang khởi động tại http://localhost:8888\n'
printf 'Mở trực tiếp http://localhost:8888, không cần token.\n'
if [[ "${SPARK_MODE}" == "distributed" ]]; then
  printf 'PySpark chạy trên 3 Spark Worker; giao diện Master: http://localhost:8080\n'
  printf 'Giao diện ứng dụng Spark khi notebook đang chạy: http://localhost:4040\n'
else
  printf 'PySpark chạy local[*] trong container audit.\n'
fi
printf 'Khi dùng xong, dừng Jupyter nhưng giữ HDFS bằng:\n'
printf '  docker compose --profile audit --profile spark-cluster stop audit spark-master spark-worker-1 spark-worker-2 spark-worker-3\n'
