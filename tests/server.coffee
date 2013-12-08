test = require('tap').test
MIDIUtil = require('../server.js').MIDIUtil
ChordGenerator = require('../server.js').ChordGenerator

test "Ensure that MIDI conversion works OK.", (t) ->
  mu = new MIDIUtil
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

test "Check array comparison.", (t) ->
  cg = new ChordGenerator
  t.ok cg.arraysEqual(["A"], ["A"]), "Arrays with A in are equal."
  t.notOk cg.arraysEqual(["A"], ["B"]), "Arrays with A and B in are not equal."
  t.ok cg.arraysEqual(["A", "B", "C"], ["A", "B", "C"]), "Longer arrays equal."
  t.ok cg.arraysEqual(["A", "B", "C"], ["C", "B", "A"]), "Order doesn't matter."
  t.end()
