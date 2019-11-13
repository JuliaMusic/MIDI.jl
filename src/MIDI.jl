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

export testmidi, testnotes

"""
    testmidi()
Return the path to a test MIDI file.
"""
testmidi() = joinpath(dirname(@__DIR__), "test", "doxy.mid")

"""
    testnotes()
Return a test set of human-played MIDI notes on the piano.
"""
testnotes() = getnotes(readMIDIFile(testmidi()), 4)

end
