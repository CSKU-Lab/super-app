const configUser = process.env.MONGO_CONFIG_USERNAME || "config_server"
const configPwd = process.env.MONGO_CONFIG_PASSWORD || "config_password"
const configDb = process.env.MONGO_CONFIG_DB || "config_server"

const taskUser = process.env.MONGO_TASK_USERNAME || "task_server"
const taskPwd = process.env.MONGO_TASK_PASSWORD || "task_password"
const taskDb = process.env.MONGO_TASK_DB || "task_server"

function createAppUser(user, pwd, dbName) {
  const database = db.getSiblingDB(dbName)
  const existing = database.getUser(user)

  if (!existing) {
    database.createUser({
      user,
      pwd,
      roles: [{ role: "readWrite", db: dbName }],
    })
  }
}

createAppUser(configUser, configPwd, configDb)
createAppUser(taskUser, taskPwd, taskDb)
