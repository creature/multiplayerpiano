# Load requirements. 
express = require 'express'
app = express()
http = require 'http'
fs = require 'fs'

# Serve static content. 
app.use('/static', express.static __dirname + '/static')

# Start server. 
server = http.createServer app
server.listen 4000
io = require('socket.io').listen server

# Serve standard template. 
app.get '/', (req, res) ->
  fs.createReadStream('./views/index.html').pipe res


# Do things on connection.
io.sockets.on 'connection', (socket) ->
  console.log "Client connected"
  socket.on 'note_on', (note) ->
    socket.broadcast.emit 'note_on', note

  socket.on 'note_off', (note) ->
    socket.broadcast.emit 'note_off', note


