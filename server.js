// Generated by CoffeeScript 2.7.0
(function() {
  // Load requirements.
  var ChordGenerator, Game, GameServer, MIDIUtil, PLAYERS_PER_GAME, app, events, express, fs, gameServer, http, io, server, socket,
    boundMethodCheck = function(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new Error('Bound instance method accessed before binding'); } },
    indexOf = [].indexOf;

  express = require('express');

  events = require('events');

  app = express();

  http = require('http');

  fs = require('fs');

  // Serve static content.
  app.use('/static', express.static(__dirname + '/static'));

  // Start server.
  server = http.createServer(app);

  socket = require('socket.io');

  io = new socket.Server(server);

  if (process.argv[2] === "start") {
    server.listen(process.env.PORT || 4000);
  }

  PLAYERS_PER_GAME = 4;

  ChordGenerator = (function() {
    //##### EXTRACT THIS LATER
    class ChordGenerator extends events.EventEmitter {
      constructor() {
        super(...arguments);
        this.getRandomChord = this.getRandomChord.bind(this);
        this.noteOn = this.noteOn.bind(this);
        this.noteOff = this.noteOff.bind(this);
        this.getNotes = this.getNotes.bind(this);
        this.target = null;
        this.notes = [];
        this.mu = new MIDIUtil();
      }

      getRandomChord() {
        var i, j, len, ref;
        boundMethodCheck(this, ChordGenerator);
        this.current = ChordGenerator.ROOTS[Math.floor(Math.random() * ChordGenerator.ROOTS.length)];
        this.currentNotes = [];
        ref = ChordGenerator.NOTES_MAJOR;
        for (j = 0, len = ref.length; j < len; j++) {
          i = ref[j];
          this.currentNotes.push(ChordGenerator.ROOTS[(ChordGenerator.ROOTS.indexOf(this.current) + i) % ChordGenerator.ROOTS.length]);
        }
        return this.current;
      }

      noteOn(note) {
        var noteName;
        boundMethodCheck(this, ChordGenerator);
        noteName = this.mu.midiToNoteName(note);
        console.log(`Note on: ${noteName}`);
        if (indexOf.call(this.notes, noteName) < 0) {
          this.notes.push(noteName);
        }
        console.log(`Notes: ${this.notes}`);
        console.log(`CurrentNotes: ${this.currentNotes}`);
        console.log("Value: " + this.arraysEqual(this.notes, this.currentNotes));
        if (indexOf.call(this.currentNotes, noteName) < 0) {
          this.score -= this.level * 20;
        }
        if (this.arraysEqual(this.notes, this.currentNotes)) {
          console.log("Chord matched!");
          this.notes = [];
          return this.emit('chordMatched');
        }
      }

      noteOff(note) {
        var x;
        boundMethodCheck(this, ChordGenerator);
        return this.notes = (function() {
          var j, len, ref, results;
          ref = this.notes;
          results = [];
          for (j = 0, len = ref.length; j < len; j++) {
            x = ref[j];
            if (x !== this.mu.midiToNoteName(note)) {
              results.push(x);
            }
          }
          return results;
        }).call(this);
      }

      arraysEqual(a, b) {
        var j, len, x;
        if (!(a instanceof Array && b instanceof Array)) {
          return false;
        }
        if (a.length !== b.length) {
          return false;
        }
        for (j = 0, len = a.length; j < len; j++) {
          x = a[j];
          if (b.indexOf(x) < 0) {
            return false;
          }
        }
        return true;
      }

      getNotes() {
        boundMethodCheck(this, ChordGenerator);
        return this.currentNotes;
      }

    };

    ChordGenerator.NOTES_MAJOR = [0, 4, 7];

    ChordGenerator.NOTES_MINOR = [0, 3, 7];

    ChordGenerator.ROOTS = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B'];

    ChordGenerator.TYPES = ['Major', 'Minor'];

    return ChordGenerator;

  }).call(this);

  exports.ChordGenerator = ChordGenerator;

  Game = class Game extends events.EventEmitter {
    constructor() {
      console.log("Starting a new game.");
      super(...arguments);
      this.addPlayer = this.addPlayer.bind(this);
      this.start = this.start.bind(this);
      this.newTurn = this.newTurn.bind(this);
      this.end = this.end.bind(this);
      this.players = []; // Players participating in this game.
      this.chordGenerator = new ChordGenerator(); // Generator for chords
      this.score = 0; // Number of points
      this.level = 0; // Number of chords successfully played.
      this.timer = null; // How long until we finish the game?
      this.chordGenerator.on('chordMatched', () => {
        var j, len, p, ref;
        this.level += 1;
        this.score = this.score + (100 * this.level);
        ref = this.players;
        for (j = 0, len = ref.length; j < len; j++) {
          p = ref[j];
          p.emit('gotIt');
        }
        return this.newTurn();
      });
    }

    addPlayer(player) {
      boundMethodCheck(this, Game);
      console.log("Adding player (game)");
      this.players.push(player);
      player.on('note_on', (note) => {
        return this.chordGenerator.noteOn(note);
      });
      return player.on('note_off', (note) => {
        return this.chordGenerator.noteOff(note);
      });
    }

    start() {
      var j, len, p, ref;
      boundMethodCheck(this, Game);
      // Run a game.
      console.log("Starting game.");
      ref = this.players;
      for (j = 0, len = ref.length; j < len; j++) {
        p = ref[j];
        p.emit('gameStart');
      }
      return this.newTurn();
    }

    newTurn() {
      var j, k, len, len1, p, ref, ref1, results, target, timeout;
      boundMethodCheck(this, Game);
      console.log("New turn.");
      timeout = 20000 - (1000 * this.level);
      if (this.timer != null) {
        clearTimeout(this.timer);
      }
      this.timer = setTimeout(this.end, timeout);
      target = this.chordGenerator.getRandomChord();
      console.log("Broadcasting target " + target + " to all players.");
      ref = this.players;
      for (j = 0, len = ref.length; j < len; j++) {
        p = ref[j];
        p.emit('target', target, timeout);
      }
      if (this.level < 5) {
        ref1 = this.players;
        results = [];
        for (k = 0, len1 = ref1.length; k < len1; k++) {
          p = ref1[k];
          results.push(p.emit('hint', this.chordGenerator.getNotes()));
        }
        return results;
      }
    }

    end() {
      var j, len, p, ref, results;
      boundMethodCheck(this, Game);
      console.log(`Game over; players scored ${this.score}`);
      ref = this.players;
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        p = ref[j];
        results.push(p.emit('gameOver', this.level, this.score));
      }
      return results;
    }

  };

  GameServer = class GameServer extends events.EventEmitter {
    constructor() {
      super(...arguments);
      this.waitingroom = [];
      this.games = [];
    }

    addPlayer(player) {
      var game, i, j, ref;
      console.log("Adding player (gameserver).");
      this.waitingroom.push(player);
      if (this.waitingroom.length >= PLAYERS_PER_GAME) {
        game = new Game();
        for (i = j = 1, ref = PLAYERS_PER_GAME; (1 <= ref ? j <= ref : j >= ref); i = 1 <= ref ? ++j : --j) {
          game.addPlayer(this.waitingroom.pop());
        }
        return game.start();
      } else {
        return player.emit('waiting', this.waitingroom.length, PLAYERS_PER_GAME);
      }
    }

  };

  MIDIUtil = (function() {
    class MIDIUtil {
      midiToNoteName(num) {
        var target;
        target = num % MIDIUtil.NOTES.length;
        return MIDIUtil.NOTES[target];
      }

      offsetFromRoot(root, target) {
        var end, start;
        start = MIDIUtil.NOTES.indexOf(root);
        end = MIDIUtil.NOTES.indexOf(target);
        if (end >= start) {
          return end - start;
        } else {
          return (MIDIUtil.NOTES.length - start) + end;
        }
      }

    };

    MIDIUtil.NOTES = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'G#', 'A', 'Bb', 'B'];

    return MIDIUtil;

  }).call(this);

  exports.MIDIUtil = MIDIUtil;

  //##### STOP EXTRACTING
  gameServer = new GameServer();

  // Serve standard template.
  app.get('/', function(req, res) {
    return fs.createReadStream('./views/index.html').pipe(res);
  });

  // Do things on connection.
  io.sockets.on('connection', function(socket) {
    gameServer.addPlayer(socket);
    socket.on('note_on', function(note) {
      return socket.broadcast.emit('note_on', note);
    });
    return socket.on('note_off', function(note) {
      return socket.broadcast.emit('note_off', note);
    });
  });

}).call(this);
