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

end
