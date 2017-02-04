"""
A Julia library for reading and writing Midi files.
"""
module MIDI

include("trackevent.jl")
include("midievent.jl")
include("metaevent.jl")
include("sysexevent.jl")
include("note.jl")
include("miditrack.jl")
include("midifile.jl")
include("constants.jl")
include("variablelength.jl")
include("convert.jl")

end
