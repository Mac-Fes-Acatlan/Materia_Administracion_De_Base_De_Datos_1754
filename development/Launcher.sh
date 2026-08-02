#!/usr/bin/env bash

#dist
python3 setup.py bdist_wheel
find . | grep -E "(build|tools.egg-info$)" | xargs rm -rf

# Show env vars
grep -v '^#' .env

# Export env vars
export $(grep -v '^#' .env | xargs)

# Drop inesary files
find . | grep -E "(__pycache__|\.pyc|\.pyo$)" | xargs rm -rf
#find . | grep -E "(.cache|.config|.ipython|.jupyter|.local$)" | xargs rm -rf

# Docker
docker-compose down
#docker-compose build
docker compose up