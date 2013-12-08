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
server.listen process.env.PORT or 4000
io = require('socket.io').listen server


###### EXTRACT THIS LATER 

class ChordGenerator extends events.EventEmitter
  @NOTES_MAJOR = [0, 4, 7]
  @NOTES_MINOR = [0, 3, 7]
  @ROOTS = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B']
  @TYPES = ['Major', 'Minor']

  constructor: ->
    @target = null
    @notes = []
    @mu = new MIDIUtil

  getRandomChord: =>
    @current = ChordGenerator.ROOTS[Math.floor(Math.random() * ChordGenerator.ROOTS.length)]
    @currentNotes = []
    for i in ChordGenerator.NOTES_MAJOR
      @currentNotes.push ChordGenerator.ROOTS[(ChordGenerator.ROOTS.indexOf(@current) + i) % ChordGenerator.ROOTS.length]
    @current

  noteOn: (note) =>
    console.log "Note on: #{@mu.midiToNoteName note}"
    @notes.push(@mu.midiToNoteName note)
    console.log "Notes: #{@notes}"
    console.log "CurrentNotes: #{@currentNotes}"
    console.log "Value: " + this.arraysEqual @notes, @currentNotes
    if this.arraysEqual @notes, @currentNotes
      console.log "Chord matched!"
      @notes = []
      this.emit 'chordMatched'

  noteOff: (note) =>
    @notes = (x for x in @notes when x != @mu.midiToNoteName note)

  arraysEqual: (a, b) ->
    unless a instanceof Array and b instanceof Array
      return false
    unless a.length is b.length
      return false
    for x in a
      if b.indexOf(x) < 0
        return false
    return true

exports.ChordGenerator = ChordGenerator



class Game extends events.EventEmitter
  constructor: ->
    console.log "Starting a new game."
    @players = [] # Players participating in this game. 
    @chordGenerator = new ChordGenerator # Generator for chords
    @score = 0 # Number of points
    @level = 0 # Number of chords successfully played.
    @timer = null # How long until we finish the game?
    
    @chordGenerator.on 'chordMatched', =>
      @level += 1
      @score = @score + (100 * @level)
      p.emit 'gotIt' for p in @players
      this.newTurn()

  addPlayer: (player) =>
    console.log "Adding player (game)"
    @players.push player
    player.on 'note_on', (note) => 
      @chordGenerator.noteOn note
    player.on 'note_off', (note) =>
      @chordGenerator.noteOff note

  start: =>
    # Run a game. 
    console.log("Starting game.")
    p.emit 'gameStart' for p in @players
    this.newTurn()

  newTurn: =>
    console.log("New turn.")
    timeout = 20000 - (1000 * @level)
    if @timer?
      clearTimeout @timer
    @timer = setTimeout this.end, timeout
    target = @chordGenerator.getRandomChord()
    console.log "Broadcasting target " + target + " to all players."
    p.emit('target', target, timeout) for p in @players
  
  end: =>
    console.log "Game over; players scored #{@score}"
    p.emit('gameOver', @level, @score) for p in @players

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
    else 
      player.emit 'waiting', @waitingroom.length, GameServer.PLAYERS_PER_GAME

      

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



