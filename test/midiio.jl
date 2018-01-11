using MIDI
using Base.Test

@testset "MIDI IO" begin
    midi = readMIDIfile("serenade.mid")
    @test midi.tpq == 960
    @test length(midi.tracks) == 4

    notes = getnotes(midi.tracks[2])

    @test length(notes.notes) > 1
    @test start(notes) == 1
    @test notes.tpq == 960

end
