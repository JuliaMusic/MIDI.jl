if current_module() != MIDI
  using MIDI
end
using Base.Test

@testset "All tests" begin
    include("variablelength.jl")
    include("sysexevent.jl")
    include("note.jl")
    include("midievent.jl")
    include("metaevent.jl")
    include("miditrack.jl")
end
