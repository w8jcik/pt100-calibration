exec = require('child_process').exec
express = require('express')

options = require './options.coffee'

app = express()
#app.use express.bodyParser()
#app.use express.methodOverride()
#app.use app.router
app.use express.static(__dirname + "/public")

push = (req, res) ->
  url = "http://#{options.controller_host}#{req.originalUrl}"

  cmd = "curl #{url}"
  console.log "Calling... #{cmd}"
  
  exec cmd, (error, stdout, stderr) ->
    if error then res.send 404 else res.send stdout

app.all "/adc", push

port = process.env.PORT
app.listen port, ->
  console.log "Express server listening on port %d in %s mode", port, app.settings.env
