{spawn, exec} = require 'child_process'
fs = require 'fs'

task 'run', 'run project in local mode', (options) =>
    process.env.MONGO_URL = "mongodb://localhost:27017/creakl"
    spawn 'meteor', [],
        stdio: 'inherit'
        env: process.env

task 'pull', 'pull PRODUCTION database from heroku to local machine', (options) =>
    process.env.MONGO_URL = "mongodb://localhost:27017/creakl"
    spawn 'heroku', ['mongo:pull', '--app', 'creakl'],
        stdio: 'inherit'
        env: process.env

task 'deploy', 'deploy MASTER branch to production app on heroku', (options) =>
    console.log 'Deploying application to PRODUCTION environment...'
    spawn 'git', ['push', 'heroku', 'master'],
        stdio: 'inherit'
        env: process.env
