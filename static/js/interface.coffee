socket = io.connect()
MIDI_CHANNEL = 0
MIDI_VOLUME = 127
LATCH_MODE = false
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
      attachHintListener()

gotit = (text) ->
  $el = $('#gotit')
  $el.text text
  $el.show().css('bottom', '20px').css('opacity', 1)
  $el.animate
    opacity: 0
    bottom: "+=100"
  , 1200, "swing", =>
    $el.hide()
  

attachListeners = ->
  $('.notes span').each (i, el) ->
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
    
    $el.mouseout ->
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

  socket.on 'target', (target, timeout) ->
    animateProgressBar timeout
    if target is 'A' or target is 'E'
      updateStatus "Play an #{target} major chord!"
    else
      updateStatus "Play a #{target} major chord!"

  socket.on 'gameStart', ->
    gotit "Begin!"
    $('.tweetthis').slideUp()
    $('.notes .hint').removeClass 'hint'

  socket.on 'gameOver', (level, score) ->
    GAME_OVER = true
    updateStatus "Game over! Your team played #{level} chords correctly, and scored #{score}."
    tweet = "text=My team just scored #{score} points from #{level} chords at Multiplayer Piano!"
    if level is 0
      tweet += " Boy, we suck."
    else if level < 5
      tweet += " Amateurs."
    else if level < 10
      tweet += " Dare to dream."
    else
      tweet += " We rule!"

    $('.tweetthis').each (i, el) =>
      $el = $('a', el)
      link = $el.attr 'href'
      link = link.replace /text=([^&]*)/, tweet
      $el.attr 'href', link
      $(el).slideDown()


  socket.on 'gotIt', ->
    gotit "Got it!"
    $('.notes .myNote').removeClass 'myNote'
    $('.notes .hint').removeClass 'hint'
    $('.notes .theirNote').removeClass 'theirNote'

  socket.on 'waiting', (you, total) ->
    updateStatus "Waiting for other players (you are player #{you} of #{total} needed)..."


attachHintListener = =>
  socket.on 'hint', (notes) ->
    for note in notes
      $(".notes span[data-note-name='#{note}']").each (i, el) =>
        $(el).addClass 'hint'
        MIDI.noteOn MIDI_CHANNEL, $(el).data('note'), MIDI_VOLUME, 0



updateStatus = (string) ->
  $('.gamestatus').each (i, el) ->
    $(el).text(string)

timer = null
started = null
animateProgressBar = (timeout) ->
  timeout -= 100
  started = new Date().getTime()
  if timer?
    clearInterval timer
  timer = setInterval ->
    percentage = 1 - ((new Date().getTime() - started) / timeout)
    if percentage < 0
      clearInterval timer
    else
      color = "#5f5"
      if percentage < 0.66
        color = "#f95"
      if percentage < 0.33
        color = "#f55"
      $('.timeleft span').css('width', "#{percentage * 100}%").css('background-color', color)
  , 100

