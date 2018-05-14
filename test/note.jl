@testset "Note" begin
    @testset "it should correctly get the pitch of a note after we perform basic arithmetic to it" begin
        @test (MIDI.Note(60, 96, 0, 0) + 2).pitch == 62
        @test (MIDI.Note(60, 96, 0, 0) - 2).pitch == 58
        @test (MIDI.Note(60, 96, 0, 0) + 0).pitch == 60
    end
end

cd(@__DIR__)

@testset "Notes" begin
    midi = readMIDIfile("doxy.mid")

    notes = getnotes(midi.tracks[4])

    @test notes.tpq == 960
    @test typeof(notes[1]) == Note
    @test typeof(notes[1:3]) == Notes{Note}
    @test typeof(notes[1:3]) <: Notes
    @test notes[1:3].notes == notes.notes[1:3]
end
