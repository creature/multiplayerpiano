// Generated by CoffeeScript 1.6.1
(function() {
  var GAME_OVER, LATCH_MODE, MIDI_CHANNEL, MIDI_VOLUME, attachListeners, init, socket, updateStatus;

  socket = io.connect();

  MIDI_CHANNEL = 0;

  MIDI_VOLUME = 127;

  LATCH_MODE = true;

  GAME_OVER = false;

  $(document).ready(function() {
    init();
    return attachListeners();
  });

  init = function() {
    return MIDI.loadPlugin({
      soundfontUrl: "/static/soundfonts/",
      instrument: "acoustic_grand_piano",
      callback: function() {
        return MIDI.setVolume(MIDI_CHANNEL, MIDI_VOLUME);
      }
    });
  };

  attachListeners = function() {
    $('span').each(function(i, el) {
      var $el;
      $el = $(el);
      $el.mousedown(function(ev) {
        var note;
        if (!GAME_OVER) {
          note = $el.data('note');
          if (LATCH_MODE) {
            if ($el.hasClass('myNote')) {
              MIDI.noteOff(MIDI_CHANNEL, note, MIDI_VOLUME, 0);
              socket.emit('note_off', note);
              return $el.removeClass('myNote');
            } else {
              MIDI.noteOn(MIDI_CHANNEL, note, MIDI_VOLUME, 0);
              socket.emit('note_on', note);
              return $el.addClass('myNote');
            }
          } else {
            MIDI.noteOn(MIDI_CHANNEL, note, MIDI_VOLUME, 0);
            socket.emit('note_on', note);
            return $el.addClass('myNote');
          }
        }
      });
      return $el.mouseup(function() {
        var note;
        if (!LATCH_MODE) {
          note = $el.data('note');
          socket.emit('note_off', note);
          return $el.removeClass('myNote');
        }
      });
    });
    socket.on('note_on', function(note) {
      MIDI.noteOn(MIDI_CHANNEL, note, MIDI_VOLUME, 0);
      return $("span[data-note='" + note + "']").each(function(i, el) {
        return $(el).addClass('theirNote');
      });
    });
    socket.on('note_off', function(note) {
      MIDI.noteOff(MIDI_CHANNEL, note);
      return $("span[data-note='" + note + "']").each(function(i, el) {
        return $(el).removeClass('theirNote');
      });
    });
    socket.on('target', function(target) {
      return updateStatus("Play a " + target + " major!");
    });
    return socket.on('gameOver', function(score) {
      GAME_OVER = true;
      return updateStatus("Game over! Your team scored " + score + ".");
    });
  };

  updateStatus = function(string) {
    return $('.gamestatus').each(function(i, el) {
      return $(el).text(string);
    });
  };

}).call(this);
