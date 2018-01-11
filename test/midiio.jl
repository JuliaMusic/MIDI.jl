using MIDI
using Base.Test

cd(@__DIR__)

@testset "MIDI IO" begin
    midi = readMIDIfile("doxy.mid")
    @test midi.tpq == 960
    @test length(midi.tracks) == 4

    notes = getnotes(midi.tracks[4])

    @test length(notes.notes) > 1
    @test start(notes) == 1
    @test notes.tpq == 960

end
