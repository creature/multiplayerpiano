// Generated by CoffeeScript 1.6.1
(function() {
  var attachListeners, init;

  $(document).ready(function() {
    init();
    return attachListeners();
  });

  init = function() {
    return MIDI.loadPlugin({
      soundfontUrl: "js/MIDI/soundfont/",
      instrument: "acoustic_grand_piano",
      callback: function() {
        return MIDI.setVolume(0, 127);
      }
    });
  };

  attachListeners = function() {
    return $('span').each(function(i, el) {
      $(el).mousedown(function() {
        var note;
        note = $(el).data('note');
        return MIDI.noteOn(0, note, 127, 0);
      });
      return $(el).mouseup(function() {
        var note;
        note = $(el).data('note');
        return MIDI.noteOff(0, note);
      });
    });
  };

}).call(this);
