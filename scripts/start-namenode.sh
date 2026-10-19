#!/usr/bin/env bash
set -euo pipefail

NAME_DIR="/hadoop/dfs/name"

if [[ ! -f "${NAME_DIR}/current/VERSION" ]]; then
  echo "Formatting the empty NameNode volume"
  hdfs namenode -format -nonInteractive
fi

exec hdfs namenode
