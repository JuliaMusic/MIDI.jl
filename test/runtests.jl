using MIDI
using Base.Test

@testset "All tests" begin
    include("variablelength.jl")
    include("sysexevent.jl")
    include("note.jl")
    include("midievent.jl")
    include("metaevent.jl")
    include("miditrack.jl")
    include("midiio.jl")
end
