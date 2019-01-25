"""
A Julia library for reading and writing MIDI files.
"""
module MIDI

include("constants.jl")
include("note.jl")
include("trackevent.jl")
include("miditrack.jl")
include("midifile.jl")
include("variablelength.jl")
include("convert.jl")
include("findevents.jl")

@warn "To abide with scientific pitch notation, `name_to_pitch` gives the notes "*
"one octave lower than before, i.e. now \"C4\" corresponds to midi pitch 60 "*
"and \"C-1\" to midi pitch 0. "*
"This change may break existing code but it is a bugfix of the wrong old way. "*
"use MIDI.jl version 1.0.0 for the previous version."

export testmidi

"""
    testmidi()
Return the path to a test MIDI file.
"""
testmidi() = dir = joinpath(dirname(@__DIR__), "test", "doxy.mid")

end
