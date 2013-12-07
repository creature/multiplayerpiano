socket = io.connect()
MIDI_CHANNEL = 0
MIDI_VOLUME = 127

$(document).ready ->
  init()
  attachListeners()

init = ->
  MIDI.loadPlugin
    soundfontUrl: "/static/soundfonts/"
    instrument: "acoustic_grand_piano"
    callback: ->
      MIDI.setVolume MIDI_CHANNEL, MIDI_VOLUME

attachListeners = ->
  $('span').each (i, el) ->
    $(el).mousedown (ev) ->
      ev.stopPropagation()
      note = $(el).data 'note'
      MIDI.noteOn MIDI_CHANNEL, note, MIDI_VOLUME, 0
      socket.emit 'note_on', note
      $(el).addClass 'myNote'

    $(el).mouseup ->
      note = $(el).data 'note'
      socket.emit 'note_off', note
      $(el).removeClass 'myNote'

  socket.on 'note_on', (note) ->
    MIDI.noteOn MIDI_CHANNEL, note, MIDI_VOLUME, 0

  socket.on 'note_off', (note) ->
    MIDI.noteOff MIDI_CHANNEL, note

  socket.on 'target', (target) ->
    updateStatus "Play a #{target}!"


updateStatus = (string) ->
  $('.gamestatus').each (i, el) ->
    $(el).text(string)
