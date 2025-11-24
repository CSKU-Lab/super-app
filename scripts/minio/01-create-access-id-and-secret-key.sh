#!/bin/sh

set -e

echo "Setting up MinIO alias..."
mc alias set minio http://s3:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD

echo "Checking if user $MAIN_SERVER_S3_ACCESS_KEY_ID already exists..."
if mc admin user info minio $MAIN_SERVER_S3_ACCESS_KEY_ID >/dev/null 2>&1; then
    echo "User $MAIN_SERVER_S3_ACCESS_KEY_ID already exists. Skipping user creation."
else
    echo "Creating user $MAIN_SERVER_S3_ACCESS_KEY_ID..."
    mc admin user add minio $MAIN_SERVER_S3_ACCESS_KEY_ID $MAIN_SERVER_S3_SECRET_ACCESS_KEY
    echo "User $MAIN_SERVER_S3_ACCESS_KEY_ID created successfully."
fi

echo "Attaching readwrite policy to user $MAIN_SERVER_S3_ACCESS_KEY_ID..."
mc admin policy attach minio readwrite --user=$MAIN_SERVER_S3_ACCESS_KEY_ID
echo "Policy attached successfully."
