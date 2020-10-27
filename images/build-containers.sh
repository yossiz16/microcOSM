#!/bin/bash
set -e

# its green
color='\033[0;32m'
NC='\033[0m' # No Color

for d in */ ; do
  if [ -f "${d}Dockerfile" ]; then
    echo -e "${color}building ${d}"
    echo -e "running docker build -t microcosm-${d%/}:v1 ${d}${NC}"
    docker build -q -t microcosm-${d%/}:v1 ${d}
  fi
done