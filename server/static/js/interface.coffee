socket = io.connect()
MIDI_CHANNEL = 0
MIDI_VOLUME = 127
LATCH_MODE = true
GAME_OVER = false

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
    $el = $(el)
    $el.mousedown (ev) ->
      unless GAME_OVER
        note = $el.data 'note'
        if LATCH_MODE
          if $el.hasClass 'myNote'
            MIDI.noteOff MIDI_CHANNEL, note, MIDI_VOLUME, 0
            socket.emit 'note_off', note
            $el.removeClass 'myNote'
          else
            MIDI.noteOn MIDI_CHANNEL, note, MIDI_VOLUME, 0
            socket.emit 'note_on', note
            $el.addClass 'myNote'
        else
          MIDI.noteOn MIDI_CHANNEL, note, MIDI_VOLUME, 0
          socket.emit 'note_on', note
          $el.addClass 'myNote'

    $el.mouseup ->
      unless LATCH_MODE
        note = $el.data 'note'
        socket.emit 'note_off', note
        $el.removeClass 'myNote'

  socket.on 'note_on', (note) ->
    MIDI.noteOn MIDI_CHANNEL, note, MIDI_VOLUME, 0
    $("span[data-note='#{note}']").each (i, el) ->
      $(el).addClass('theirNote')

  socket.on 'note_off', (note) ->
    MIDI.noteOff MIDI_CHANNEL, note
    $("span[data-note='#{note}']").each (i, el) ->
      $(el).removeClass('theirNote')

  socket.on 'target', (target) ->
    updateStatus "Play a #{target} major!"

  socket.on 'gameOver', (score) ->
    GAME_OVER = true
    updateStatus "Game over! Your team scored #{score}."


updateStatus = (string) ->
  $('.gamestatus').each (i, el) ->
    $(el).text(string)
