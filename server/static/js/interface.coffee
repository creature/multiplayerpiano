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

gotit = (text) ->
  $el = $('#gotit')
  $el.text text
  $el.show().css('bottom', '20px').css('opacity', 1)
  $el.animate
    opacity: 0
    bottom: "+=100"
  , "slow"
  

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
    if target is 'A' or target is 'E'
      updateStatus "Play an #{target} major chord!"
    else
      updateStatus "Play a #{target} major chord!"

  socket.on 'gameStart', ->
    gotit "Begin!"

  socket.on 'gameOver', (level, score) ->
    GAME_OVER = true
    updateStatus "Game over! Your team played #{level} chords correctly, and scored #{score}."

  socket.on 'gotIt', ->
    gotit "Got it!"
    $('.myNote').removeClass 'myNote'

  socket.on 'waiting', (you, total) ->
    updateStatus "Waiting for other players (you are player #{you} of #{total} needed)..."


updateStatus = (string) ->
  $('.gamestatus').each (i, el) ->
    $(el).text(string)
