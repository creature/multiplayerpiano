# Load requirements. 
express = require 'express'
events = require 'events'
app = express()
http = require 'http'
fs = require 'fs'

# Serve static content. 
app.use('/static', express.static __dirname + '/static')

# Start server. 
server = http.createServer app
server.listen 4000
io = require('socket.io').listen server


###### EXTRACT THIS LATER 

class ChordGenerator extends events.EventEmitter
  NOTES_MAJOR = [0, 4, 7]
  NOTES_MINOR = [0, 3, 7]
  ROOTS = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'G', 'G#', 'A', 'Bb', 'B']
  TYPES = ['Major', 'Minor']
  @target = null
  @notes = []

  getRandomChord: =>
    @current = ROOTS[Math.floor(Math.random() * ROOTS.length)]

  noteOn: (note) =>
    @notes.push(note)

  noteOff: (note) =>
    @notes = @notes.filter (x) -> x isnt note
exports.ChordGenerator = ChordGenerator



class Game extends events.EventEmitter
  constructor: ->
    console.log "Starting a new game."
    @players = [] # Players participating in this game. 
    @chordGenerator = new ChordGenerator # Generator for chords
    @score = 0 # Number of successfully played chords
    @timeout = null # How long until we finish the game?
    @notes = []

  addPlayer: (player) =>
    console.log "Adding player (game)"
    @players.push player

  start: =>
    # Run a game. 
    console.log("Starting game.")
    p.emit 'gameStart' for p in @players
    this.newTurn()

  newTurn: =>
    console.log("New turn.")
    if @timeout?
      clearTimeout @timeout
    @timeout = setTimeout this.end, 10000 - (1000 * @score)
    target = @chordGenerator.getRandomChord()
    console.log "Broadcasting target " + target + " to all players."
    p.emit('target', target) for p in @players
  
  end: =>
    console.log "Game over; players scored #{@score}"
    p.emit('gameOver', @score) for p in @players

class GameServer extends events.EventEmitter
  @PLAYERS_PER_GAME = 1
  constructor: ->
    @waitingroom = []
    @games = []

  addPlayer: (player) ->
    console.log "Adding player (gameserver)."
    @waitingroom.push player
    if @waitingroom.length >= GameServer.PLAYERS_PER_GAME
      game = new Game
      for i in [1..GameServer.PLAYERS_PER_GAME]
        game.addPlayer @waitingroom.pop()
      game.start()

      

class MIDIUtil
  @NOTES = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B']
  midiToNoteName: (num) ->
    target = num % MIDIUtil.NOTES.length
    MIDIUtil.NOTES[target]

  offsetFromRoot: (root, target) ->
    start = MIDIUtil.NOTES.indexOf root
    end = MIDIUtil.NOTES.indexOf target
    if end >= start
      return end-start
    else
      return (MIDIUtil.NOTES.length-start)+end
exports.MIDIUtil = MIDIUtil

###### STOP EXTRACTING



gameServer = new GameServer
# Serve standard template. 
app.get '/', (req, res) ->
  fs.createReadStream('./views/index.html').pipe res


# Do things on connection.
io.sockets.on 'connection', (socket) ->
  gameServer.addPlayer socket
  socket.on 'note_on', (note) ->
    socket.broadcast.emit 'note_on', note

  socket.on 'note_off', (note) ->
    socket.broadcast.emit 'note_off', note



