#!/bin/bash
set -e

# 1. Export variables so mongosh can read them via process.env
export CONFIG_USER=${MONGO_CONFIG_USERNAME:-config_server}
export CONFIG_PWD=${MONGO_CONFIG_PASSWORD:-config_password}
export CONFIG_DB=${MONGO_CONFIG_DB:-config_server}

export TASK_USER=${MONGO_TASK_USERNAME:-task_server}
export TASK_PWD=${MONGO_TASK_PASSWORD:-task_password}
export TASK_DB=${MONGO_TASK_DB:-task_server}

echo "Creating application users..."

# 2. Run mongosh using process.env (No variable injection errors!)
mongosh -u "$MONGO_INITDB_ROOT_USERNAME" -p "$MONGO_INITDB_ROOT_PASSWORD" --authenticationDatabase admin --eval "
  function createAppUser(userEnv, pwdEnv, dbEnv) {
    // Read from the exported environment variables
    const user = process.env[userEnv];
    const pwd = process.env[pwdEnv];
    const dbName = process.env[dbEnv];
    
    if (!user || !pwd || !dbName) {
        print('Error: Missing env vars for ' + userEnv);
        return;
    }

    const targetDb = db.getSiblingDB(dbName);
    const existing = targetDb.getUser(user);
    
    if (!existing) {
      targetDb.createUser({
        user: user,
        pwd: pwd,
        roles: [{ role: 'readWrite', db: dbName }]
      });
      print('Created user: ' + user + ' on db: ' + dbName);
    } else {
      print('User already exists: ' + user);
    }
  }

  // Pass the NAMES of the env vars, not the values
  createAppUser('CONFIG_USER', 'CONFIG_PWD', 'CONFIG_DB');
  createAppUser('TASK_USER', 'TASK_PWD', 'TASK_DB');
"
