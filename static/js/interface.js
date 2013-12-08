// Generated by CoffeeScript 1.6.1
(function() {
  var GAME_OVER, LATCH_MODE, MIDI_CHANNEL, MIDI_VOLUME, animateProgressBar, attachHintListener, attachListeners, gotit, init, socket, started, timer, updateStatus,
    _this = this;

  socket = io.connect();

  MIDI_CHANNEL = 0;

  MIDI_VOLUME = 127;

  LATCH_MODE = false;

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
        MIDI.setVolume(MIDI_CHANNEL, MIDI_VOLUME);
        return attachHintListener();
      }
    });
  };

  gotit = function(text) {
    var $el,
      _this = this;
    $el = $('#gotit');
    $el.text(text);
    $el.show().css('bottom', '20px').css('opacity', 1);
    return $el.animate({
      opacity: 0,
      bottom: "+=100"
    }, 1200, "swing", function() {
      return $el.hide();
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
    socket.on('target', function(target, timeout) {
      animateProgressBar(timeout);
      if (target === 'A' || target === 'E') {
        return updateStatus("Play an " + target + " major chord!");
      } else {
        return updateStatus("Play a " + target + " major chord!");
      }
    });
    socket.on('gameStart', function() {
      gotit("Begin!");
      $('.tweetthis').slideUp();
      return $('.hint').removeClass('hint');
    });
    socket.on('gameOver', function(level, score) {
      var tweet,
        _this = this;
      GAME_OVER = true;
      updateStatus("Game over! Your team played " + level + " chords correctly, and scored " + score + ".");
      tweet = "text=My team just scored " + score + " points from " + level + " chords at Multiplayer Piano!";
      if (level === 0) {
        tweet += " Boy, we suck.";
      } else if (level < 5) {
        tweet += " Amateurs.";
      } else if (level < 10) {
        tweet += " Dare to dream.";
      } else {
        tweet += " We rule!";
      }
      return $('.tweetthis').each(function(i, el) {
        var $el, link;
        $el = $('a', el);
        link = $el.attr('href');
        link = link.replace(/text=([^&]*)/, tweet);
        $el.attr('href', link);
        return $(el).slideDown();
      });
    });
    socket.on('gotIt', function() {
      gotit("Got it!");
      $('.myNote').removeClass('myNote');
      return $('.hint').removeClass('hint');
    });
    return socket.on('waiting', function(you, total) {
      return updateStatus("Waiting for other players (you are player " + you + " of " + total + " needed)...");
    });
  };

  attachHintListener = function() {
    return socket.on('hint', function(notes) {
      var note, _i, _len, _results,
        _this = this;
      _results = [];
      for (_i = 0, _len = notes.length; _i < _len; _i++) {
        note = notes[_i];
        _results.push($(".notes span[data-note-name='" + note + "']").each(function(i, el) {
          $(el).addClass('hint');
          return MIDI.noteOn(MIDI_CHANNEL, $(el).data('note'), MIDI_VOLUME, 0);
        }));
      }
      return _results;
    });
  };

  updateStatus = function(string) {
    return $('.gamestatus').each(function(i, el) {
      return $(el).text(string);
    });
  };

  timer = null;

  started = null;

  animateProgressBar = function(timeout) {
    timeout -= 100;
    started = new Date().getTime();
    if (timer != null) {
      clearInterval(timer);
    }
    return timer = setInterval(function() {
      var color, percentage;
      percentage = 1 - ((new Date().getTime() - started) / timeout);
      if (percentage < 0) {
        return clearInterval(timer);
      } else {
        color = "#5f5";
        if (percentage < 0.66) {
          color = "#f95";
        }
        if (percentage < 0.33) {
          color = "#f55";
        }
        return $('.timeleft span').css('width', "" + (percentage * 100) + "%").css('background-color', color);
      }
    }, 100);
  };

}).call(this);
