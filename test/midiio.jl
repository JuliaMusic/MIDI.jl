using MIDI
using Compat.Test

cd(@__DIR__)

@testset "MIDI IO" begin
    midi = readMIDIfile("doxy.mid")
    @test midi.tpq == 960
    @test length(midi.tracks) == 4

    notes = getnotes(midi.tracks[4])

    @test length(notes.notes) > 1
    if VERSION < v"0.7-"
        @test start(notes) == 1
    end
    @test notes.tpq == 960

    @test notes[1].pitch == 65
    @test notes[1].velocity == 69
    @test notes[1].position == 7427
    @test notes[1].duration == 181
    @test notes[1].channel == 0

    @test notes[2].pitch == 70
    @test notes[2].velocity == 85
    @test notes[2].position == 7760
    @test notes[2].duration == 450
    @test notes[2].channel == 0

end
