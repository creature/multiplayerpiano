$(document).ready ->
  init()
  attachListeners()

init = ->
  MIDI.loadPlugin
    soundfontUrl: "js/MIDI/soundfont/"
    instrument: "acoustic_grand_piano"
    callback: ->
      MIDI.setVolume(0, 127)

attachListeners = ->
  $('span').each (i, el) ->
    $(el).mousedown ->
      note = $(el).data 'note'
      MIDI.noteOn 0, note, 127, 0

    $(el).mouseup ->
      note = $(el).data 'note'
      MIDI.noteOff 0, note

