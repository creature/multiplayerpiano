test = require('tap').test
MIDIUtil = require('../server.js').MIDIUtil

test "Ensure that MIDI conversion works OK.", (t) ->
  mu = new MIDIUtil
  cg = new ChordGenerator
  t.test "Ensure that note resolution works.", (t) =>
    t.equal mu.midiToNoteName(60), "C"
    t.equal mu.midiToNoteName(79), "G"
    t.equal mu.midiToNoteName(82), "Bb"
    t.end()
  t.end()

  t.test "Ensure root offset works.", (t) =>
    t.equal mu.offsetFromRoot("C", "C"), 0
    t.equal mu.offsetFromRoot("C", "D"), 2
    t.equal mu.offsetFromRoot("C", "F#"), 6
    t.equal mu.offsetFromRoot("A", "D"), 5
    t.end()
