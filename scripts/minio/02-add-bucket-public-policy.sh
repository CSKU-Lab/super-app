#!/bin/sh

set -e

echo "Setting up MinIO alias..."
mc alias set minio http://s3:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

mc mb minio/cs-lab
echo "Successfully created main server bucket"

mc anonymous set public minio/cs-lab
echo "Successfully set public policy for main server bucket"
